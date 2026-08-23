import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SecondaryMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool danger;
  final bool warning;

  const SecondaryMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.danger,
    required this.warning,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = danger
        ? colors.danger
        : (warning ? colors.warning : Theme.of(context).colorScheme.primary);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color.withOpacity(0.8)),
              const SizedBox(width: 5),
              Text(label,
                  style:
                      TextStyle(fontSize: 11, color: color.withOpacity(0.7))),
              if (danger) ...[
                const Spacer(),
                Icon(Icons.warning_rounded, size: 14, color: color),
              ],
            ],
          ),
          Text(
            value,
            style: AppTheme.gaugeNumberStyle(fontSize: 22, color: color),
          ),
        ],
      ),
    );
  }
}
