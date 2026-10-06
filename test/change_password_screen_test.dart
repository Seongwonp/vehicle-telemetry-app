import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telemetrix/core/api/api_client.dart';
import 'package:telemetrix/core/auth/auth_provider.dart';
import 'package:telemetrix/core/providers/vehicle_providers.dart';
import 'package:telemetrix/core/theme/app_theme.dart';
import 'package:telemetrix/features/landing/landing_screen.dart';
import 'package:telemetrix/features/settings/change_password_screen.dart';
import 'test_support.dart';

/// 화면 + 실제 ApiClient(가짜 HTTP 어댑터) + 실제 authProvider 로그아웃 경로.
class _Harness {
  final MemoryTokenStore tokens =
      MemoryTokenStore(accessToken: 'a', refreshToken: 'r', username: 'u');
  final List<RequestOptions> requests = [];
  late final ApiClient api;

  _Harness(FutureOr<ResponseBody> Function(RequestOptions) onPassword) {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dio.httpClientAdapter = CallbackHttpClientAdapter((options) {
      requests.add(options);
      if (options.path == '/api/auth/password') return onPassword(options);
      return ResponseBody.fromString('', 204); // /api/auth/logout
    });
    api = ApiClient.forTesting(dio: dio, tokenStore: tokens);
  }

  int get passwordCalls =>
      requests.where((r) => r.path == '/api/auth/password').length;

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(api),
        tokenStoreProvider.overrideWithValue(tokens),
      ],
      child: MaterialApp(
          theme: AppTheme.light(), home: const ChangePasswordScreen()),
    ));
  }
}

Future<void> _fill(WidgetTester tester,
    {String current = 'old-password',
    String next = 'new-password-1',
    String? confirm}) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), current);
  await tester.enterText(fields.at(1), next);
  await tester.enterText(fields.at(2), confirm ?? next);
}

Future<void> _submit(WidgetTester tester) async {
  await tester.tap(find.byType(FilledButton));
  // LandingScreen은 무한 반복 애니메이션이라 pumpAndSettle을 쓸 수 없다.
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  // 화면 전환(300ms)이 끝나야 이전 라우트가 트리에서 빠진다.
  await tester.pump(const Duration(seconds: 1));
}

/// 랜딩의 반복 애니메이션과 스낵바 타이머를 정리한다.
Future<void> _teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 6));
}

String _text(WidgetTester tester, int index) =>
    tester.widget<TextField>(find.byType(TextField).at(index)).controller!.text;

ResponseBody _error(int status, String code) =>
    jsonResponse({'code': code, 'message': 'x'}, status);

typedef _Case = ({
  String current,
  String next,
  String? confirm,
  String message
});

