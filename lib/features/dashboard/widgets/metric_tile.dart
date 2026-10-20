import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../dashboard_view_state.dart';

/// 기준이 있는 계측값 하나. 세 모양이 있다.
///
/// - **수신 중**: 큰 숫자 + 단위 + 기준 한 줄
/// - **기준 초과**: 같은 자리, danger 테두리·바탕 + 경고 아이콘
/// - **지난 값**(재연결·지연): 큰 숫자 자리를 `—`로 비우고 값은 작게 둔다(현재 값으로 읽히지 않게).
///
/// 높이는 내용이 정한다 — 고정 비율 칸이면 큰 글자 배율에서 넘친다.
class MetricTile extends StatelessWidget {
  final MetricReading reading;
  final DashboardViewState state;

  const MetricTile({required this.reading, required this.state, super.key});

  static IconData iconFor(MetricKind kind) => switch (kind) {
        MetricKind.speed => Icons.speed_outlined,
        MetricKind.rpm => Icons.rotate_right,
        MetricKind.engineTemp => Icons.thermostat_outlined,
        MetricKind.battery => Icons.battery_charging_full_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final live = state.isLive;
    final over = state.showsOver(reading);
    final accent = over ? colors.danger : colors.textSecondary;

    final available = reading.available;
    final semantics = !available
        ? (live
            ? '${reading.label} ${reading.valueText}, ${reading.limitText}'
            : '${reading.label}, ${state.receivedClock}에 받은 레코드에도 값 없음, 현재 값 아님')
        : live
            ? '${reading.label} ${reading.valueText} ${reading.unit}, ${reading.limitText}'
            : '${reading.label}, ${state.receivedClock}에 받은 값 '
                '${reading.valueText} ${reading.unit}, 현재 값 아님';

    return Semantics(
      container: true,
      label: semantics,
      excludeSemantics: true,
      child: Container(
        key: Key('metric_tile_${reading.kind.name}'),
        padding: const EdgeInsets.all(Spacing.sm),
        decoration: BoxDecoration(
          color: over ? colors.danger.withValues(alpha: 0.08) : colors.surface,
          borderRadius: Radii.mdAll,
          border: Border.all(
            color: over ? colors.danger.withValues(alpha: 0.45) : colors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(iconFor(reading.kind), size: 16, color: accent),
                const SizedBox(width: Spacing.xxs),
                Flexible(
                  child: Text(
                    reading.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: FontSizes.caption,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                if (over) ...[
                  const SizedBox(width: Spacing.xxs),
                  Icon(Icons.warning_rounded, size: 14, color: colors.danger),
                ],
              ],
            ),
            const SizedBox(height: Spacing.xs),
            if (live && !available)
              // 값 없는 선택 센서는 0 대신 흐린 낱말로 둔다.
              Text(
                reading.valueText,
                key: Key('metric_tile_${reading.kind.name}_missing'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: FontSizes.subtitle,
                  fontWeight: FontWeight.w600,
                  color: colors.textTertiary,
                ),
              )
            else if (live)
              _LiveValue(reading: reading, over: over)
            else
              Text(
                '—',
                key: Key('metric_tile_${reading.kind.name}_blank'),
                style: AppTheme.gaugeNumberStyle(
                  fontSize: FontSizes.displayCompact,
                  color: colors.textTertiary,
                ),
              ),
            const SizedBox(height: Spacing.xs),
            if (live)
              Text(
                reading.limitText,
                style: TextStyle(
                  fontSize: FontSizes.badge,
                  fontWeight: over ? FontWeight.w700 : FontWeight.w400,
                  color: over ? colors.danger : colors.textTertiary,
                ),
              )
            else
              Text(
                // 받은 시각은 타일 위 머리글이 보여준다.
                available
                    ? '지난 값 ${reading.valueText} ${reading.unit}'
                    : '지난 레코드에도 ${reading.valueText}',
                key: Key('metric_tile_${reading.kind.name}_past'),
                style: TextStyle(
                  fontSize: FontSizes.badge,
                  color: colors.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LiveValue extends StatelessWidget {
  final MetricReading reading;
  final bool over;
  const _LiveValue({required this.reading, required this.over});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // 숫자와 단위가 갈라지지 않게 줄바꿈 대신 줄인다.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            reading.valueText,
            key: Key('metric_tile_${reading.kind.name}_value'),
            style: AppTheme.gaugeNumberStyle(
              fontSize: FontSizes.displayCompact,
              color: over ? colors.danger : colors.textPrimary,
            ),
          ),
          const SizedBox(width: Spacing.xxs),
          Text(
            reading.unit,
            style: TextStyle(
              fontSize: FontSizes.caption,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
