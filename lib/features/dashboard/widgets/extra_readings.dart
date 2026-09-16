import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../dashboard_view_state.dart';

/// 기준이 없는 값(연료·스로틀) — 라벨과 값 한 줄씩. 초과 판정을 하지 않으므로 타일로 올리지 않는다.
class ExtraReadings extends StatelessWidget {
  final DashboardViewState state;
  const ExtraReadings({required this.state, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final live = state.isLive;
    return Container(
      key: const Key('extra_readings'),
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Radii.mdAll,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < state.extras.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
              decoration: BoxDecoration(
                border: i == 0
                    ? null
                    : Border(top: BorderSide(color: colors.border)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      state.extras[i].label,
                      style: TextStyle(
                        fontSize: FontSizes.body,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    '${state.extras[i].valueText}${state.extras[i].unit}',
                    style: AppTheme.gaugeNumberStyle(
                      fontSize: FontSizes.subtitle,
                      color: live ? colors.textPrimary : colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.sm),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                live ? '연료·스로틀은 이상 기준이 없습니다' : '${state.receivedClock}에 받은 값',
                style: TextStyle(
                  fontSize: FontSizes.badge,
                  color: colors.textTertiary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
