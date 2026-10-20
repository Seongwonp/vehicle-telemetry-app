import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';

/// 하나만 고르는 필터 칩. 이상 이력·주행 기록 탭이 같이 쓴다.
/// Material `ChoiceChip`과 겹치지 않게 `App` 접두사를 붙였다.
class AppChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const AppChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.sm, vertical: Spacing.xs),
        decoration: BoxDecoration(
          color: selected ? primary.withValues(alpha: 0.15) : colors.surface,
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(color: selected ? primary : colors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: FontSizes.caption,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? primary : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
