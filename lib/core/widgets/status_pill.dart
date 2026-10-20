import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// 상태·심각도·코드를 한 줄 알약으로 보여주는 공통 위젯.
///
/// 구조는 여기 한 곳에 두고, 호출부마다 다른 값은 인자로 드러낸다
/// (값 통일은 스냅샷이 바뀌는 별도 결정 — `docs/design-system.md`).
class StatusPill extends StatelessWidget {
  /// 알약 안의 글자.
  final String label;

  /// 글자·아이콘·배경·테두리의 기준 색. `context.appColors`에서 가져와야 다크에서 바뀐다.
  final Color color;

  final IconData? icon;
  final StatusPillVariant variant;
  final StatusPillDensity density;
  final FontWeight fontWeight;

  /// null이면 텍스트 테마 값을 따른다. 0을 기본값으로 두면 테마의 자간을 덮어쓴다.
  final double? letterSpacing;

  /// [StatusPillVariant.filled]의 배경 불투명도.
  final double fillOpacity;

  /// 넘기면 알약 전체를 [Semantics]로 감싼다(자식 의미는 유지).
  final String? semanticsLabel;

  const StatusPill({
    required this.label,
    required this.color,
    this.icon,
    this.variant = StatusPillVariant.filled,
    this.density = StatusPillDensity.compact,
    this.fontWeight = FontWeight.w700,
    this.letterSpacing,
    this.fillOpacity = 0.12,
    this.semanticsLabel,
    super.key,
  });

  /// 아이콘 크기는 의미가 있는 치수라 간격 스케일 대상이 아니다
  /// (`docs/design-system.md` "왜 만들었나").
  static const double _iconSize = 12;

  /// 테두리 변형의 불투명도. 채움보다 진해야 같은 무게로 보인다.
  static const double _outlineOpacity = 0.45;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: TextStyle(
        fontSize: FontSizes.badge,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        color: color,
      ),
    );

    final pill = Container(
      padding: EdgeInsets.symmetric(
        horizontal: Spacing.xs,
        vertical: density.verticalPadding,
      ),
      decoration: BoxDecoration(
        color: variant == StatusPillVariant.filled
            ? color.withValues(alpha: fillOpacity)
            : null,
        borderRadius: Radii.pillAll,
        border: variant == StatusPillVariant.outlined
            ? Border.all(color: color.withValues(alpha: _outlineOpacity))
            : null,
      ),
      child: icon == null
          ? text
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: _iconSize, color: color),
                const SizedBox(width: Spacing.xxs),
                text,
              ],
            ),
    );

    if (semanticsLabel == null) return pill;
    return Semantics(label: semanticsLabel, child: pill);
  }
}

enum StatusPillVariant {
  /// 색을 옅게 깔아 상태 자체가 정보인 곳.
  filled,

  /// 테두리만. DTC 코드처럼 보조 정보를 화면에서 가장 무거운 요소로
  /// 만들지 않기 위한 변형이다(`docs/design-system.md` 원칙 2).
  outlined,
}

enum StatusPillDensity {
  /// 세로 패딩 [Spacing.xxs]. 단독으로 놓이는 상태 알약.
  regular,

  /// 세로 패딩 2. [Wrap] 안에 줄지어 놓이는 배지.
  ///
  /// 4pt 그리드 밖이지만 [Spacing.xxs]로 올리면 배지 높이와 스냅샷이 바뀐다.
  compact,
}

extension on StatusPillDensity {
  double get verticalPadding => switch (this) {
        StatusPillDensity.regular => Spacing.xxs,
        StatusPillDensity.compact => 2,
      };
}
