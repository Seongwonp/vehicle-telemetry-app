import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ArcGauge extends StatelessWidget {
  final double value;
  final double maxValue;
  final String label;
  final String unit;
  final double size;
  final Color? color;
  final bool danger;
  final bool warning;

  const ArcGauge({
    required this.value,
    required this.maxValue,
    required this.label,
    required this.unit,
    this.size = 168,
    this.color,
    this.danger = false,
    this.warning = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final activeColor = danger
        ? colors.danger
        : (warning ? colors.warning : color ?? Theme.of(context).colorScheme.primary);
    final ratio = (value / maxValue).clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: ratio),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, animatedRatio, _) {
          return CustomPaint(
            painter: _ArcGaugePainter(
              ratio: animatedRatio,
              trackColor: colors.border,
              activeColor: activeColor,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value.toStringAsFixed(
                        value >= 1000 ? 0 : (value % 1 == 0 ? 0 : 1)),
                    style: AppTheme.gaugeNumberStyle(
                      fontSize: size * 0.2,
                      color: activeColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.textTertiary,
                      letterSpacing: 0.4,
                    ),
                  ),
                  if (label.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ArcGaugePainter extends CustomPainter {
  static const _startAngle = 0.75 * math.pi; // 135˚ — 바닥 왼쪽에서 시작
  static const _sweepTotal = 1.5 * math.pi; // 270˚ 스윕

  final double ratio;
  final Color trackColor;
  final Color activeColor;

  _ArcGaugePainter({
    required this.ratio,
    required this.trackColor,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 10.0;
    final radius = (size.shortestSide - strokeWidth) / 2 - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, _startAngle, _sweepTotal, false, trackPaint);

    if (ratio <= 0) return;
    final sweep = _sweepTotal * ratio;

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, _startAngle, sweep, false, activePaint);
  }

  @override
  bool shouldRepaint(covariant _ArcGaugePainter oldDelegate) {
    return oldDelegate.ratio != ratio ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.trackColor != trackColor;
  }
}
