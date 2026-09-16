import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/models/telemetry.dart';
import '../../../core/theme/app_theme.dart';

class SpeedChart extends StatelessWidget {
  final List<Telemetry> history;

  /// 재연결·지연 중이면 true — 선을 흐리게, 제목에 "마지막으로 받은"을 붙인다.
  final bool past;
  const SpeedChart({required this.history, this.past = false, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final primary =
        past ? colors.textTertiary : Theme.of(context).colorScheme.primary;
    final spots = history.reversed
        .toList()
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.speed))
        .toList();

    final maxY =
        (history.map((t) => t.speed).reduce((a, b) => a > b ? a : b) + 20)
            .clamp(60.0, 250.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.show_chart, size: 16, color: primary),
            const SizedBox(width: Spacing.xxs),
            // 좁은 폭·큰 글자에서는 개수가 제목 아래로 내려간다(제목이 세 줄로 눌리지 않게).
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: Spacing.xs,
                children: [
                  Text(past ? '마지막으로 받은 속도 추이' : '속도 추이',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: FontSizes.body)),
                  Text(
                      past
                          ? '최근 ${history.length}개 · 이후 수신 없음'
                          : '최근 ${history.length}개',
                      style: TextStyle(
                          fontSize: FontSizes.badge,
                          color: colors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
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
                  color: colors.border,
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
                          fontSize: FontSizes.badge,
                          color: colors.textTertiary),
                    ),
                  ),
                ),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: primary,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        primary.withValues(alpha: 0.25),
                        primary.withValues(alpha: 0.0),
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
