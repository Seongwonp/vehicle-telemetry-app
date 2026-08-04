import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/models/anomaly.dart';
import '../../../core/theme/app_theme.dart';

class AnomalyCard extends StatelessWidget {
  final Anomaly anomaly;
  const AnomalyCard({required this.anomaly, super.key});

  Color get _severityColor =>
      anomaly.isHigh ? AppTheme.danger : AppTheme.warning;

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
    final color = _severityColor;

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // 왼쪽 심각도 바
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
              ),
            ),

            // 아이콘
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 6, 16),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_anomalyIcon, color: color, size: 20),
              ),
            ),

            // 내용
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anomaly.anomalyType,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      anomaly.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 11, color: AppTheme.textTertiary),
                        const SizedBox(width: 3),
                        Text(
                          timeago.format(anomaly.detectedAt, locale: 'ko'),
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 심각도 뱃지
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  anomaly.severity,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
