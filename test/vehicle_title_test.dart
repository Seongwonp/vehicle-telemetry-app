import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telemetrix/core/models/vehicle.dart';
import 'package:telemetrix/core/theme/app_theme.dart';
import 'package:telemetrix/features/vehicle_detail/vehicle_detail_screen.dart';

const _short = '포터 II 1호차';
const _long = '아이오닉 5 롱레인지 AWD 캘리그래피 2024 영업 3팀 공용';

/// 가로 모드 케이스용. 폭 800에서 제목 칸은 664px(= 800 − 56 − 16×2 − 48)이라
/// [_long]은 한 줄에 들어가버려 "한 줄로 줄였는데도 잘린다"를 못 본다.
const _longer = '$_long · 정비 이력 다수 · 임시 번호판 · 2팀 인수 예정';

Vehicle _vehicle(String name) => Vehicle(
      vehicleId: 'KR-GA-1234',
      name: name,
      owner: 'tester',
      active: true,
      highAnomalyCount: 0,
      registeredAt: DateTime(2026, 1, 2),
    );

Future<List<String>> _pump(
  WidgetTester tester, {
  required Vehicle? vehicle,
  required double width,
  required double textScale,
  double height = 800,
}) async {
  final overflows = <String>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    final message = details.exceptionAsString();
    if (message.contains('overflowed')) {
      overflows.add(message.split('\n').first);
    } else {
      previous?.call(details);
    }
  };
  addTearDown(() => FlutterError.onError = previous);

  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(
      theme: AppTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, height),
          textScaler: TextScaler.linear(textScale),
        ),
        child: VehicleDetailScreen(
          vehicleId: 'KR-GA-1234',
          vehicle: vehicle,
          dashboardOverride: const SizedBox.shrink(),
        ),
      ),
    ),
  ));
  await tester.pump();
  return overflows;
}

RenderParagraph _nameParagraph(WidgetTester tester) =>
    tester.renderObject<RenderParagraph>(find.descendant(
      of: find.byKey(const Key('vehicle_title_name')),
      matching: find.byType(RichText),
    ));

bool _renderedNameClipped(WidgetTester tester) =>
    _nameParagraph(tester).didExceedMaxLines;

/// 실제로 그려진 줄 수. `maxLines` 인자를 읽는 것과 달리 렌더 결과를 본다 —
/// 글자 상자의 서로 다른 윗변 개수가 곧 줄 수다.
int _renderedNameLines(WidgetTester tester) {
  final paragraph = _nameParagraph(tester);
  final boxes = paragraph.getBoxesForSelection(TextSelection(
    baseOffset: 0,
    extentOffset: paragraph.text.toPlainText().length,
  ));
  return boxes.map((box) => box.top).toSet().length;
}

void main() {
  final button = find.byKey(const Key('vehicle_full_name_button'));

  for (final width in const [320.0, 360.0, 400.0]) {
    for (final scale in const [1.0, 1.5]) {
      for (final name in const [_short, _long]) {
        final label = name == _short ? '짧은 이름' : '긴 이름';
        testWidgets('${width.toInt()}px · 글자 ${scale}x · $label',
            (tester) async {
          final overflows = await _pump(tester,
              vehicle: _vehicle(name), width: width, textScale: scale);

          expect(overflows, isEmpty);
          expect(find.text(name), findsOneWidget);

          // 핵심 불변식: 화면에서 이름이 잘렸다면 전체 이름을 여는 버튼이 반드시 있다.
          if (_renderedNameClipped(tester)) {
            expect(button, findsOneWidget, reason: '잘린 이름을 볼 방법이 없다');
          }
          if (name == _short) {
            expect(button, findsNothing, reason: '짧은 이름에 불필요한 버튼');
          }

          // 제목이 탭 줄을 덮지 않는다.
          final titleBottom = tester.getBottomLeft(find.text('KR-GA-1234')).dy;
          final tabsTop = tester.getTopLeft(find.byType(TabBar)).dy;
          expect(titleBottom, lessThanOrEqualTo(tabsTop));

          if (button.evaluate().isNotEmpty) {
            await tester.tap(button);
            await tester.pumpAndSettle();
            expect(find.byKey(const Key('vehicle_full_name_text')),
                findsOneWidget);
            final sheet = tester.widget<SelectableText>(
                find.byKey(const Key('vehicle_full_name_text')));
            expect(sheet.data, name);
          }
        });
      }
    }
  }

  testWidgets('320px·1.5배 긴 이름은 반드시 잘리고 버튼이 생긴다', (tester) async {
    await _pump(tester, vehicle: _vehicle(_long), width: 320, textScale: 1.5);
    expect(_renderedNameClipped(tester), isTrue);
    expect(button, findsOneWidget);
  });

  // 가로 모드 폰(높이 < 480, plans/2026-09-16-vehicle-detail-c.md §5-4).
  // 세로로 쓸 공간이 없으므로 이름을 두 줄이 아니라 한 줄로 줄인다. 폭(800)은 태블릿급이라
  // **폭만 보면 가로 모드를 구분할 수 없다** — 높이로 가른다.
  testWidgets('가로 400 × 폭 800 긴 이름 — 제목은 한 줄, 잘리면 버튼', (tester) async {
    final overflows = await _pump(tester,
        vehicle: _vehicle(_longer), width: 800, height: 400, textScale: 1.0);

    expect(overflows, isEmpty);
    expect(_renderedNameLines(tester), 1, reason: '가로 모드에서 제목이 두 줄이 됐다');
    expect(_renderedNameClipped(tester), isTrue,
        reason: '전제: 이 이름은 한 줄에 안 들어간다');
    expect(button, findsOneWidget, reason: '잘린 이름을 볼 방법이 없다');

    // 앱바(제목 + ID)가 TabBar 줄을 덮지 않는다.
    final titleBottom = tester.getBottomLeft(find.text('KR-GA-1234')).dy;
    final tabsTop = tester.getTopLeft(find.byType(TabBar)).dy;
    expect(titleBottom, lessThanOrEqualTo(tabsTop));

    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<SelectableText>(
                find.byKey(const Key('vehicle_full_name_text')))
            .data,
        _longer);
  });

  // 같은 폭·같은 이름을 세로 높이로만 바꾼 대조군. 줄 수가 높이에서 나온다는 근거다.
  testWidgets('같은 폭 800이 세로(높이 800)면 제목은 두 줄로 돌아온다', (tester) async {
    final overflows = await _pump(tester,
        vehicle: _vehicle(_longer), width: 800, height: 800, textScale: 1.0);

    expect(overflows, isEmpty);
    expect(_renderedNameLines(tester), 2);
  });

  testWidgets('차량 정보 없이 들어오면 ID만 제목으로 쓴다', (tester) async {
    await _pump(tester, vehicle: null, width: 360, textScale: 1.0);
    expect(find.text('KR-GA-1234'), findsOneWidget);
    expect(button, findsNothing);
  });
}
