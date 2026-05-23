import 'package:dio/dio.dart';
import '../auth/token_storage.dart';

class ApiClient {
  // --dart-define=API_BASE_URL=http://<EC2-IP>:8080 으로 빌드 시 주입
  // 미설정 시 로컬 개발 기본값 사용
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;

  // refresh 만료/실패 시 AuthNotifier가 콜백 등록 → 강제 로그아웃
  void Function()? onRefreshFailed;

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await TokenStorage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // /auth/ 경로는 refresh 시도 제외 (무한 루프 방지)
        if (error.response?.statusCode == 401 &&
            !error.requestOptions.path.contains('/auth/')) {
          final refreshed = await _tryRefresh();
          if (refreshed) {
            // 새 access token으로 원래 요청 재시도
            final token = await TokenStorage.getToken();
            final opts  = error.requestOptions;
            opts.headers['Authorization'] = 'Bearer $token';
            try {
              final retryResp = await _dio.fetch(opts);
              handler.resolve(retryResp);
              return;
            } catch (_) {
              // retry도 실패 — 아래 handler.next로 낙하
            }
          } else {
            onRefreshFailed?.call();
          }
        }
        handler.next(error);
      },
    ));
  }

  // 별도 Dio 인스턴스로 refresh 호출 — 인터셉터 재진입 방지
  Future<bool> _tryRefresh() async {
    final refreshToken = await TokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await Dio().post(
        '$baseUrl/api/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      await TokenStorage.save(
        response.data['accessToken'] as String,
        response.data['refreshToken'] as String,
      );
      return true;
    } catch (_) {
      await TokenStorage.clear();
      return false;
    }
  }

  // ── 인증 ─────────────────────────────────────────────────────
  Future<Map<String, String>> login(String username, String password) async {
    final response = await _dio.post('/api/auth/login', data: {
      'username': username,
      'password': password,
    });
    return {
      'accessToken':  response.data['accessToken']  as String,
      'refreshToken': response.data['refreshToken'] as String? ?? '',
    };
  }

  // ── 차량 관리 ─────────────────────────────────────────────────
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

  // ── 텔레메트리 ────────────────────────────────────────────────
  Future<List<dynamic>> getRecentTelemetry(String vehicleId,
      {int limit = 20}) async {
    final response = await _dio.get(
      '/api/vehicles/$vehicleId/telemetry',
      queryParameters: {'limit': limit},
    );
    return response.data as List<dynamic>;
  }

  // ── 이상 이벤트 ───────────────────────────────────────────────
  Future<List<dynamic>> getAnomalies(String vehicleId) async {
    final response = await _dio.get('/api/vehicles/$vehicleId/anomalies');
    return response.data as List<dynamic>;
  }

  // ── AI 진단 ───────────────────────────────────────────────────
  Future<Map<String, dynamic>> getDiagnosis(String vehicleId) async {
    final response = await _dio.get('/api/vehicles/$vehicleId/diagnosis');
    return response.data as Map<String, dynamic>;
  }
}
