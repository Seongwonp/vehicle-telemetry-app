import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../auth/token_storage.dart';

class ApiClient {
  // --dart-define=API_BASE_URL=... 로 주입. 없으면 로컬 개발값.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  /// release 빌드는 로컬이 아닌 HTTPS 주소가 없으면 시작하지 않는다 —
  /// 토큰이 평문 HTTP/WS로 나가는 빌드를 배포 전에 막는다.
  static void validateConfiguration() {
    validateBaseUrl(baseUrl, releaseMode: kReleaseMode);
  }

  @visibleForTesting
  static void validateBaseUrl(String value, {required bool releaseMode}) {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw StateError('API_BASE_URL must be an absolute URL: $value');
    }
    if (releaseMode &&
        (uri.scheme != 'https' ||
            uri.host == 'localhost' ||
            uri.host == '127.0.0.1')) {
      throw StateError(
        'Release builds require a non-local HTTPS API_BASE_URL. '
        'Pass --dart-define=API_BASE_URL=https://<host>.',
      );
    }
  }

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;
  late final TokenStore _tokenStore;
  late final Dio Function() _refreshDioFactory;

  // refresh가 거부되면 호출된다(AuthNotifier가 강제 로그아웃).
  void Function()? onRefreshFailed;

  ApiClient._internal() {
    _tokenStore = const SecureTokenStore();
    _refreshDioFactory = Dio.new;
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ));

    _installInterceptors();
  }

  @visibleForTesting
  ApiClient.forTesting({
    required Dio dio,
    required TokenStore tokenStore,
    Dio Function()? refreshDioFactory,
  }) {
    _dio = dio;
    _tokenStore = tokenStore;
    _refreshDioFactory = refreshDioFactory ?? Dio.new;
    _installInterceptors();
  }

  void _installInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokenStore.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // 발급·폐기 요청은 제외하되 인증이 필요한 /auth/me는 갱신 대상이다.
        if (error.response?.statusCode == 401 &&
            !const ['/api/auth/login', '/api/auth/refresh', '/api/auth/logout']
                .contains(error.requestOptions.path) &&
            error.requestOptions.extra['authRetried'] != true) {
          bool refreshed;
          try {
            refreshed = await _tryRefresh();
          } on DioException catch (refreshError) {
            handler.next(refreshError);
            return;
          } catch (_) {
            handler.next(error);
            return;
          }
          if (refreshed) {
            final token = await _tokenStore.getToken();
            final opts = error.requestOptions;
            opts.extra['authRetried'] = true;
            opts.headers['Authorization'] = 'Bearer $token';
            try {
              final retryResp = await _dio.fetch(opts);
              handler.resolve(retryResp);
              return;
            } on DioException catch (retryError) {
              handler.next(retryError);
              return;
            }
          } else {
            onRefreshFailed?.call();
          }
        }
        handler.next(error);
      },
    ));
  }

  // refresh는 동시에 한 번만 돈다. refresh token이 1회성이라 두 번째 요청이
  // 이미 회전된 토큰으로 실패해 정상 세션이 로그아웃되는 것을 막는다.
  Future<bool>? _refreshing;

  Future<bool> _tryRefresh() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  // 인터셉터 재진입을 막으려고 별도 Dio로 호출한다.
  Future<bool> _doRefresh() async {
    final refreshToken = await _tokenStore.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await _refreshDioFactory().post(
        '$baseUrl/api/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      await _tokenStore.save(
        response.data['accessToken'] as String,
        response.data['refreshToken'] as String,
      );
      return true;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        await _tokenStore.clear();
        return false;
      }
      // 토큰은 401/403에서만 지운다. 일시적 통신·저장소 장애는 만료가 아니다.
      rethrow;
    }
  }

  // ── 인증 ─────────────────────────────────────────────────────
  Future<Map<String, String>> login(String username, String password) async {
    final response = await _dio.post('/api/auth/login', data: {
      'username': username,
      'password': password,
    });
    return {
      'accessToken': response.data['accessToken'] as String,
      'refreshToken': response.data['refreshToken'] as String? ?? '',
    };
  }

  // 서버의 refresh token을 폐기한다(안 하면 재발급이 계속 가능하다).
  // 실패해도 로컬 로그아웃은 진행되도록 AuthNotifier가 예외를 삼킨다.
  Future<void> logout(String refreshToken) async {
    if (refreshToken.isEmpty) return;
    await _dio.post('/api/auth/logout', data: {'refreshToken': refreshToken});
  }

  // 성공(204) 시 서버가 refresh token을 전부 폐기하므로 호출부가 로컬 세션을 정리해야 한다.
  // 오류 code는 [errorCode]로 읽는다.
  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    await _dio.post('/api/auth/password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  /// 백엔드 ErrorResponse의 `code`. 본문이 없거나 형식이 다르면 null.
  static String? errorCode(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['code'] is String) return data['code'] as String;
    return null;
  }

  // ── 차량 관리 ─────────────────────────────────────────────────
  Future<bool> canRegisterVehicles() async {
    final response = await _dio.get('/api/auth/me');
    return (response.data['roles'] as List<dynamic>).contains('ROLE_ADMIN');
  }

  Future<List<dynamic>> getVehicles() async {
    final response = await _dio.get('/api/vehicles');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> registerVehicle(
      String vehicleId, String name, String owner) async {
    final response = await _dio.post('/api/vehicles', data: {
      'vehicleId': vehicleId,
      'name': name,
      'owner': owner,
    });
    return response.data as Map<String, dynamic>;
  }

  // 소프트 삭제(active=false). InfluxDB 이력과의 연결을 남긴다.
  Future<void> deactivateVehicle(String vehicleId) async {
    await _dio.delete('/api/vehicles/$vehicleId');
  }

  // ── 텔레메트리 ────────────────────────────────────────────────
  Future<List<dynamic>> getRecentTelemetry(String vehicleId,
      {int limit = 20}) async {
    final response = await _dio.get(
      '/api/vehicles/$vehicleId/telemetry',
      queryParameters: {'limit': limit},
    );
    return response.data as List<dynamic>;
  }

  // 최근 N시간(최대 6) 트립 요약. 구간 분할은 서버가 한다.
  Future<List<dynamic>> getTrips(String vehicleId, {int? hours}) async {
    final response = await _dio.get(
      '/api/vehicles/$vehicleId/telemetry/trips',
      queryParameters: hours != null ? {'hours': hours} : null,
    );
    return response.data as List<dynamic>;
  }

  // ── 이상 이벤트 ───────────────────────────────────────────────
  // 필터를 클라이언트에서 적용하므로 서버 최대치(100건)를 받는다.
  Future<List<dynamic>> getAnomalies(String vehicleId) async {
    final response = await _dio.get(
      '/api/vehicles/$vehicleId/anomalies',
      queryParameters: {'limit': 100},
    );
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getAnomalyPage(
    String vehicleId, {
    String? severity,
    DateTime? from,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _dio.get(
      '/api/vehicles/$vehicleId/anomalies/page',
      queryParameters: {
        if (severity != null) 'severity': severity,
        if (from != null) 'from': from.toUtc().toIso8601String(),
        'page': page,
        'size': size,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  // ── AI 진단 ───────────────────────────────────────────────────
  // 상세 진단은 오래 걸려 기본 15초 대신 백엔드 타임아웃(90초)보다 길게 둔다.
  Future<Map<String, dynamic>> getDiagnosis(String vehicleId) async {
    final response = await _dio.get(
      '/api/vehicles/$vehicleId/diagnosis',
      options: Options(receiveTimeout: const Duration(seconds: 100)),
    );
    return response.data as Map<String, dynamic>;
  }
}
