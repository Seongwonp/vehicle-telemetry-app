import 'package:flutter/material.dart';

class DiagnosisHeaderCard extends StatelessWidget {
  final String vehicleId;
  const DiagnosisHeaderCard({required this.vehicleId, super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.fact_check_outlined,
                size: 22, color: cs.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('센서 기반 보조 진단',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: cs.onSurface)),
                const SizedBox(height: 4),
                Text(
                  '최근 센서 데이터와 DTC·이상 이력을 바탕으로 참고용 결과를 생성합니다.',
                  style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                      height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
