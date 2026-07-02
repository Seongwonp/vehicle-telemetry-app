import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';

/// 로그인 전 화면이라 실제 API를 호출할 수 없다 — 순수 장식용으로
/// "살아있는 대시보드" 느낌만 준다. 실제 데이터는 로그인 후 대시보드에서 보여준다.
class LivePreviewCard extends StatefulWidget {
  const LivePreviewCard({super.key});

  @override
  State<LivePreviewCard> createState() => _LivePreviewCardState();
}

class _LivePreviewCardState extends State<LivePreviewCard>
    with SingleTickerProviderStateMixin {
  final _random = Random();
  final List<double> _speedHistory = List.generate(20, (_) => 80);
  double _speed = 80;
  double _rpm = 2400;
  double _temp = 88;

  late final AnimationController _pulseController;
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _tickTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      setState(() {
        // 실제 시뮬레이터처럼 급변 없이 완만하게 흔들리는 값
        _speed = (_speed + _random.nextDouble() * 16 - 8).clamp(40.0, 160.0);
        _rpm = (_rpm + _random.nextDouble() * 400 - 200).clamp(1200.0, 5200.0);
        _temp = (_temp + _random.nextDouble() * 1.6 - 0.8).clamp(78.0, 98.0);
        _speedHistory.add(_speed);
        if (_speedHistory.length > 20) _speedHistory.removeAt(0);
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _tickTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spots = _speedHistory
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_car_filled,
                  size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              const Text('SIM-001',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary)),
              const Spacer(),
              FadeTransition(
                opacity: _pulseController,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.success,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              const Text('LIVE PREVIEW',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: AppTheme.success)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 90,
            child: LineChart(
              LineChartData(
                minY: 30,
                maxY: 170,
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppTheme.primary,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.primary.withOpacity(0.3),
                          AppTheme.primary.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatTile(
                  label: '속도', value: _speed.toStringAsFixed(0), unit: 'km/h'),
              const SizedBox(width: 10),
              _StatTile(
                  label: 'RPM', value: _rpm.toStringAsFixed(0), unit: 'rpm'),
              const SizedBox(width: 10),
              _StatTile(
                  label: '온도', value: _temp.toStringAsFixed(0), unit: '°C'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _StatTile(
      {required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppTheme.textTertiary)),
            const SizedBox(height: 2),
            Text.rich(
              TextSpan(
                text: value,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary),
                children: [
                  TextSpan(
                    text: ' $unit',
                    style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.normal,
                        color: AppTheme.textTertiary),
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