void main() {
  testWidgets('성공: 스낵바를 띄우고 로컬 토큰을 지운 뒤 처음 화면으로 돌아간다', (tester) async {
    final h = _Harness((_) => ResponseBody.fromString('', 204));
    await h.pump(tester);
    await _fill(tester);
    await _submit(tester);

    final body = h.requests.first.data as Map;
    expect(body, {
      'currentPassword': 'old-password',
      'newPassword': 'new-password-1',
    });
    expect(h.tokens.clearCount, 1);
    expect(h.tokens.accessToken, isNull);
    expect(find.byType(LandingScreen), findsOneWidget);
    expect(find.byType(ChangePasswordScreen), findsNothing);
    expect(find.text('비밀번호를 바꿨습니다. 다시 로그인해 주세요.'), findsOneWidget);
    await _teardown(tester);
  });

  testWidgets('현재 비밀번호 틀림: 현재 칸 아래 인라인 오류, 입력값 유지, 로그아웃 안 함', (tester) async {
    final h = _Harness((_) => _error(400, 'CURRENT_PASSWORD_INCORRECT'));
    await h.pump(tester);
    await _fill(tester);
    await _submit(tester);

    expect(find.text('현재 비밀번호가 맞지 않습니다'), findsOneWidget);
    expect(_text(tester, 0), 'old-password');
    expect(_text(tester, 1), 'new-password-1');
    expect(_text(tester, 2), 'new-password-1');
    expect(find.byType(ChangePasswordScreen), findsOneWidget);
    expect(h.tokens.clearCount, 0);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull);

    // 그 칸을 고치기 시작하면 오류가 사라진다.
    await tester.enterText(find.byType(TextField).at(0), 'old-password2');
    await tester.pump();
    expect(find.text('현재 비밀번호가 맞지 않습니다'), findsNothing);
  });

  group('클라이언트 검증은 요청을 보내지 않는다', () {
    final cases = <String, _Case>{
      '너무 짧음': (
        current: 'old-password',
        next: 'short',
        confirm: null,
        message: '새 비밀번호는 8~72자로 입력하세요'
      ),
      '73자': (
        current: 'old-password',
        next: 'a' * 73,
        confirm: null,
        message: '새 비밀번호는 8~72자로 입력하세요'
      ),
      '공백만 8자': (
        current: 'old-password',
        next: ' ' * 8,
        confirm: null,
        message: '새 비밀번호는 8~72자로 입력하세요'
      ),
      '확인 불일치': (
        current: 'old-password',
        next: 'new-password-1',
        confirm: 'new-password-2',
        message: '새 비밀번호가 일치하지 않습니다'
      ),
      '현재와 같음': (
        current: 'same-password',
        next: 'same-password',
        confirm: null,
        message: '현재 비밀번호와 다른 비밀번호를 입력하세요'
      ),
    };
    for (final entry in cases.entries) {
      testWidgets(entry.key, (tester) async {
        final h = _Harness((_) => ResponseBody.fromString('', 204));
        await h.pump(tester);
        await _fill(tester,
            current: entry.value.current,
            next: entry.value.next,
            confirm: entry.value.confirm);
        await _submit(tester);
        expect(find.text(entry.value.message), findsOneWidget);
        expect(h.requests, isEmpty);
        expect(h.tokens.clearCount, 0);
      });
    }
  });

  testWidgets('현재 비밀번호를 비우면 현재 칸에 오류, 요청 없음', (tester) async {
    final h = _Harness((_) => ResponseBody.fromString('', 204));
    await h.pump(tester);
    await _fill(tester, current: '');
    await _submit(tester);
    expect(find.text('현재 비밀번호를 입력하세요'), findsOneWidget);
    expect(h.requests, isEmpty);
  });

  testWidgets('503: 일시 장애 문구, 입력값 유지, 로그아웃 안 함, 다시 시도 가능', (tester) async {
    var calls = 0;
    final h = _Harness((_) {
      calls++;
      return calls == 1
          ? _error(503, 'REDIS_UNAVAILABLE')
          : ResponseBody.fromString('', 204);
    });
    await h.pump(tester);
    await _fill(tester);
    await _submit(tester);

    expect(find.textContaining('잠시 뒤 다시 시도해 주세요'), findsOneWidget);
    expect(find.textContaining('비밀번호는 바뀌지 않았습니다'), findsOneWidget);
    expect(_text(tester, 0), 'old-password');
    expect(_text(tester, 1), 'new-password-1');
    expect(_text(tester, 2), 'new-password-1');
    expect(h.tokens.clearCount, 0);
    expect(find.byType(ChangePasswordScreen), findsOneWidget);

    // 같은 값으로 다시 누르면 성공한다.
    await _submit(tester);
    expect(h.passwordCalls, 2);
    expect(find.byType(LandingScreen), findsOneWidget);
    await _teardown(tester);
  });

  testWidgets('서버 정책 위반·같은 비밀번호는 새 비밀번호 칸에 표시한다', (tester) async {
    final codes = ['VALIDATION_FAILED', 'BAD_REQUEST'];
    final h = _Harness((_) => _error(400, codes.removeAt(0)));
    await h.pump(tester);
    await _fill(tester);
    await _submit(tester);
    expect(find.text('새 비밀번호는 8~72자로 입력하세요'), findsOneWidget);
    await _submit(tester);
    expect(find.text('현재 비밀번호와 다른 비밀번호를 입력하세요'), findsOneWidget);
    expect(find.text('새 비밀번호는 8~72자로 입력하세요'), findsNothing);
    expect(_text(tester, 1), 'new-password-1');
    expect(h.tokens.clearCount, 0);
  });

  testWidgets('제출 중에는 버튼과 입력칸이 비활성이고 중복 요청이 없다', (tester) async {
    final gate = Completer<ResponseBody>();
    final h = _Harness((_) => gate.future);
    await h.pump(tester);
    await _fill(tester);
    await _submit(tester);

    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    expect(find.text('변경 중...'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField).first).enabled,
        isFalse);
    expect(h.passwordCalls, 1);

    gate.complete(_error(400, 'CURRENT_PASSWORD_INCORRECT'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull);
  });

  testWidgets('보기 토글은 해당 칸만 바꾼다', (tester) async {
    final h = _Harness((_) => ResponseBody.fromString('', 204));
    await h.pump(tester);
    bool obscured(int i) =>
        tester.widget<TextField>(find.byType(TextField).at(i)).obscureText;
    expect([obscured(0), obscured(1), obscured(2)], [true, true, true]);
    await tester.tap(find.byTooltip('새 비밀번호 보기'));
    await tester.pump();
    expect([obscured(0), obscured(1), obscured(2)], [true, false, true]);
  });

  testWidgets("키보드 '다음'은 칸 안의 보기 버튼이 아니라 다음 입력칸으로 간다", (tester) async {
    final h = _Harness((_) => ResponseBody.fromString('', 204));
    await h.pump(tester);
    final fields = find.byType(TextField);
    bool focused(int i) =>
        tester.widget<TextField>(fields.at(i)).focusNode?.hasFocus ??
        tester.binding.focusManager.primaryFocus?.context
                ?.findAncestorWidgetOfExactType<TextField>() ==
            tester.widget<TextField>(fields.at(i));
    await tester.tap(fields.at(0));
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(focused(1), isTrue);
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(focused(2), isTrue);
    expect(h.passwordCalls, 0);
  });
}
