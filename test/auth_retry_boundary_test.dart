import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telemetrix/core/api/api_client.dart';
import 'test_support.dart';

void main() {
  for (final refreshStatus in [200, 401, 503]) {
    test(
        'persistent 401, refresh $refreshStatus terminates and preserves transient sessions',
        () async {
      final tokens =
          MemoryTokenStore(accessToken: 'old', refreshToken: 'refresh');
      var apiCalls = 0;
      var refreshCalls = 0;
      var expiredCalls = 0;
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
      dio.httpClientAdapter = CallbackHttpClientAdapter((_) {
        apiCalls++;
        return jsonResponse({'code': 'UNAUTHORIZED'}, 401);
      });
      final refreshDio = Dio();
      refreshDio.httpClientAdapter = CallbackHttpClientAdapter((_) {
        refreshCalls++;
        return jsonResponse(
            {'accessToken': 'new', 'refreshToken': 'new-refresh'},
            refreshStatus);
      });
      final api = ApiClient.forTesting(
          dio: dio, tokenStore: tokens, refreshDioFactory: () => refreshDio);
      api.onRefreshFailed = () => expiredCalls++;

      await expectLater(
          api.getVehicles().timeout(const Duration(seconds: 2)),
          throwsA(isA<DioException>().having((e) => e.response?.statusCode,
              'status', refreshStatus == 503 ? 503 : 401)));
      expect(refreshCalls, 1);
      expect(apiCalls, refreshStatus == 200 ? 2 : 1);
      expect(expiredCalls, refreshStatus == 401 ? 1 : 0);
      expect(tokens.clearCount, refreshStatus == 401 ? 1 : 0);
      if (refreshStatus == 503) expect(tokens.refreshToken, 'refresh');
    });
  }

  test('identity lookup refreshes expired access token and uses server role',
      () async {
    final tokens =
        MemoryTokenStore(accessToken: 'old', refreshToken: 'refresh');
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dio.httpClientAdapter = CallbackHttpClientAdapter((options) {
      expect(options.path, '/api/auth/me');
      return options.headers['Authorization'] == 'Bearer new'
          ? jsonResponse({
              'username': 'admin',
              'roles': ['ROLE_ADMIN']
            }, 200)
          : jsonResponse({}, 401);
    });
    final refreshDio = Dio();
    refreshDio.httpClientAdapter = CallbackHttpClientAdapter((_) =>
        jsonResponse(
            {'accessToken': 'new', 'refreshToken': 'new-refresh'}, 200));
    final api = ApiClient.forTesting(
        dio: dio, tokenStore: tokens, refreshDioFactory: () => refreshDio);
    expect(await api.canRegisterVehicles(), isTrue);
  });
}
