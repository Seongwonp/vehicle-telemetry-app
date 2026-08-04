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
            final opts = error.requestOptions;
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

  // 동시에 여러 요청이 401을 맞아도 refresh는 한 번만 실행되게 진행 중인 Future를
  // 공유한다(single-flight). 이 락이 없으면 백엔드가 refresh token을 1회성으로
  // 회전(rotate)시킬 때, 동시에 도착한 두 번째 refresh 요청이 이미 무효화된
  // 토큰으로 실패해 정상 세션인데도 강제 로그아웃되는 레이스 컨디션이 생긴다.
  Future<bool>? _refreshing;

  Future<bool> _tryRefresh() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  // 별도 Dio 인스턴스로 refresh 호출 — 인터셉터 재진입 방지
  Future<bool> _doRefresh() async {
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
      'accessToken': response.data['accessToken'] as String,
      'refreshToken': response.data['refreshToken'] as String? ?? '',
    };
  }

  // 서버 측 refresh token을 폐기한다 — 이걸 안 부르면 로그아웃해도 Redis에 토큰이
  // 남아있어서 재발급 사슬이 끊기지 않는다. 실패해도 로컬 로그아웃은 계속 진행되도록
  // 호출부(AuthNotifier)에서 예외를 삼킨다.
  Future<void> logout(String refreshToken) async {
    if (refreshToken.isEmpty) return;
    await _dio.post('/api/auth/logout', data: {'refreshToken': refreshToken});
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

  // 물리 삭제가 아니라 active=false로 내리는 소프트 삭제(백엔드
  // VehicleService.deactivate와 동일한 정책) — InfluxDB 이력과의 연결을 보존한다.
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

  // ── 이상 이벤트 ───────────────────────────────────────────────
  // 화면에서 기간/등급 필터를 클라이언트 사이드로 적용하므로 기본 20건보다
  // 넉넉한 풀(서버 최대치인 100건)을 받아온다.
  Future<List<dynamic>> getAnomalies(String vehicleId) async {
    final response = await _dio.get(
      '/api/vehicles/$vehicleId/anomalies',
      queryParameters: {'limit': 100},
    );
    return response.data as List<dynamic>;
  }

  // ── AI 진단 ───────────────────────────────────────────────────
  // 상세 리포트 요청 시 Gemini 응답이 40~80초대까지 걸릴 수 있어 기본
  // receiveTimeout(15초)보다 넉넉하게 개별 지정한다 (백엔드 타임아웃 90초 + 여유).
  Future<Map<String, dynamic>> getDiagnosis(String vehicleId) async {
    final response = await _dio.get(
      '/api/vehicles/$vehicleId/diagnosis',
      options: Options(receiveTimeout: const Duration(seconds: 100)),
    );
    return response.data as Map<String, dynamic>;
  }
}
