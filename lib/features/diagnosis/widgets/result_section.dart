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

        // 등급/점수 카드
        _GradeScoreCard(grade: grade, score: score),
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
          child: MarkdownBody(
            data: diagnosis,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                  fontSize: 14, height: 1.7, color: AppTheme.textPrimary),
              strong: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppTheme.primaryBright),
              h1: AppTheme.gaugeNumberStyle(fontSize: 20),
              h2: AppTheme.gaugeNumberStyle(fontSize: 18),
              h3: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary),
              listBullet: const TextStyle(
                  fontSize: 14, color: AppTheme.textSecondary),
              blockSpacing: 12,
            ),
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

// A~F 등급을 3단계 색상(양호/주의/위험)으로 매핑해 점수 막대와 함께 보여준다.
// 텍스트 진단을 다 읽지 않아도 한눈에 상태를 파악할 수 있게 하는 목적.
class _GradeScoreCard extends StatelessWidget {
  final String grade;
  final int score;

  const _GradeScoreCard({required this.grade, required this.score});

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
    final color = _gradeColor;
    final clampedScore = score.clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Text(
              grade.toUpperCase(),
              style: AppTheme.gaugeNumberStyle(fontSize: 24, color: color),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('차량 건강 점수',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary.withOpacity(0.9))),
                    const Spacer(),
                    Text('$clampedScore',
                        style: AppTheme.gaugeNumberStyle(
                            fontSize: 18, color: color)),
                    Text('/100',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary.withOpacity(0.7))),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: clampedScore / 100,
                    minHeight: 6,
                    backgroundColor: AppTheme.bgElevated,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
