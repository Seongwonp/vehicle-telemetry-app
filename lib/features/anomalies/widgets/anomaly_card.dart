import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/models/anomaly.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';

/// 이상 이력 목록의 카드.
///
/// 예전에는 바깥 [Row]에 `[심각도 바][아이콘][Expanded 내용][심각도 배지]`를 나란히
/// 뒀는데, 글자 배율을 1.3배로만 올려도 오른쪽 배지가 내용 영역을 밀어내 잘렸다
/// (320·360px에서 재현, test/responsive_overflow_test.dart).
///
/// 배지를 제목과 같은 줄로 옮기고 제목에 [Expanded]를 줬다. 같은 정보를 담으면서
/// 가로로 경쟁하는 고정 폭 요소가 하나 줄어든다.
///
/// 색도 `AppTheme.danger` 같은 정적 상수 대신 [AppSemanticColors]에서 가져온다 —
/// 정적 상수는 다크 모드에서 그대로라 배경 대비가 무너졌다.
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
            // 왼쪽 심각도 바 — 목록을 훑을 때 색만으로 구분되게 한다.
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
                              _SeverityBadge(
                                severity: anomaly.severity,
                                color: color,
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

class _SeverityBadge extends StatelessWidget {
  final String severity;
  final Color color;
  const _SeverityBadge({required this.severity, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: Radii.pillAll,
      ),
      child: Text(
        severity,
        style: TextStyle(
          fontSize: FontSizes.badge,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
