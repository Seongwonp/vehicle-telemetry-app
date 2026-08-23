import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AnomalyBanner extends StatelessWidget {
  final List<String> dtcCodes;
  const AnomalyBanner({required this.dtcCodes, super.key});

  @override
  Widget build(BuildContext context) {
    final danger = context.appColors.danger;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: danger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: danger.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_rounded, color: danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('이상 값 감지됨',
                    style: TextStyle(
                        color: danger, fontWeight: FontWeight.bold)),
                if (dtcCodes.isNotEmpty)
                  Text('DTC: ${dtcCodes.join(', ')}',
                      style: TextStyle(color: danger, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
