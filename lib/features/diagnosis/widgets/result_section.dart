import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class DiagnosisResultSection extends StatelessWidget {
  final String diagnosis;
  final int dataPoints;
  final DateTime diagnosedAt;

  const DiagnosisResultSection({
    required this.diagnosis,
    required this.dataPoints,
    required this.diagnosedAt,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${diagnosedAt.hour.toString().padLeft(2, '0')}:${diagnosedAt.minute.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 메타 정보 바
        Row(
          children: [
            const Icon(Icons.check_circle, size: 15, color: AppTheme.success),
            const SizedBox(width: 6),
            const Text('진단 완료',
                style: TextStyle(
                    color: AppTheme.success,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('데이터 $dataPoints개 · $timeStr',
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
        const SizedBox(height: 10),

        // AI 응답 본문
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.border),
          ),
          child: SelectableText(
            diagnosis,
            style: const TextStyle(fontSize: 14, height: 1.7),
          ),
        ),

        // 하단 안내
        const SizedBox(height: 10),
        const Text(
          '* AI 진단은 참고용입니다. 정확한 진단은 정비사에게 문의하세요.',
          style: TextStyle(
              fontSize: 11,
              color: AppTheme.textTertiary,
              fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}
