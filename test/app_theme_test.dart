import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telemetrix/core/theme/app_theme.dart';

void main() {
  testWidgets('화면 색상은 ThemeExtension에서 조회한다', (tester) async {
    AppSemanticColors? colors;

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Builder(builder: (context) {
        colors = context.appColors;
        return const SizedBox();
      }),
    ));

    expect(colors, isNotNull);
    expect(colors!.background, AppTheme.bg);
    expect(colors!.surface, AppTheme.surface);
    expect(colors!.border, AppTheme.border);
    expect(colors!.textPrimary, AppTheme.textPrimary);
    expect(colors!.danger, AppTheme.danger);
  });

  testWidgets('라이트와 다크는 서로 다른 표면과 텍스트 토큰을 제공한다',
      (tester) async {
    AppSemanticColors? lightColors;
    AppSemanticColors? darkColors;

    // 같은 구조의 트리를 연달아 pump하면 엘리먼트가 재사용돼 두 번째 Builder가
    // 갱신된 테마를 못 읽는다(darkColors에 light 값이 들어와 테스트가 실패했다).
    // 테마마다 다른 key를 줘서 엘리먼트를 새로 만들게 한다.
    await tester.pumpWidget(MaterialApp(
      key: const ValueKey('light'),
      theme: AppTheme.light(),
      home: Builder(builder: (context) {
        lightColors = context.appColors;
        return const SizedBox();
      }),
    ));
    await tester.pumpWidget(MaterialApp(
      key: const ValueKey('dark'),
      theme: AppTheme.dark(),
      home: Builder(builder: (context) {
        darkColors = context.appColors;
        return const SizedBox();
      }),
    ));

    expect(lightColors!.background, isNot(darkColors!.background));
    expect(lightColors!.surface, isNot(darkColors!.surface));
    expect(lightColors!.textPrimary, isNot(darkColors!.textPrimary));
    expect(AppTheme.dark().brightness, Brightness.dark);
  });
}
