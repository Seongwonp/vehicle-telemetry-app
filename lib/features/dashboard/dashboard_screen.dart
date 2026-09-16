import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../../core/api/api_client.dart';
import '../../core/auth/token_storage.dart';
import '../../core/models/telemetry.dart';
import '../../core/responsive/breakpoints.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/dtc_section.dart';
import 'widgets/error_view.dart';
import 'widgets/extra_readings.dart';
import 'widgets/metric_tile_grid.dart';
import 'widgets/status_summary.dart';
import 'widgets/no_data_view.dart';
import 'widgets/route_map.dart';
import 'widgets/speed_chart.dart';
import '../../core/theme/design_tokens.dart';
import 'dashboard_view_state.dart';

export 'dashboard_view_state.dart' show DashboardConnectionState;

typedef StompClientFactory = StompClient Function(StompConfig config);
typedef TokenLoader = Future<String?> Function();
typedef DashboardClock = DateTime Function();

StompClient _createStompClient(StompConfig config) =>
    StompClient(config: config);
Future<String?> _loadAccessToken() => TokenStorage.getToken();
DateTime _currentTime() => DateTime.now();

String webSocketUrlForApiBase(String apiBaseUrl) {
  final uri = Uri.parse(apiBaseUrl);
  final path = '${uri.path.replaceFirst(RegExp(r'/$'), '')}/ws';
  return uri
      .replace(
        scheme: uri.scheme == 'https' ? 'wss' : 'ws',
        path: path,
      )
      .toString();
}

// 차량 상세 화면(VehicleDetailScreen)의 첫 번째 탭 — 자체 Scaffold/AppBar
// 없이 본문만 그린다. 웹소켓 연결 생명주기는 이 위젯이 계속 소유한다.
class DashboardTab extends StatefulWidget {
  final String vehicleId;
  final StompClientFactory stompClientFactory;
  final TokenLoader tokenLoader;
  final Duration noSignalTimeout;
  final Duration staleTimeout;
  final DashboardClock now;

  const DashboardTab({
    required this.vehicleId,
    this.stompClientFactory = _createStompClient,
    this.tokenLoader = _loadAccessToken,
    this.noSignalTimeout = const Duration(seconds: 8),
    this.staleTimeout = const Duration(seconds: 10),
    this.now = _currentTime,
    super.key,
  });

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  // TabBarView는 기본적으로 현재 탭과 바로 인접한 탭만 살려두고 멀리
  // 스와이프하면 언마운트한다 — 그러면 웹소켓이 끊기고 히스토리가 초기화된다.
  // KeepAlive로 세 탭 다 항상 살아있게 유지한다.
  @override
  bool get wantKeepAlive => true;

  static const _historyLimit = 20;
  Telemetry? _latest;
  List<Telemetry> _history = [];
  StompClient? _client;
  bool _loading = true;
  bool _error = false;
  bool _connected = false;
  DashboardConnectionState _connectionState =
      DashboardConnectionState.connecting;
  DateTime? _lastUpdated;

