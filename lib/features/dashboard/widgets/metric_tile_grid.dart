import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../dashboard_view_state.dart';
import 'metric_tile.dart';

/// 계측 타일을 화면 폭이 아니라 받은 폭에 맞춰 줄 세운다(2단 안에서는 칸이 좁다).
/// 3열은 2열로 내린다(한 개만 남는 줄을 만들지 않는다).
class MetricTileGrid extends StatelessWidget {
  final DashboardViewState state;

  /// 폭이 충분할 때의 열 수(2 또는 4).
  final int maxColumns;

  const MetricTileGrid({
    required this.state,
    this.maxColumns = 2,
    super.key,
  });

  /// 글자 1.0배에서 타일 한 칸의 최소 폭. 글자 배율만큼 늘린다.
  /// 360px·1.5배에서 2열, 320px·1.5배에서 1열이 되는 값이다(golden 스냅샷이 고정).
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
