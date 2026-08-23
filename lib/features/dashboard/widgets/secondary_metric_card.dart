import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SecondaryMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool danger;

  const SecondaryMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.danger,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = danger ? colors.danger : colors.textSecondary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: danger ? color.withValues(alpha: 0.45) : colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(fontSize: 11, color: colors.textSecondary)),
              if (danger) ...[
                const Spacer(),
                Icon(Icons.warning_rounded, size: 14, color: color),
              ],
            ],
          ),
          Text(
            value,
            style: AppTheme.gaugeNumberStyle(
              fontSize: 20,
              color: danger ? color : colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