  // 지금 연결에서 새 프레임을 하나라도 받았는지. **소켓이 다시 붙은 것만으로는 "실시간"이 아니다** —
  // 새 프레임이 오기 전까지 화면의 값은 끊기기 전 것이다. 이게 없으면 재연결 직후 지난 값이
  // 큰 숫자·기준 초과로 다시 현재처럼 보였다(2026-09-16 Copilot 리뷰 지적, 코드로 확인).
  // 역전·중복 프레임은 버려지므로 이 값을 올리지 않는다.
  bool _frameSinceConnect = false;
  Timer? _signalTimeout;
  Timer? _staleTimer;
  int _connectionGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _connect();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _signalTimeout?.cancel();
    _staleTimer?.cancel();
    _connectionGeneration++;
    _client?.deactivate();
    super.dispose();
  }

  // 앱이 백그라운드로 가면 소켓을 끊는다 — 화면이 안 보이는데 계속 연결을
  // 유지하는 건 배터리 낭비다. 포그라운드로 돌아오면 재연결한다.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _client?.deactivate();
      _client = null;
      _connected = false;
      _connectionState = _latest == null
          ? DashboardConnectionState.connecting
          : DashboardConnectionState.reconnecting;
    } else if (state == AppLifecycleState.resumed) {
      if (_client == null) _connect();
    }
  }

  String _wsUrl() {
    return webSocketUrlForApiBase(ApiClient.baseUrl);
  }

  Future<void> _connect() async {
    // 에러 화면의 수동 재시도와 stomp_dart_client의 자동 재연결이 겹치면
    // 소켓/구독이 중복될 수 있으므로 새 클라이언트를 만들기 전에 기존 것을 끝낸다.
    final generation = ++_connectionGeneration;
    _client?.deactivate();
    _client = null;
    _frameSinceConnect = false;

    setState(() {
      _loading = _latest == null;
      _error = false;
      _connected = false;
      _connectionState = _latest == null
          ? DashboardConnectionState.connecting
          : DashboardConnectionState.reconnecting;
    });

    final connectHeaders = <String, String>{};
    final client = widget.stompClientFactory(
      StompConfig(
        url: _wsUrl(),
        stompConnectHeaders: connectHeaders,
        // 자동 재연결을 포함해 CONNECT 직전마다 최신 access token을 사용한다.
        beforeConnect: () async {
          final token = await widget.tokenLoader();
          connectHeaders.clear();
          if (token != null && token.isNotEmpty) {
            connectHeaders['Authorization'] = 'Bearer $token';
          }
        },
        onConnect: (frame) {
          if (generation == _connectionGeneration) _onConnect(frame);
        },
        onWebSocketError: (_) {
          if (generation == _connectionGeneration) _handleConnectionIssue();
        },
        onStompError: (_) {
          if (generation == _connectionGeneration) _handleConnectionIssue();
        },
        onWebSocketDone: () {
          if (generation == _connectionGeneration) _handleConnectionIssue();
        },
        onDisconnect: (_) {
          if (generation == _connectionGeneration) _handleConnectionIssue();
        },
        reconnectDelay: const Duration(seconds: 5),
      ),
    );
    if (!mounted || generation != _connectionGeneration) {
      client.deactivate();
      return;
    }
    _client = client;
    client.activate();

    // 연결은 됐는데 이 차량 데이터가 계속 안 들어오는 경우(비활성 차량 등)와
    // 아예 연결 자체가 안 되는 경우를 구분하기 위한 유예 시간.
    _signalTimeout?.cancel();
    _signalTimeout = Timer(widget.noSignalTimeout, () {
      if (!mounted || _latest != null) return;
      setState(() {
        _loading = false;
        _error = !_connected;
      });
    });
    _startStaleTimer();
  }

  void _startStaleTimer() {
    _staleTimer?.cancel();
    _staleTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _lastUpdated == null) return;
      final stale =
          widget.now().difference(_lastUpdated!) > widget.staleTimeout;
      final nextState = stale
          ? DashboardConnectionState.stale
          : (_connected && _frameSinceConnect
              ? DashboardConnectionState.connected
              : DashboardConnectionState.reconnecting);
      // 매초 rebuild해 "N초 전" 표시도 데이터가 끊긴 동안 정확히 갱신한다.
      setState(() => _connectionState = nextState);
    });
  }

  void _onConnect(StompFrame frame) {
    if (!mounted) return;
    setState(() {
      _connected = true;
      // 받은 값이 이미 있으면 새 프레임이 올 때까지 재연결 중으로 둔다(_frameSinceConnect 참고).
      _connectionState = _latest == null || _frameSinceConnect
          ? DashboardConnectionState.connected
          : DashboardConnectionState.reconnecting;
    });
    final client = _client;
    if (client == null) return;
    client.subscribe(
      destination: '/topic/vehicle/${widget.vehicleId}/telemetry',
      callback: (frame) {
        if (frame.body == null || !mounted) return;
        Telemetry? telemetry;
        try {
          final decoded = jsonDecode(frame.body!);
          if (decoded is! Map<String, dynamic>) {
            throw const FormatException('telemetry payload is not an object');
          }
          telemetry = Telemetry.tryFromJson(
            decoded,
            onError: (error, stackTrace) => debugPrint(
              'Malformed telemetry frame ignored for ${widget.vehicleId}: $error',
            ),
          );
        } catch (error) {
          debugPrint(
            'Malformed telemetry frame ignored for ${widget.vehicleId}: $error',
          );
          return;
        }
        if (telemetry == null) return;

        // 이미 가진 값보다 오래됐거나 같은 시각의 프레임은 버린다.
        //
        // 파이프라인은 차량별 순서를 **전역으로 보장하지 않는다.** Kafka 브로커 장애 뒤
        // 로컬 spool을 드레인할 때, 밀렸던 메시지가 새 메시지보다 늦게 도착할 수 있다.
        // 실측하니 90초 장애에서 차량당 4~6건, **최대 114초 묵은 값**이 최신 메시지 뒤에
        // 왔다(백엔드 저장소의 load-test/order-integrity/RESULT_20260905_order.md).
        //
        // 그대로 두면 묵은 값이 현재 값으로 표시되고, `_lastUpdated`가 도착 시각으로
        // 갱신돼 "오래된 데이터" 표시로도 안 걸러진다. 같은 timestamp 재전달도 새
        // 수신으로 취급하면 히스토리가 중복되고 지연 상태가 거짓으로 회복한다.
        //
        // 파이프라인에서 순서를 맞추지 않는 이유는 그쪽 비용이 크기 때문이다 —
        // 드레인과 신규 발행을 한 락으로 묶으면 수집 처리량이 무너진다. 순서가 필요한 곳은
        // "지금 값"을 보여주는 이 화면 하나뿐이라 여기서 막는 게 가장 싸고 정확하다.
        final previous = _latest;
        if (previous != null &&
            !telemetry.timestamp.isAfter(previous.timestamp)) {
          return;
        }

        setState(() {
          _latest = telemetry;
          _history = [telemetry!, ..._history].take(_historyLimit).toList();
          _loading = false;
          _error = false;
          _connected = true;
          _frameSinceConnect = true;
          _connectionState = DashboardConnectionState.connected;
          _lastUpdated = widget.now();
        });
      },
    );
  }

  void _handleConnectionIssue() {
    if (!mounted) return;
    _frameSinceConnect = false;
    setState(() {
      _connected = false;
      _connectionState = _latest == null
          ? DashboardConnectionState.connecting
          : DashboardConnectionState.reconnecting;
    });
    // stomp_dart_client가 reconnectDelay에 따라 자동 재시도한다 — 여기선
    // "아직 한 번도 데이터를 못 받았다면" 에러 상태만 반영한다.
    if (_latest == null) {
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  String _lastUpdatedText() {
    if (_lastUpdated == null) return '';
    final diff = widget.now().difference(_lastUpdated!).inSeconds;
    if (diff < 5) return '방금 업데이트';
    return '$diff초 전 업데이트';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 필수 호출
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_latest == null) {
      return _error
          ? DashboardErrorView(onRetry: _connect)
          : NoDataView(vehicleId: widget.vehicleId);
    }
    return _DashboardBody(
      state: DashboardViewState.from(
        latest: _latest!,
        connection: _connectionState,
        receivedAt: _lastUpdated ?? widget.now(),
      ),
      history: _history,
      lastUpdatedText: _lastUpdatedText(),
    );
  }
}

