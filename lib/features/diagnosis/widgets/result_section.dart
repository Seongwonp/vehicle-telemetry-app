import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../../core/theme/app_theme.dart';

class DiagnosisResultSection extends StatelessWidget {
  final String diagnosis;
  final int dataPoints;
  final String grade;
  final int score;
  final DateTime diagnosedAt;

  const DiagnosisResultSection({
    required this.diagnosis,
    required this.dataPoints,
    required this.grade,
    required this.score,
    required this.diagnosedAt,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final timeStr =
        '${diagnosedAt.hour.toString().padLeft(2, '0')}:${diagnosedAt.minute.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                style: TextStyle(
                    fontSize: 11, color: colors.textSecondary)),
          ],
        ),
        const SizedBox(height: 12),

        _ReferenceSummary(grade: grade, score: score),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: colors.backgroundElevated,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 16, color: colors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '이 결과는 참고용입니다. 이상 징후나 DTC가 확인되면 정비사의 점검을 받으세요.',
                  style: TextStyle(
                      fontSize: 12, height: 1.45, color: colors.textSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border),
          ),
          child: MarkdownBody(
            data: diagnosis,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(
                  fontSize: 14, height: 1.7, color: colors.textPrimary),
              strong: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppTheme.primaryBright),
              h1: AppTheme.gaugeNumberStyle(
                  fontSize: 20, color: colors.textPrimary),
              h2: AppTheme.gaugeNumberStyle(
                  fontSize: 18, color: colors.textPrimary),
              h3: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary),
              listBullet: TextStyle(
                  fontSize: 14, color: colors.textSecondary),
              blockSpacing: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReferenceSummary extends StatelessWidget {
  final String grade;
  final int score;

  const _ReferenceSummary({required this.grade, required this.score});

  Color get _gradeColor {
    switch (grade.toUpperCase()) {
      case 'A':
      case 'B':
        return AppTheme.success;
      case 'C':
      case 'D':
        return AppTheme.warning;
      default:
        return AppTheme.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = _gradeColor;
    final clampedScore = score.clamp(0, 100);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Text(
            '참고 지표',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary),
          ),
          const Spacer(),
          Text(
            '${grade.toUpperCase()} 등급',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: color),
          ),
          Container(
            width: 1,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: colors.border,
          ),
          Text(
            '$clampedScore/100',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary),
          ),
        ],
      ),
    );
  }
}
