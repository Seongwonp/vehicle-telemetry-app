import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'token_storage.dart';
import '../api/api_client.dart';
import '../navigation/navigator_key.dart';
import '../../features/landing/landing_screen.dart';

final authProvider = StateNotifierProvider<AuthNotifier, bool>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<bool> {
  AuthNotifier() : super(false) {
    // refresh token 만료/무효 시 인터셉터에서 이 콜백을 호출 → 강제 로그아웃.
    // login/logout 버튼과 달리 이 트리거는 위젯 트리 밖(인터셉터)에서 일어나
    // BuildContext가 없다 — 로그인 화면이 이미 대시보드 등 다른 화면 위에 깊이
    // push돼 있어도 rootNavigatorKey로 스택을 통째로 리셋해 로그인 화면으로 되돌린다.
    // (state = false만 하고 네비게이션을 안 하면, MaterialApp의 home:은 이미 push된
    // 라우트 위에서는 반영되지 않아 사용자가 로그아웃된 채로 같은 화면에 계속 머문다.)
    ApiClient().onRefreshFailed = () {
      TokenStorage.clear();
      state = false;
      rootNavigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LandingScreen()),
        (route) => false,
      );
    };
    _checkToken();
  }

  Future<void> _checkToken() async {
    state = await TokenStorage.hasToken();
  }

  Future<void> login(String username, String password) async {
    final result = await ApiClient().login(username, password);
    await TokenStorage.save(
        result['accessToken']!, result['refreshToken']!, username);
    state = true;
  }

  Future<void> logout() async {
    final refreshToken = await TokenStorage.getRefreshToken();
    if (refreshToken != null) {
      try {
        await ApiClient().logout(refreshToken);
      } catch (_) {
        // 서버 호출이 실패해도(오프라인 등) 클라이언트 로그아웃은 계속 진행한다.
      }
    }
    await TokenStorage.clear();
    state = false;
  }
}
