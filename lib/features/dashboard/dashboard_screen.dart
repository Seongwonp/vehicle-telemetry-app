import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../../core/api/api_client.dart';
import '../../core/auth/token_storage.dart';
import '../../core/models/telemetry.dart';
import '../../core/responsive/breakpoints.dart';
import '../../core/theme/app_theme.dart';
import '../anomalies/anomaly_list_screen.dart';
import '../diagnosis/diagnosis_screen.dart';
import 'widgets/anomaly_banner.dart';
import 'widgets/dtc_section.dart';
import 'widgets/error_view.dart';
import 'widgets/no_data_view.dart';
import 'widgets/primary_metric_card.dart';
import 'widgets/secondary_metric_card.dart';
import 'widgets/speed_chart.dart';

class DashboardScreen extends StatefulWidget {
  final String vehicleId;
  const DashboardScreen({required this.vehicleId, super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  static const _historyLimit = 20;
  static const _noSignalTimeout = Duration(seconds: 8);

  Telemetry? _latest;
  List<Telemetry> _history = [];
  StompClient? _client;
  bool _loading = true;
  bool _error = false;
  bool _connected = false;
  DateTime? _lastUpdated;
  Timer? _signalTimeout;

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
    } else if (state == AppLifecycleState.resumed) {
      if (_client == null) _connect();
    }
  }

  String _wsUrl() {
    final base = ApiClient.baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    return '$base/ws';
  }

  Future<void> _connect() async {
    setState(() {
      _loading = true;
      _error = false;
    });

    final token = await TokenStorage.getToken();
    _client = StompClient(
      config: StompConfig(
        url: _wsUrl(),
        stompConnectHeaders: {if (token != null) 'Authorization': 'Bearer $token'},
        onConnect: _onConnect,
        onWebSocketError: (_) => _handleConnectionIssue(),
        onStompError: (_) => _handleConnectionIssue(),
        onDisconnect: (_) {
          if (mounted) setState(() => _connected = false);
        },
        reconnectDelay: const Duration(seconds: 5),
      ),
    );
    _client!.activate();

    // 연결은 됐는데 이 차량 데이터가 계속 안 들어오는 경우(비활성 차량 등)와
    // 아예 연결 자체가 안 되는 경우를 구분하기 위한 유예 시간.
    _signalTimeout?.cancel();
    _signalTimeout = Timer(_noSignalTimeout, () {
      if (!mounted || _latest != null) return;
      setState(() {
        _loading = false;
        _error = !_connected;
      });
    });
  }

  void _onConnect(StompFrame frame) {
    if (!mounted) return;
    setState(() => _connected = true);
    _client!.subscribe(
      destination: '/topic/vehicle/${widget.vehicleId}/telemetry',
      callback: (frame) {
        if (frame.body == null || !mounted) return;
        final telemetry =
            Telemetry.fromJson(jsonDecode(frame.body!) as Map<String, dynamic>);
        setState(() {
          _latest = telemetry;
          _history = [telemetry, ..._history].take(_historyLimit).toList();
          _loading = false;
          _error = false;
          _lastUpdated = DateTime.now();
        });
      },
    );
  }

  void _handleConnectionIssue() {
    if (!mounted) return;
    setState(() => _connected = false);
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
    final diff = DateTime.now().difference(_lastUpdated!).inSeconds;
    if (diff < 5) return '방금 업데이트';
    return '${diff}초 전 업데이트';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.vehicleId,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (_lastUpdated != null)
              Text(_lastUpdatedText(),
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.warning_amber_outlined),
            tooltip: '이상 이력',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      AnomalyListScreen(vehicleId: widget.vehicleId)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.psychology_outlined),
            tooltip: 'AI 진단',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => DiagnosisScreen(vehicleId: widget.vehicleId)),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _latest == null
              ? (_error
                  ? DashboardErrorView(onRetry: _connect)
                  : NoDataView(vehicleId: widget.vehicleId))
              : _DashboardBody(latest: _latest!, history: _history),
    );
  }
}

// ── 본문 ─────────────────────────────────────────────────────

class _DashboardBody extends StatelessWidget {
  final Telemetry latest;
  final List<Telemetry> history;

  const _DashboardBody({required this.latest, required this.history});

  @override
  Widget build(BuildContext context) {
    // 데스크톱 폭에서는 보조지표를 4열로 펼치고 전체 콘텐츠 폭을 제한해
    // 카드가 화면 끝까지 늘어나 보이지 않게 한다.
    final secondaryColumns = context.isDesktop ? 4 : 2;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 이상 감지 배너
              if (latest.hasAnomaly) ...[
                AnomalyBanner(dtcCodes: latest.dtcCodes),
                const SizedBox(height: 12),
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
                      warning: latest.speed > 120,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryMetricCard(
                      label: 'RPM',
                      value: latest.rpm.toDouble(),
                      maxValue: 7000,
                      unit: 'rpm',
                      icon: Icons.rotate_right,
                      danger: latest.rpm > 6000,
                      warning: latest.rpm > 4500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

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
                    warning: latest.engineTemp > 95,
                  ),
                  SecondaryMetricCard(
                    label: '연료',
                    value: '${latest.fuelLevel.toStringAsFixed(1)}%',
                    icon: Icons.local_gas_station_outlined,
                    danger: latest.fuelLevel < 10,
                    warning: latest.fuelLevel < 20,
                  ),
                  SecondaryMetricCard(
                    label: '배터리',
                    value: '${latest.batteryVoltage.toStringAsFixed(2)}V',
                    icon: Icons.battery_charging_full_outlined,
                    danger: latest.batteryVoltage < 11.5 ||
                        latest.batteryVoltage > 15.0,
                    warning: latest.batteryVoltage < 12.2 ||
                        latest.batteryVoltage > 14.8,
                  ),
                  SecondaryMetricCard(
                    label: '스로틀',
                    value: '${latest.throttlePosition.toStringAsFixed(1)}%',
                    icon: Icons.tune,
                    danger: false,
                    warning: false,
                  ),
                ],
              ),

              // DTC 진단 코드
              if (latest.dtcCodes.isNotEmpty) ...[
                const SizedBox(height: 16),
                DtcSection(codes: latest.dtcCodes),
              ],

              // 속도 추이 차트
              if (history.length > 2) ...[
                const SizedBox(height: 24),
                SpeedChart(history: history),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
