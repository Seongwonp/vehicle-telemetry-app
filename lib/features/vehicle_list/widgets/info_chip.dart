import 'package:flutter/material.dart';

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
        Icon(icon, size: 11, color: cs.onSurface.withOpacity(0.5)),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}
