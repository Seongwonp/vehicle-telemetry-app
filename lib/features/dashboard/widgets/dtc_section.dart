import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/status_pill.dart';

class DtcSection extends StatelessWidget {
  final List<String> codes;
  const DtcSection({required this.codes, super.key});

  @override
  Widget build(BuildContext context) {
    final warning = context.appColors.warning;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: warning.withValues(alpha: 0.08),
        borderRadius: Radii.mdAll,
        border: Border.all(color: warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.build_circle_outlined, size: 16, color: warning),
              const SizedBox(width: Spacing.xs),
              Text('DTC 진단 코드',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: warning,
                      fontSize: FontSizes.caption)),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Wrap(
            spacing: Spacing.xs,
            runSpacing: Spacing.xxs,
            children: codes
                .map((code) => StatusPill(
                      label: code,
                      color: warning,
                      // 보조 정보라 채움 대신 테두리를 쓴다.
                      variant: StatusPillVariant.outlined,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
