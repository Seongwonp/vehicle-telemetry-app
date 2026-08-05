import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telemetrix/core/api/api_client.dart';
import 'package:telemetrix/core/providers/vehicle_providers.dart';
import 'package:telemetrix/features/trips/trip_history_tab.dart';

import 'test_support.dart';

Map<String, dynamic> tripJson(double distance) => {
      'startTime': '2026-08-05T01:00:00Z',
      'endTime': '2026-08-05T01:30:00Z',
      'durationMinutes': 30,
      'distanceKm': distance,
      'avgSpeedKmh': 20,
      'maxSpeedKmh': 40,
      'pointCount': 10,
    };

void main() {
  testWidgets('기간 전환 중 기존 목록을 유지하고 늦은 이전 응답을 무시한다', (tester) async {
    final responses = <int, Completer<ResponseBody>>{
      1: Completer<ResponseBody>(),
      3: Completer<ResponseBody>(),
      6: Completer<ResponseBody>(),
    };
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dio.httpClientAdapter = CallbackHttpClientAdapter((options) {
      final hours = options.queryParameters['hours'] as int;
      return responses[hours]!.future;
    });
    final api = ApiClient.forTesting(
      dio: dio,
      tokenStore: MemoryTokenStore(accessToken: 'token'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(api)],
        child: const MaterialApp(
          home: Scaffold(body: TripHistoryTab(vehicleId: 'SIM-001')),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    responses[1]!.complete(jsonResponse([tripJson(1)], 200));
    await tester.pumpAndSettle();
    expect(find.text('1.0km'), findsOneWidget);

    await tester.tap(find.text('3시간'));
    await tester.pump();
    expect(find.text('1.0km'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    await tester.tap(find.text('6시간'));
    await tester.pump();
    responses[6]!.complete(jsonResponse([tripJson(6)], 200));
    await tester.pumpAndSettle();
    expect(find.text('6.0km'), findsOneWidget);

    responses[3]!.complete(jsonResponse([tripJson(3)], 200));
    await tester.pumpAndSettle();
    expect(find.text('6.0km'), findsOneWidget);
    expect(find.text('3.0km'), findsNothing);
  });

  testWidgets('빈 상태에서도 pull-to-refresh 가능한 스크롤 구조를 사용한다', (tester) async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dio.httpClientAdapter =
        CallbackHttpClientAdapter((_) => jsonResponse([], 200));
    final api = ApiClient.forTesting(
      dio: dio,
      tokenStore: MemoryTokenStore(accessToken: 'token'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(api)],
        child: const MaterialApp(
          home: Scaffold(body: TripHistoryTab(vehicleId: 'SIM-001')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('이 기간엔 주행 기록이 없어요'), findsOneWidget);
    final list = tester.widget<ListView>(find.byType(ListView));
    expect(list.physics, isA<AlwaysScrollableScrollPhysics>());
  });

  test('트립 오류 메시지를 상태별로 구분한다', () {
    DioException responseError(int status) {
      final request = RequestOptions(path: '/trips');
      return DioException.badResponse(
        statusCode: status,
        requestOptions: request,
        response: Response(requestOptions: request, statusCode: status),
      );
    }

    expect(tripErrorMessage(responseError(401)), contains('다시 로그인'));
    expect(tripErrorMessage(responseError(429)), contains('요청이 너무 많습니다'));
    expect(tripErrorMessage(responseError(503)), contains('서버에 일시적인 문제'));
  });
}
