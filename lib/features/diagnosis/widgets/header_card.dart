import 'package:flutter/material.dart';

class DiagnosisHeaderCard extends StatelessWidget {
  final String vehicleId;
  const DiagnosisHeaderCard({required this.vehicleId, super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.psychology, size: 30, color: cs.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gemini AI 차량 진단',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: cs.primary)),
                const SizedBox(height: 4),
                Text(
                  '최근 센서 데이터 · DTC 코드 · 이상 이벤트를\n종합 분석하여 진단 결과를 제공합니다.',
                  style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withOpacity(0.55),
                      height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
