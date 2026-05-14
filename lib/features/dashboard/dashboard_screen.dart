import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/api/api_client.dart';
import '../../core/models/telemetry.dart';
import '../anomalies/anomaly_list_screen.dart';
import '../diagnosis/diagnosis_screen.dart';

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
          _lastUpdated = DateTime.now();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
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
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade400)),
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
                  builder: (_) =>
                      DiagnosisScreen(vehicleId: widget.vehicleId)),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _latest == null
              ? _NoDataView(vehicleId: widget.vehicleId)
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이상 감지 배너
          if (latest.hasAnomaly) ...[
            _AnomalyBanner(dtcCodes: latest.dtcCodes),
            const SizedBox(height: 12),
          ],

          // 주요 지표: 속도 + RPM
          Row(
            children: [
              Expanded(
                child: _PrimaryCard(
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
                child: _PrimaryCard(
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

          // 보조 지표: 4개 그리드
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.65,
            children: [
              _SecondaryCard(
                label: '엔진 온도',
                value: '${latest.engineTemp.toStringAsFixed(1)}°C',
                icon: Icons.thermostat_outlined,
                danger: latest.engineTemp > 105,
                warning: latest.engineTemp > 95,
              ),
              _SecondaryCard(
                label: '연료',
                value: '${latest.fuelLevel.toStringAsFixed(1)}%',
                icon: Icons.local_gas_station_outlined,
                danger: latest.fuelLevel < 10,
                warning: latest.fuelLevel < 20,
              ),
              _SecondaryCard(
                label: '배터리',
                value: '${latest.batteryVoltage.toStringAsFixed(2)}V',
                icon: Icons.battery_charging_full_outlined,
                danger: latest.batteryVoltage < 11.5 ||
                    latest.batteryVoltage > 15.0,
                warning: latest.batteryVoltage < 12.2 ||
                    latest.batteryVoltage > 14.8,
              ),
              _SecondaryCard(
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
            _DtcSection(codes: latest.dtcCodes),
          ],

          // 속도 추이 차트
          if (history.length > 2) ...[
            const SizedBox(height: 24),
            _SpeedChart(history: history),
          ],
        ],
      ),
    );
  }
}

// ── 주요 지표 카드 (속도 / RPM) ──────────────────────────────

class _PrimaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final double ratio; // 0.0 ~ 1.0
  final bool danger;
  final bool warning;

  const _PrimaryCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.ratio,
    required this.danger,
    required this.warning,
  });

  Color get _accentColor {
    if (danger) return Colors.redAccent;
    if (warning) return Colors.orange;
    return const Color(0xFF1565C0);
  }

  @override
  Widget build(BuildContext context) {
    final color = _accentColor;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color.withOpacity(0.8)),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 12, color: color.withOpacity(0.8))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: color,
                      height: 1.0)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(unit,
                    style: TextStyle(
                        fontSize: 13, color: color.withOpacity(0.7))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 5,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 보조 지표 카드 ────────────────────────────────────────────

class _SecondaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool danger;
  final bool warning;

  const _SecondaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.danger,
    required this.warning,
  });

  Color get _color {
    if (danger) return Colors.redAccent;
    if (warning) return Colors.orange;
    return const Color(0xFF1565C0);
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color.withOpacity(0.8)),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      fontSize: 11, color: color.withOpacity(0.7))),
              if (danger) ...[
                const Spacer(),
                Icon(Icons.warning_rounded, size: 14, color: color),
              ],
            ],
          ),
          Text(
            value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

// ── 이상 감지 배너 ────────────────────────────────────────────

class _AnomalyBanner extends StatelessWidget {
  final List<String> dtcCodes;
  const _AnomalyBanner({required this.dtcCodes});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: Colors.redAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('이상 값 감지됨',
                    style: TextStyle(
                        color: Colors.redAccent, fontWeight: FontWeight.bold)),
                if (dtcCodes.isNotEmpty)
                  Text('DTC: ${dtcCodes.join(', ')}',
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── DTC 코드 섹션 ─────────────────────────────────────────────

class _DtcSection extends StatelessWidget {
  final List<String> codes;
  const _DtcSection({required this.codes});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.build_circle_outlined, size: 16, color: Colors.orange),
              SizedBox(width: 6),
              Text('DTC 진단 코드',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: codes
                .map((code) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.orange.withOpacity(0.4)),
                      ),
                      child: Text(code,
                          style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── 속도 추이 차트 ────────────────────────────────────────────

class _SpeedChart extends StatelessWidget {
  final List<Telemetry> history;
  const _SpeedChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final spots = history.reversed
        .toList()
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.speed))
        .toList();

    final maxY = (history.map((t) => t.speed).reduce((a, b) => a > b ? a : b) + 20)
        .clamp(60.0, 250.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.show_chart, size: 16, color: Color(0xFF1565C0)),
            const SizedBox(width: 6),
            const Text('속도 추이',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
            const Spacer(),
            Text('최근 ${history.length}개',
                style:
                    TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY,
              clipData: const FlClipData.all(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 3,
                getDrawingHorizontalLine: (v) => FlLine(
                  color: Colors.white.withOpacity(0.06),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: maxY / 3,
                    getTitlesWidget: (value, _) => Text(
                      '${value.toInt()}',
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade600),
                    ),
                  ),
                ),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: const Color(0xFF1565C0),
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF1565C0).withOpacity(0.25),
                        const Color(0xFF1565C0).withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── 데이터 없을 때 ────────────────────────────────────────────

class _NoDataView extends StatelessWidget {
  final String vehicleId;
  const _NoDataView({required this.vehicleId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sensors_off,
              size: 64, color: Colors.grey.shade600),
          const SizedBox(height: 16),
          const Text('데이터 없음',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('시뮬레이터 또는 OBD-II 동글을 연결하세요.',
              style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
