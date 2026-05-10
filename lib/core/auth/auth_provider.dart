import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'token_storage.dart';
import '../api/api_client.dart';

final authProvider = StateNotifierProvider<AuthNotifier, bool>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<bool> {
  AuthNotifier() : super(false) {
    _checkToken();
  }

  Future<void> _checkToken() async {
    state = await TokenStorage.hasToken();
  }

  Future<void> login(String username, String password) async {
    final token = await ApiClient().login(username, password);
    await TokenStorage.save(token);
    state = true;
  }

  Future<void> logout() async {
    await TokenStorage.clear();
    state = false;
  }
}
