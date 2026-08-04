import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telemetrix/core/api/api_client.dart';

import 'test_support.dart';

void main() {
  group('ApiClient', () {
    test('release 빌드는 로컬 또는 평문 API URL을 거부한다', () {
      expect(
        () => ApiClient.validateBaseUrl(
          'http://api.example.com',
          releaseMode: true,
        ),
        throwsStateError,
      );
      expect(
        () => ApiClient.validateBaseUrl(
          'http://localhost:8080',
          releaseMode: true,
        ),
        throwsStateError,
      );
      expect(
        () => ApiClient.validateBaseUrl(
          'https://api.example.com',
          releaseMode: true,
        ),
        returnsNormally,
      );
      expect(
        () => ApiClient.validateBaseUrl(
          'http://localhost:8080',
          releaseMode: false,
        ),
        returnsNormally,
      );
    });

    test('동시 401 요청은 refresh를 한 번만 실행하고 새 토큰으로 재시도한다', () async {
      final tokens = MemoryTokenStore(
        accessToken: 'expired-access',
        refreshToken: 'valid-refresh',
      );
      var refreshCalls = 0;
      final apiDio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
      apiDio.httpClientAdapter = CallbackHttpClientAdapter((options) {
        if (options.headers['Authorization'] == 'Bearer fresh-access') {
          return jsonResponse([], 200);
        }
        return jsonResponse({'message': 'expired'}, 401);
      });
      final refreshDio = Dio();
      refreshDio.httpClientAdapter = CallbackHttpClientAdapter((options) async {
        refreshCalls++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return jsonResponse({
          'accessToken': 'fresh-access',
          'refreshToken': 'rotated-refresh',
        }, 200);
      });
      final api = ApiClient.forTesting(
        dio: apiDio,
        tokenStore: tokens,
        refreshDioFactory: () => refreshDio,
      );

      await Future.wait([api.getVehicles(), api.getVehicles()]);

      expect(refreshCalls, 1);
      expect(tokens.accessToken, 'fresh-access');
      expect(tokens.refreshToken, 'rotated-refresh');
    });

    test('차량 생성/삭제와 진단 endpoint 계약을 지킨다', () async {
      final requests = <RequestOptions>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
      dio.httpClientAdapter = CallbackHttpClientAdapter((options) {
        requests.add(options);
        if (options.path.endsWith('/diagnosis')) {
          return jsonResponse({
            'diagnosis': '정상',
            'dataPoints': 20,
            'grade': 'A',
            'score': 95,
          }, 200);
        }
        if (options.method == 'POST') {
          return jsonResponse({'vehicleId': 'SIM-001'}, 201);
        }
        return jsonResponse(null, 204);
      });
      final api = ApiClient.forTesting(
        dio: dio,
        tokenStore: MemoryTokenStore(accessToken: 'token'),
      );

      await api.registerVehicle('SIM-001', '테스트 차량', 'tester');
      await api.deactivateVehicle('SIM-001');
      final diagnosis = await api.getDiagnosis('SIM-001');

      expect(requests.map((r) => r.method), ['POST', 'DELETE', 'GET']);
      expect(requests[0].path, '/api/vehicles');
      expect(requests[0].data, {
        'vehicleId': 'SIM-001',
        'name': '테스트 차량',
        'owner': 'tester',
      });
      expect(requests[1].path, '/api/vehicles/SIM-001');
      expect(diagnosis['grade'], 'A');
    });
  });
}
