import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telemetrix/core/theme/app_theme.dart';
import 'package:telemetrix/features/vehicle_list/widgets/empty_view.dart';

import 'golden/golden_support.dart';

/// 버튼 글자가 버튼 안에 다 들어가는지 — overflow 검사로는 안 잡힌다(글자가 넘치지 않고 버튼 끝에서 잘려 보였다).
/// 실제 글꼴(Manrope + 나눔고딕)을 실어야 폭이 기기와 같아진다.
void main() {
  setUpAll(loadTestFonts);

  for (final scale in const [1.0, 1.5]) {
    testWidgets('빈 목록의 버튼 글자가 버튼 안에 있다 — 글자 ${scale}x', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(),
        home: MediaQuery(
          data: MediaQueryData(
              size: const Size(360, 800), textScaler: TextScaler.linear(scale)),
          child: Scaffold(body: EmptyView(onRetry: () {})),
        ),
      ));
      for (final label in const ['차량 추가', '다시 시도']) {
        final button = find.ancestor(
            of: find.text(label),
            matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));
        final buttonRect = tester.getRect(button.first);
        final textRect = tester.getRect(find.text(label));
        expect(textRect.right, lessThanOrEqualTo(buttonRect.right - 8),
            reason: '$label 글자 오른쪽이 버튼 안쪽 여백을 침범한다');
        expect(textRect.left, greaterThanOrEqualTo(buttonRect.left + 8));
      }
    });
  }
}
