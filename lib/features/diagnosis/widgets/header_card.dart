import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

class DiagnosisHeaderCard extends StatelessWidget {
  final String vehicleId;
  const DiagnosisHeaderCard({required this.vehicleId, super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(Radii.md),
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
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            child: Icon(Icons.fact_check_outlined,
                size: 22, color: cs.onPrimaryContainer),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('센서 기반 보조 진단',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: FontSizes.body,
                        color: cs.onSurface)),
                const SizedBox(height: Spacing.xxs),
                Text(
                  '최근 센서 데이터와 DTC·이상 이력을 바탕으로 참고용 결과를 생성합니다.',
                  style: TextStyle(
                      fontSize: FontSizes.caption,
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
