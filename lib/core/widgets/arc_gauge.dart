import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 270도 스윕 아크 게이지 — 실물 차량 계기판을 흉내낸 커스텀 페인터.
/// 값이 바뀔 때마다 새로 그리지 않고 TweenAnimationBuilder로 부드럽게
/// 보간해서, 폴링(2초)마다 바늘이 뚝뚝 끊기지 않고 스윽 움직이게 한다.
class ArcGauge extends StatelessWidget {
  final double value;
  final double maxValue;
  final String label;
  final String unit;
  final double size;
  final Color color;
  final bool danger;
  final bool warning;

  const ArcGauge({
    required this.value,
    required this.maxValue,
    required this.label,
    required this.unit,
    this.size = 168,
    this.color = AppTheme.primary,
    this.danger = false,
    this.warning = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor =
        danger ? AppTheme.danger : (warning ? AppTheme.warning : color);
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
              trackColor: AppTheme.border,
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
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textTertiary,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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

    // 은은한 글로우 — 크리스프한 아크 뒤에 블러 처리된 같은 색을 한 번 더 깔아
    // 계기판이 빛나는 느낌을 낸다.
    final glowPaint = Paint()
      ..color = activeColor.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawArc(rect, _startAngle, sweep, false, glowPaint);

    final activePaint = Paint()
      ..shader = SweepGradient(
        startAngle: _startAngle,
        endAngle: _startAngle + _sweepTotal,
        colors: [activeColor.withOpacity(0.7), activeColor],
        stops: const [0, 1],
        transform: GradientRotation(_startAngle),
      ).createShader(rect)
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
