import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';

class DiagnosisErrorSection extends StatelessWidget {
  final String message;
  const DiagnosisErrorSection({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.danger, size: 18),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: AppTheme.danger,
                    fontSize: FontSizes.caption,
                    height: 1.5)),
          ),
        ],
      ),
    );
  }
}
