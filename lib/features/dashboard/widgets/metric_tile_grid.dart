import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../dashboard_view_state.dart';
import 'metric_tile.dart';

/// 계측 타일을 **받은 폭**에 맞춰 줄 세운다.
///
/// 화면 폭 분기(`isDesktop`)가 아니라 이 위젯이 실제로 받은 폭으로 열 수를 정한다 —
/// 2단 레이아웃 안처럼 화면은 넓어도 칸은 좁은 경우가 있다.
/// 열 수가 3이면 2로 내린다(4개 중 1개가 혼자 남는 줄을 만들지 않는다).
class MetricTileGrid extends StatelessWidget {
  final DashboardViewState state;

  /// 폭이 충분할 때의 열 수(2 또는 4).
  final int maxColumns;

  const MetricTileGrid({
    required this.state,
    this.maxColumns = 2,
    super.key,
  });

  /// 글자 1.0배에서 타일 한 칸의 최소 폭. 글자 배율(최대 1.5)만큼 늘린다.
  ///
  /// 104 × 1.5 = 156 — 360px·1.5배(내용 폭 328)에서 2열, 320px·1.5배(296)에서 1열이 되는 값이다.
  /// 이보다 좁으면 기준 문구가 세 줄로 접히고 값이 FittedBox에 과하게 눌린다
  /// (`test/golden/snapshots/detail/`로 확인).
  static const double minTileWidth = 104;

  static int columnsFor(double width, double textScale, int maxColumns) {
    final minTile = minTileWidth * textScale.clamp(1.0, 1.5);
    final fit = ((width + Spacing.sm) / (minTile + Spacing.sm)).floor();
    final columns = fit.clamp(1, maxColumns);
    return columns == 3 ? 2 : columns;
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(builder: (context, constraints) {
      final columns = columnsFor(constraints.maxWidth, textScale, maxColumns);
      final tiles = [
        for (final r in state.readings) MetricTile(reading: r, state: state),
      ];
      final rows = <Widget>[];
      for (var i = 0; i < tiles.length; i += columns) {
        final chunk = tiles.sublist(i, (i + columns).clamp(0, tiles.length));
        rows.add(IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = 0; j < chunk.length; j++) ...[
                if (j > 0) const SizedBox(width: Spacing.sm),
                Expanded(child: chunk[j]),
              ],
            ],
          ),
        ));
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: Spacing.sm),
            rows[i],
          ],
        ],
      );
    });
  }
}
