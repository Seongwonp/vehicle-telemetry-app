import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AnomalyBanner extends StatelessWidget {
  final List<String> dtcCodes;
  const AnomalyBanner({required this.dtcCodes, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.danger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: AppTheme.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('이상 값 감지됨',
                    style: TextStyle(
                        color: AppTheme.danger, fontWeight: FontWeight.bold)),
                if (dtcCodes.isNotEmpty)
                  Text('DTC: ${dtcCodes.join(', ')}',
                      style: const TextStyle(
                          color: AppTheme.danger, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
