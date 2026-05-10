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

  @override
  void initState() {
    super.initState();
    _fetchData();
    // 2초마다 자동 갱신
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _fetchData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final data = await ApiClient().getRecentTelemetry(widget.vehicleId, limit: 20);
      final list = data
          .map((e) => Telemetry.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() {
          _latest = list.isNotEmpty ? list.first : null;
          _history = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vehicleId),
        actions: [
          IconButton(
            icon: const Icon(Icons.warning_amber),
            tooltip: '이상 이력',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AnomalyListScreen(vehicleId: widget.vehicleId),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.psychology),
            tooltip: 'AI 진단',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DiagnosisScreen(vehicleId: widget.vehicleId),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _latest == null
              ? const Center(child: Text('데이터가 없습니다\n시뮬레이터 또는 OBD-II 동글을 연결하세요'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (_latest!.hasAnomaly)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.15),
                            border: Border.all(color: Colors.redAccent),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning, color: Colors.redAccent),
                              SizedBox(width: 8),
                              Text('이상 값이 감지되었습니다',
                                  style: TextStyle(color: Colors.redAccent)),
                            ],
                          ),
                        ),
                      // 센서 카드 그리드
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.4,
                        children: [
                          _SensorCard(
                            label: '속도',
                            value: '${_latest!.speed.toStringAsFixed(1)} km/h',
                            icon: Icons.speed,
                            warning: _latest!.speed > 200,
                          ),
                          _SensorCard(
                            label: 'RPM',
                            value: '${_latest!.rpm}',
                            icon: Icons.rotate_right,
                            warning: _latest!.rpm > 6000,
                          ),
                          _SensorCard(
                            label: '엔진 온도',
                            value: '${_latest!.engineTemp.toStringAsFixed(1)}°C',
                            icon: Icons.thermostat,
                            warning: _latest!.engineTemp > 105,
                          ),
                          _SensorCard(
                            label: '연료',
                            value: '${_latest!.fuelLevel.toStringAsFixed(1)}%',
                            icon: Icons.local_gas_station,
                            warning: _latest!.fuelLevel < 10,
                          ),
                          _SensorCard(
                            label: '배터리',
                            value: '${_latest!.batteryVoltage.toStringAsFixed(2)}V',
                            icon: Icons.battery_charging_full,
                            warning: _latest!.batteryVoltage < 11.5 ||
                                _latest!.batteryVoltage > 15.0,
                          ),
                          _SensorCard(
                            label: '스로틀',
                            value: '${_latest!.throttlePosition.toStringAsFixed(1)}%',
                            icon: Icons.tune,
                            warning: false,
                          ),
                        ],
                      ),
                      if (_latest!.dtcCodes.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            border: Border.all(color: Colors.orange),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('DTC 진단 코드',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange)),
                              const SizedBox(height: 8),
                              ..._latest!.dtcCodes.map((code) => Text('• $code',
                                  style: const TextStyle(color: Colors.orange))),
                            ],
                          ),
                        ),
                      ],
                      // 속도 추이 차트
                      if (_history.length > 1) ...[
                        const SizedBox(height: 24),
                        const Text('속도 추이',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 160,
                          child: LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: false),
                              titlesData: const FlTitlesData(show: false),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _history.reversed
                                      .toList()
                                      .asMap()
                                      .entries
                                      .map((e) => FlSpot(
                                            e.key.toDouble(),
                                            e.value.speed,
                                          ))
                                      .toList(),
                                  isCurved: true,
                                  color: const Color(0xFF1565C0),
                                  barWidth: 2,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: const Color(0xFF1565C0).withOpacity(0.1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool warning;

  const _SensorCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.warning,
  });

  @override
  Widget build(BuildContext context) {
    final color = warning ? Colors.redAccent : const Color(0xFF1565C0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }
}
