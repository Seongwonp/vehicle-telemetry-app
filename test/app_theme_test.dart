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

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Builder(builder: (context) {
        lightColors = context.appColors;
        return const SizedBox();
      }),
    ));
    await tester.pumpWidget(MaterialApp(
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
