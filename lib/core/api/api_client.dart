import 'package:dio/dio.dart';
import '../auth/token_storage.dart';

class ApiClient {
  // 로컬 개발: http://localhost:8080
  // AWS 배포 후: http://<EC2-IP>:8080 으로 변경
  static const String baseUrl = 'http://localhost:8080';

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;

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
        if (error.response?.statusCode == 401) {
          await TokenStorage.clear();
        }
        handler.next(error);
      },
    ));
  }

  // ── 인증 ─────────────────────────────────────────────────────
  Future<String> login(String username, String password) async {
    final response = await _dio.post('/api/auth/login', data: {
      'username': username,
      'password': password,
    });
    return response.data['accessToken'] as String;
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
      '/api/vehicles/$vehicleId/telemetry/recent',
      queryParameters: {'limit': limit},
    );
    return response.data as List<dynamic>;
  }

  // ── 이상 이벤트 ───────────────────────────────────────────────
  Future<List<dynamic>> getAnomalies(String vehicleId) async {
    final response = await _dio.get('/api/vehicles/$vehicleId/anomalies');
    return response.data as List<dynamic>;
  }

  // ── AI 진단 (Phase 7 완성 후 활성화) ─────────────────────────
  Future<Map<String, dynamic>> getDiagnosis(String vehicleId) async {
    final response = await _dio.get('/api/vehicles/$vehicleId/diagnosis');
    return response.data as Map<String, dynamic>;
  }
}
