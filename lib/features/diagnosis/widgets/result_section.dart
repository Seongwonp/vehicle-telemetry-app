import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';

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
            const SizedBox(width: Spacing.xs),
            const Text('진단 완료',
                style: TextStyle(
                    color: AppTheme.success,
                    fontSize: FontSizes.caption,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('데이터 $dataPoints개 · $timeStr',
                style: TextStyle(
                    fontSize: FontSizes.badge, color: colors.textSecondary)),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        _ReferenceSummary(grade: grade, score: score),
        const SizedBox(height: Spacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: Spacing.sm, vertical: Spacing.sm),
          decoration: BoxDecoration(
            color: colors.backgroundElevated,
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 16, color: colors.textSecondary),
              const SizedBox(width: Spacing.xs),
              Expanded(
                child: Text(
                  '이 결과는 참고용입니다. 이상 징후나 DTC가 확인되면 정비사의 점검을 받으세요.',
                  style: TextStyle(
                      fontSize: FontSizes.caption,
                      height: 1.45,
                      color: colors.textSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(color: colors.border),
          ),
          child: MarkdownBody(
            data: diagnosis,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(
                  fontSize: FontSizes.body,
                  height: 1.7,
                  color: colors.textPrimary),
              strong: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppTheme.primaryBright),
              h1: AppTheme.gaugeNumberStyle(
                  fontSize: FontSizes.title, color: colors.textPrimary),
              h2: AppTheme.gaugeNumberStyle(
                  fontSize: FontSizes.subtitle, color: colors.textPrimary),
              h3: const TextStyle(
                  fontSize: FontSizes.body,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary),
              listBullet: TextStyle(
                  fontSize: FontSizes.body, color: colors.textSecondary),
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
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md, vertical: Spacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Text(
            '참고 지표',
            style: TextStyle(
                fontSize: FontSizes.caption,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary),
          ),
          const Spacer(),
          Text(
            '${grade.toUpperCase()} 등급',
            style: TextStyle(
                fontSize: FontSizes.caption,
                fontWeight: FontWeight.w700,
                color: color),
          ),
          Container(
            width: 1,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: Spacing.sm),
            color: colors.border,
          ),
          Text(
            '$clampedScore/100',
            style: TextStyle(
                fontSize: FontSizes.caption,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary),
          ),
        ],
      ),
    );
  }
}
