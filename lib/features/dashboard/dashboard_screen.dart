import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../../core/api/api_client.dart';
import '../../core/auth/token_storage.dart';
import '../../core/models/telemetry.dart';
import '../../core/responsive/breakpoints.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/anomaly_banner.dart';
import 'widgets/dtc_section.dart';
import 'widgets/error_view.dart';
import 'widgets/no_data_view.dart';
import 'widgets/primary_metric_card.dart';
import 'widgets/secondary_metric_card.dart';
import 'widgets/route_map.dart';
import 'widgets/speed_chart.dart';
import '../../core/theme/design_tokens.dart';

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

enum DashboardConnectionState {
  connecting,
  connected,
  reconnecting,
  stale,
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
          : (_connected
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
      _connectionState = DashboardConnectionState.connected;
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
        setState(() {
          _latest = telemetry;
          _history = [telemetry!, ..._history].take(_historyLimit).toList();
          _loading = false;
          _error = false;
          _connected = true;
          _connectionState = DashboardConnectionState.connected;
          _lastUpdated = widget.now();
        });
      },
    );
  }

  void _handleConnectionIssue() {
    if (!mounted) return;
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
      latest: _latest!,
      history: _history,
      lastUpdatedText: _lastUpdatedText(),
      connectionState: _connectionState,
    );
  }
}

// ── 본문 ─────────────────────────────────────────────────────

class _DashboardBody extends StatelessWidget {
  final Telemetry latest;
  final List<Telemetry> history;
  final String lastUpdatedText;
  final DashboardConnectionState connectionState;

  const _DashboardBody({
    required this.latest,
    required this.history,
    required this.lastUpdatedText,
    required this.connectionState,
  });

  @override
  Widget build(BuildContext context) {
    // 데스크톱 폭에서는 보조지표를 4열로 펼치고 전체 콘텐츠 폭을 제한해
    // 카드가 화면 끝까지 늘어나 보이지 않게 한다.
    final secondaryColumns = context.isDesktop ? 4 : 2;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          Spacing.md, Spacing.sm, Spacing.md, Spacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (lastUpdatedText.isNotEmpty) ...[
                _ConnectionStatus(
                  state: connectionState,
                  lastUpdatedText: lastUpdatedText,
                ),
                const SizedBox(height: Spacing.xs),
              ],

              // 이상 감지 배너
              if (latest.hasAnomaly) ...[
                AnomalyBanner(dtcCodes: latest.dtcCodes),
                const SizedBox(height: Spacing.sm),
              ],

              // 주요 지표: 속도 + RPM
              Row(
                children: [
                  Expanded(
                    child: PrimaryMetricCard(
                      label: '속도',
                      value: latest.speed,
                      maxValue: 220,
                      unit: 'km/h',
                      icon: Icons.speed_outlined,
                      danger: latest.speed > 200,
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: PrimaryMetricCard(
                      label: 'RPM',
                      value: latest.rpm.toDouble(),
                      maxValue: 7000,
                      unit: 'rpm',
                      icon: Icons.rotate_right,
                      danger: latest.rpm > 6000,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.sm),

              // 보조 지표: 모바일 2열 / 데스크톱 4열
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: secondaryColumns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: secondaryColumns == 4 ? 1.3 : 1.65,
                children: [
                  SecondaryMetricCard(
                    label: '엔진 온도',
                    value: '${latest.engineTemp.toStringAsFixed(1)}°C',
                    icon: Icons.thermostat_outlined,
                    danger: latest.engineTemp > 105,
                  ),
                  SecondaryMetricCard(
                    label: '연료',
                    value: '${latest.fuelLevel.toStringAsFixed(1)}%',
                    icon: Icons.local_gas_station_outlined,
                    danger: false,
                  ),
                  SecondaryMetricCard(
                    label: '배터리',
                    value: '${latest.batteryVoltage.toStringAsFixed(2)}V',
                    icon: Icons.battery_charging_full_outlined,
                    danger: latest.batteryVoltage < 11.5 ||
                        latest.batteryVoltage > 15.0,
                  ),
                  SecondaryMetricCard(
                    label: '스로틀',
                    value: '${latest.throttlePosition.toStringAsFixed(1)}%',
                    icon: Icons.tune,
                    danger: false,
                  ),
                ],
              ),

              // DTC 진단 코드
              if (latest.dtcCodes.isNotEmpty) ...[
                const SizedBox(height: Spacing.md),
                DtcSection(codes: latest.dtcCodes),
              ],

              // 속도 추이 차트
              if (history.length > 2) ...[
                const SizedBox(height: Spacing.lg),
                SpeedChart(history: history),
              ],

              // 주행 경로 지도
              const SizedBox(height: Spacing.lg),
              RouteMap(history: history),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionStatus extends StatelessWidget {
  final DashboardConnectionState state;
  final String lastUpdatedText;

  const _ConnectionStatus({required this.state, required this.lastUpdatedText});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final (icon, title, detail, color, background) = switch (state) {
      DashboardConnectionState.connected => (
          Icons.wifi,
          '실시간 수신 중',
          lastUpdatedText,
          colors.success,
          colors.success.withValues(alpha: 0.08),
        ),
      DashboardConnectionState.connecting => (
          Icons.sync,
          '연결 확인 중',
          '마지막 $lastUpdatedText',
          colors.warning,
          colors.warning.withValues(alpha: 0.08),
        ),
      DashboardConnectionState.reconnecting => (
          Icons.sync_problem,
          '재연결 중',
          '마지막 $lastUpdatedText',
          colors.warning,
          colors.warning.withValues(alpha: 0.08),
        ),
      DashboardConnectionState.stale => (
          Icons.schedule,
          '데이터 지연',
          '마지막 $lastUpdatedText',
          colors.danger,
          colors.danger.withValues(alpha: 0.08),
        ),
    };
    final semanticLabel = '$title, $detail';
    return Semantics(
      liveRegion: state != DashboardConnectionState.connected,
      label: semanticLabel,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md, vertical: Spacing.sm),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: FontSizes.caption,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: Spacing.xxs),
                  Text(
                    detail,
                    style: TextStyle(
                      fontSize: FontSizes.badge,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
