import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class DiagnosisErrorSection extends StatelessWidget {
  final String message;
  const DiagnosisErrorSection({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.danger, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: AppTheme.danger, fontSize: 13, height: 1.5)),
          ),
        ],
      ),
    );
  }
}
