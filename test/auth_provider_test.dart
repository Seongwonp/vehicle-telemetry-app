import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telemetrix/core/api/api_client.dart';
import 'package:telemetrix/core/auth/auth_provider.dart';
import 'package:telemetrix/core/providers/vehicle_providers.dart';
import 'package:telemetrix/features/landing/landing_screen.dart';
import 'package:telemetrix/features/vehicle_list/vehicle_list_screen.dart';
import 'package:telemetrix/main.dart';

import 'test_support.dart';

class DelayedTokenStore extends MemoryTokenStore {
  final Completer<bool> result = Completer<bool>();

  @override
  Future<bool> hasToken() => result.future;
}

ApiClient createAuthApi() {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
  dio.httpClientAdapter = CallbackHttpClientAdapter((options) {
    if (options.path == '/api/auth/login') {
      return jsonResponse({
        'accessToken': 'new-access',
        'refreshToken': 'new-refresh',
      }, 200);
    }
    if (options.path == '/api/vehicles') return jsonResponse([], 200);
    return jsonResponse(null, 204);
  });
  return ApiClient.forTesting(
    dio: dio,
    tokenStore: MemoryTokenStore(),
  );
}

void main() {
  testWidgets('토큰 확인 전에는 랜딩 대신 초기화 화면을 표시한다', (tester) async {
    final tokens = DelayedTokenStore();
    final api = createAuthApi();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        tokenStoreProvider.overrideWithValue(tokens),
        apiClientProvider.overrideWithValue(api),
      ],
      child: const TelemetryApp(),
    ));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(LandingScreen), findsNothing);
    expect(find.byType(VehicleListScreen), findsNothing);

    tokens.result.complete(true);
    await tester.pumpAndSettle();
    expect(find.byType(VehicleListScreen), findsOneWidget);
  });

  test('로그인·로그아웃·refresh 실패 상태 전이가 명확하다', () async {
    final tokens = MemoryTokenStore();
    final api = createAuthApi();
    var expiredNavigationCount = 0;
    final notifier = AuthNotifier(
      apiClient: api,
      tokenStore: tokens,
      onSessionExpired: () => expiredNavigationCount++,
    );
    await Future<void>.delayed(Duration.zero);
    expect(notifier.state, AuthStatus.unauthenticated);

    await notifier.login('tester', 'password');
    expect(notifier.state, AuthStatus.authenticated);
    expect(tokens.accessToken, 'new-access');

    await notifier.logout();
    expect(notifier.state, AuthStatus.unauthenticated);
    expect(tokens.accessToken, isNull);

    tokens.accessToken = 'expired';
    tokens.refreshToken = 'invalid';
    await notifier.login('tester', 'password');
    api.onRefreshFailed?.call();
    await Future<void>.delayed(Duration.zero);
    expect(notifier.state, AuthStatus.unauthenticated);
    expect(tokens.accessToken, isNull);
    expect(expiredNavigationCount, 1);

    notifier.dispose();
    expect(api.onRefreshFailed, isNull);
  });
}
