import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

class InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const InfoChip({required this.label, required this.icon, super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: cs.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: Spacing.xxs),
        Text(
          label,
          style: TextStyle(
            fontSize: FontSizes.caption,
            color: cs.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
