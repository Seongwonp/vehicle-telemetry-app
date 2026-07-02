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

  Color get _color {
    if (danger) return AppTheme.danger;
    if (warning) return AppTheme.warning;
    return AppTheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
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
                  style: TextStyle(
                      fontSize: 11, color: color.withOpacity(0.7))),
              if (danger) ...[
                const Spacer(),
                Icon(Icons.warning_rounded, size: 14, color: color),
              ],
            ],
          ),
          Text(
            value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
