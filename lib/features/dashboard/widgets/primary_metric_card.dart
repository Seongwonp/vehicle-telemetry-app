import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// 대시보드 상단의 속도/RPM처럼 가장 중요한 지표를 크게 보여주는 카드.
class PrimaryMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final double ratio; // 0.0 ~ 1.0
  final bool danger;
  final bool warning;

  const PrimaryMetricCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.ratio,
    required this.danger,
    required this.warning,
    super.key,
  });

  Color get _accentColor {
    if (danger) return AppTheme.danger;
    if (warning) return AppTheme.warning;
    return AppTheme.primary;
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
