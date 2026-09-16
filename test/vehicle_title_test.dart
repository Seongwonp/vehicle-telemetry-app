import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telemetrix/core/models/vehicle.dart';
import 'package:telemetrix/core/theme/app_theme.dart';
import 'package:telemetrix/features/vehicle_detail/vehicle_detail_screen.dart';

const _short = '포터 II 1호차';
const _long = '아이오닉 5 롱레인지 AWD 캘리그래피 2024 영업 3팀 공용';

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

  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(
      theme: AppTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 800),
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

bool _renderedNameClipped(WidgetTester tester) {
  final paragraph = tester.renderObject<RenderParagraph>(find.descendant(
    of: find.byKey(const Key('vehicle_title_name')),
    matching: find.byType(RichText),
  ));
  return paragraph.didExceedMaxLines;
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

  testWidgets('차량 정보 없이 들어오면 ID만 제목으로 쓴다', (tester) async {
    await _pump(tester, vehicle: null, width: 360, textScale: 1.0);
    expect(find.text('KR-GA-1234'), findsOneWidget);
    expect(button, findsNothing);
  });
}
