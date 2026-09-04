import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/arc_gauge.dart';

class PrimaryMetricCard extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;
  final String unit;
  final IconData icon;
  final bool danger;

  const PrimaryMetricCard({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.unit,
    required this.icon,
    required this.danger,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color =
        danger ? colors.danger : Theme.of(context).colorScheme.primary;
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: colors.textSecondary),
              const SizedBox(width: Spacing.xxs),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: FontSizes.caption,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final gaugeSize =
                  (constraints.maxWidth - 4).clamp(104.0, 144.0).toDouble();
              return Center(
                child: ArcGauge(
                  value: value,
                  maxValue: maxValue,
                  label: '',
                  unit: unit,
                  size: gaugeSize,
                  danger: danger,
                  color: color,
                ),
              );
            },
          ),
          if (danger)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber_rounded, size: 14, color: color),
                const SizedBox(width: Spacing.xxs),
                Flexible(
                  child: Text(
                    '이상 기준 초과',
                    style: TextStyle(
                      fontSize: FontSizes.badge,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
