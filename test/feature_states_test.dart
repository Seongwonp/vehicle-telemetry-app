import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemetrix/core/api/api_client.dart';
import 'package:telemetrix/features/diagnosis/diagnosis_screen.dart';
import 'package:telemetrix/features/login/login_screen.dart';
import 'package:telemetrix/features/settings/settings_screen.dart';

import 'test_support.dart';

DioException responseError(int statusCode) {
  final request = RequestOptions(path: '/test');
  return DioException.badResponse(
    statusCode: statusCode,
    requestOptions: request,
    response: Response(requestOptions: request, statusCode: statusCode),
  );
}

void main() {
  test('로그인 오류를 상태 코드별로 구분한다', () {
    expect(loginErrorMessage(responseError(401)), contains('아이디 또는 비밀번호'));
    expect(loginErrorMessage(responseError(429)), contains('시도가 너무 많습니다'));
    expect(loginErrorMessage(responseError(500)), contains('서버에 일시적인 문제'));
    expect(loginErrorMessage(responseError(400)), contains('입력 내용을 확인'));
  });

  test('AI 진단 오류를 상태 코드별로 구분한다', () {
    expect(diagnosisErrorMessage(responseError(401)), contains('다시 로그인'));
    expect(diagnosisErrorMessage(responseError(422)), contains('데이터가 부족'));
    expect(diagnosisErrorMessage(responseError(429)), contains('요청이 많습니다'));
    expect(diagnosisErrorMessage(responseError(503)), contains('일시적인 문제'));
  });

  testWidgets('재진단 실패와 탭 전환 후에도 마지막 정상 결과를 유지한다', (tester) async {
    var diagnosisCalls = 0;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dio.httpClientAdapter = CallbackHttpClientAdapter((options) {
      diagnosisCalls++;
      if (diagnosisCalls == 1) {
        return jsonResponse({
          'diagnosis': '엔진 상태가 정상입니다.',
          'dataPoints': 20,
          'grade': 'A',
          'score': 95,
        }, 200);
      }
      return jsonResponse({'message': 'busy'}, 429);
    });
    final api = ApiClient.forTesting(
      dio: dio,
      tokenStore: MemoryTokenStore(accessToken: 'token'),
    );

    await tester.pumpWidget(MaterialApp(
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            bottom: const TabBar(
              tabs: [Tab(text: '진단'), Tab(text: '다른 탭')],
            ),
          ),
          body: TabBarView(children: [
            DiagnosisTab(vehicleId: 'SIM-001', apiClient: api),
            const Center(child: Text('다른 화면')),
          ]),
        ),
      ),
    ));

    await tester.tap(find.text('고장진단하기'));
    await tester.pumpAndSettle();
    expect(find.textContaining('엔진 상태가 정상입니다.'), findsOneWidget);

    await tester.tap(find.text('다시 진단하기'));
    await tester.pumpAndSettle();
    expect(find.textContaining('AI 진단 요청이 많습니다'), findsOneWidget);
    expect(find.textContaining('엔진 상태가 정상입니다.'), findsOneWidget);

    await tester.tap(find.text('다른 탭'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('진단'));
    await tester.pumpAndSettle();
    expect(find.textContaining('엔진 상태가 정상입니다.'), findsOneWidget);
  });

  testWidgets('설정은 저장된 계정과 로그아웃만 표시한다', (tester) async {
    FlutterSecureStorage.setMockInitialValues({'username': 'tester'});
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SettingsScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('tester'), findsOneWidget);
    expect(find.text('로그아웃'), findsOneWidget);
    expect(find.text('시스템'), findsOneWidget);
    expect(find.text('라이트'), findsOneWidget);
    expect(find.text('다크'), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
  });
}
