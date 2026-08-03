import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
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

class _DashboardScreenState extends State<DashboardScreen> {
  Telemetry? _latest;
  List<Telemetry> _history = [];
  Timer? _timer;
  bool _loading = true;
  bool _error = false;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _fetchData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final data =
          await ApiClient().getRecentTelemetry(widget.vehicleId, limit: 20);
      final list = data
          .map((e) => Telemetry.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() {
          _latest = list.isNotEmpty ? list.first : null;
          _history = list;
          _loading = false;
          _error = false;
          _lastUpdated = DateTime.now();
        });
      }
    } catch (_) {
      // 2초마다 폴링하는 도중 한 번 실패한다고 화면을 통째로 에러로 덮진 않는다 —
      // 이미 표시 중인 마지막 정상 데이터(_latest)는 그대로 유지한다. _error는
      // "아직 한 번도 데이터를 못 받은 상태(_latest == null)"일 때만 의미가 있고,
      // 그 경우에만 "데이터 없음"이 아니라 진짜 조회 실패임을 구분해서 보여준다.
      if (mounted) {
        setState(() {
          _loading = false;
          if (_latest == null) _error = true;
        });
      }
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
                  ? DashboardErrorView(onRetry: _fetchData)
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
                      value: latest.speed.toStringAsFixed(1),
                      unit: 'km/h',
                      icon: Icons.speed_outlined,
                      ratio: (latest.speed / 220).clamp(0.0, 1.0),
                      danger: latest.speed > 200,
                      warning: latest.speed > 120,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryMetricCard(
                      label: 'RPM',
                      value: latest.rpm.toString(),
                      unit: 'rpm',
                      icon: Icons.rotate_right,
                      ratio: (latest.rpm / 7000).clamp(0.0, 1.0),
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
