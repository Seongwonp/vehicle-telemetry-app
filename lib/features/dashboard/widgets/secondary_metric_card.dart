import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';

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
      padding: const EdgeInsets.all(Spacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Radii.mdAll,
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
              const SizedBox(width: Spacing.xxs),
              Text(label,
                  style: TextStyle(
                      fontSize: FontSizes.badge, color: colors.textSecondary)),
              if (danger) Icon(Icons.warning_rounded, size: 14, color: color),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTheme.gaugeNumberStyle(
                fontSize: FontSizes.title,
                color: danger ? color : colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
