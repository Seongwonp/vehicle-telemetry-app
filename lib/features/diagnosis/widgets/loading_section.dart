import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/app_theme.dart';

class DiagnosisLoadingSection extends StatelessWidget {
  const DiagnosisLoadingSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    const steps = [
      '센서 데이터 수집 중...',
      '이상 이벤트 조회 중...',
      '진단 결과 생성 중...',
    ];
    return Column(
      children: steps
          .map((step) => Padding(
                padding: const EdgeInsets.only(bottom: Spacing.sm),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Text(step,
                        style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: FontSizes.body)),
                  ],
                ),
              ))
          .toList(),
    );
  }
}
