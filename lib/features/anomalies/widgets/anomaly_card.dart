import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/models/anomaly.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/status_pill.dart';

/// 이상 이력 목록의 카드.
///
/// 배지를 제목 줄에 두고 제목에 [Expanded]를 준다 — 바깥 [Row]에 두면 글자 배율이
/// 커질 때 잘린다(test/responsive_overflow_test.dart). 색은 다크 모드를 위해
/// [AppSemanticColors]에서 가져온다.
class AnomalyCard extends StatelessWidget {
  final Anomaly anomaly;
  const AnomalyCard({required this.anomaly, super.key});

  IconData get _anomalyIcon {
    final type = anomaly.anomalyType.toLowerCase();
    if (type.contains('과열') || type.contains('온도')) return Icons.thermostat;
    if (type.contains('rpm') || type.contains('과부하')) {
      return Icons.rotate_right;
    }
    if (type.contains('배터리') || type.contains('전압')) {
      return Icons.battery_alert;
    }
    if (type.contains('속도') || type.contains('과속')) return Icons.speed;
    if (type.contains('dtc') || type.contains('진단')) return Icons.build_circle;
    return Icons.warning_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = anomaly.isHigh ? colors.danger : colors.warning;

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: Radii.mdAll,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(Radii.md),
                  bottomLeft: Radius.circular(Radii.md),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: Radii.smAll,
                      ),
                      child: Icon(_anomalyIcon, color: color, size: 20),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  anomaly.anomalyType,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: FontSizes.body,
                                    height: 1.3,
                                    color: color,
                                  ),
                                ),
                              ),
                              const SizedBox(width: Spacing.xs),
                              StatusPill(
                                label: anomaly.severity,
                                color: color,
                                fillOpacity: 0.15,
                              ),
                            ],
                          ),
                          const SizedBox(height: Spacing.xxs),
                          Text(
                            anomaly.description,
                            style: TextStyle(
                              fontSize: FontSizes.caption,
                              height: 1.4,
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: Spacing.xs),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: colors.textTertiary,
                              ),
                              const SizedBox(width: Spacing.xxs),
                              Flexible(
                                child: Text(
                                  timeago.format(anomaly.detectedAt,
                                      locale: 'ko'),
                                  style: TextStyle(
                                    fontSize: FontSizes.badge,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
