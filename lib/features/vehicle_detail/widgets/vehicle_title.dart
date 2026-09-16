import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';

/// 앱바 제목 — 차량 이름(최대 두 줄)과 차량 ID.
///
/// 긴 이름은 두 줄에서 자르되 **전체 이름을 볼 방법을 남긴다**: 잘렸을 때만 앱바에
/// '전체 이름' 버튼([VehicleFullNameButton])이 생기고 바텀시트로 연다.
/// 잘렸는지는 화면 폭·글자 배율로 미리 잰다([VehicleTitleLayout.measure]) — 앱바 높이도 이 값으로 정한다.
class VehicleTitle extends StatelessWidget {
  final String name;
  final String vehicleId;

  const VehicleTitle({required this.name, required this.vehicleId, super.key});

  static const nameStyle = TextStyle(
      fontSize: FontSizes.subtitle, fontWeight: FontWeight.w700, height: 1.3);
  static const idStyle = TextStyle(fontSize: FontSizes.caption, height: 1.3);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      header: true,
      label: '$name, $vehicleId',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            key: const Key('vehicle_title_name'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: nameStyle.copyWith(color: colors.textPrimary),
          ),
          Text(
            vehicleId,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: idStyle.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class VehicleTitleLayout {
  final bool clipped;
  final double toolbarHeight;

  const VehicleTitleLayout._(this.clipped, this.toolbarHeight);

  /// 앱바 제목 칸의 폭 = 화면 폭 − 뒤로 버튼(56) − 제목 양옆 여백(16×2) − 버튼 자리(48).
  /// [baseStyle]은 앱바 제목의 기본 글꼴 — 글꼴이 다르면 줄 수를 잘못 잰다.
  /// 버튼 자리는 잘리지 않은 경우에도 빼고 잰다 — 버튼이 생기면서 폭이 줄어 다시 잘리는 순환을 막는다.
  static VehicleTitleLayout measure({
    required String name,
    required double screenWidth,
    required TextScaler textScaler,
    TextStyle? baseStyle,
  }) {
    final base = baseStyle ?? const TextStyle();
    final width = (screenWidth - 56 - Spacing.md * 2 - TouchTarget.min)
        .clamp(48.0, 10000.0);
    final painter = TextPainter(
      text: TextSpan(text: name, style: base.merge(VehicleTitle.nameStyle)),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
      maxLines: 2,
    )..layout(maxWidth: width);
    final clipped = painter.didExceedMaxLines;
    final nameHeight = painter.height;
    painter.dispose();

    final idPainter = TextPainter(
      text: TextSpan(text: 'KR', style: base.merge(VehicleTitle.idStyle)),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();
    final idHeight = idPainter.height;
    idPainter.dispose();

    // 위아래 여백 xs씩 — 두 줄 이름이 앱바 가장자리에 붙지 않게.
    final height = nameHeight + idHeight + Spacing.xs * 2;
    return VehicleTitleLayout._(
        clipped, height < kToolbarHeight ? kToolbarHeight : height);
  }
}

class VehicleFullNameButton extends StatelessWidget {
  final String name;
  final String vehicleId;

  const VehicleFullNameButton(
      {required this.name, required this.vehicleId, super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('vehicle_full_name_button'),
      tooltip: '전체 이름',
      icon: const Icon(Icons.notes_outlined),
      constraints: const BoxConstraints(
          minWidth: TouchTarget.min, minHeight: TouchTarget.min),
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg)),
        ),
        builder: (context) {
          final colors = context.appColors;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  Spacing.lg, 0, Spacing.lg, Spacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('차량 이름',
                      style: TextStyle(
                          fontSize: FontSizes.caption,
                          color: colors.textSecondary)),
                  const SizedBox(height: Spacing.xxs),
                  SelectableText(
                    name,
                    key: const Key('vehicle_full_name_text'),
                    style: const TextStyle(
                        fontSize: FontSizes.title, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text('차량 ID',
                      style: TextStyle(
                          fontSize: FontSizes.caption,
                          color: colors.textSecondary)),
                  const SizedBox(height: Spacing.xxs),
                  SelectableText(vehicleId,
                      style: const TextStyle(fontSize: FontSizes.body)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
