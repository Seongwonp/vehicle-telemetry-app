import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class DtcSection extends StatelessWidget {
  final List<String> codes;
  const DtcSection({required this.codes, super.key});

  @override
  Widget build(BuildContext context) {
    final warning = context.appColors.warning;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: warning.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.build_circle_outlined,
                  size: 16, color: warning),
              const SizedBox(width: 6),
              Text('DTC 진단 코드',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: warning,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: codes
                .map((code) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: warning.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(code,
                          style: TextStyle(
                              color: warning,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
