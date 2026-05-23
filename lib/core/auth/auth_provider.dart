import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'token_storage.dart';
import '../api/api_client.dart';

final authProvider = StateNotifierProvider<AuthNotifier, bool>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<bool> {
  AuthNotifier() : super(false) {
    // refresh token 만료/무효 시 인터셉터에서 이 콜백을 호출 → 강제 로그아웃
    ApiClient().onRefreshFailed = () {
      TokenStorage.clear();
      state = false;
    };
    _checkToken();
  }

  Future<void> _checkToken() async {
    state = await TokenStorage.hasToken();
  }

  Future<void> login(String username, String password) async {
    final result = await ApiClient().login(username, password);
    await TokenStorage.save(result['accessToken']!, result['refreshToken']!);
    state = true;
  }

  Future<void> logout() async {
    await TokenStorage.clear();
    state = false;
  }
}