// ── 본문 ─────────────────────────────────────────────────────

/// 폭별 배치(docs/plans/2026-09-16-vehicle-detail-c.md §5):
/// - 600 미만: 한 열. 타일 2×2(좁거나 글자가 크면 1열)
/// - 600~1023: 한 열, 타일 4열 한 줄, 내용 폭 feed(840)
/// - 1024 이상: 요약 아래 2단 — 왼쪽(값) 7 : 오른쪽(차트·지도) 5, 내용 폭 grid(1200)
class _DashboardBody extends StatelessWidget {
  final DashboardViewState state;
  final List<Telemetry> history;
  final String lastUpdatedText;

  const _DashboardBody({
    required this.state,
    required this.history,
    required this.lastUpdatedText,
  });

  @override
  Widget build(BuildContext context) {
    final wide = context.isDesktop;
    final tablet = !context.isMobile && !wide;
    final past = !state.isLive;

    final values = <Widget>[
      _ValuesHeader(state: state),
      const SizedBox(height: Spacing.sm),
      MetricTileGrid(state: state, maxColumns: tablet ? 4 : 2),
      const SizedBox(height: Spacing.sm),
      ExtraReadings(state: state),
      // DTC는 지난 프레임 것이면 현재 고장 코드처럼 읽히므로 수신 중에만 둔다.
      if (state.isLive && state.dtcCodes.isNotEmpty) ...[
        const SizedBox(height: Spacing.sm),
        DtcSection(codes: state.dtcCodes),
      ],
    ];
    final trends = <Widget>[
      if (history.length > 2) ...[
        SpeedChart(history: history, past: past),
        const SizedBox(height: Spacing.lg),
      ],
      RouteMap(history: history, past: past),
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          context.screenPadding, Spacing.sm, context.screenPadding, Spacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: wide
                ? ContentWidths.grid
                : (tablet ? ContentWidths.feed : double.infinity),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StatusSummary(state: state, lastUpdatedText: lastUpdatedText),
              const SizedBox(height: Spacing.md),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: values,
                      ),
                    ),
                    const SizedBox(width: Spacing.lg),
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: trends,
                      ),
                    ),
                  ],
                )
              else ...[
                ...values,
                const SizedBox(height: Spacing.lg),
                ...trends,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 타일 위 한 줄 — 이 값들이 "지금" 것인지 "언제" 것인지 먼저 말한다.
class _ValuesHeader extends StatelessWidget {
  final DashboardViewState state;
  const _ValuesHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final live = state.isLive;
    final overCount = state.overCount;
    return Wrap(
      spacing: Spacing.xs,
      runSpacing: Spacing.xxs,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        Text(
          live ? '지금 받은 값' : '${state.receivedClock}에 받은 값',
          style: TextStyle(
            fontSize: FontSizes.subtitle,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        Text(
          live
              ? (overCount > 0 ? '기준 초과 $overCount' : '기준 초과 없음')
              : '현재 값 아님 · 기준 판정 안 함',
          key: const Key('values_header_aside'),
          style: TextStyle(
            fontSize: FontSizes.caption,
            fontWeight: overCount > 0 ? FontWeight.w700 : FontWeight.w400,
            color: overCount > 0 ? colors.danger : colors.textTertiary,
          ),
        ),
      ],
    );
  }
}
