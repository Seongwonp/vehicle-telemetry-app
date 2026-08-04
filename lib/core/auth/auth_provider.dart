import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'token_storage.dart';
import '../api/api_client.dart';
import '../navigation/navigator_key.dart';
import '../providers/vehicle_providers.dart';
import '../../features/landing/landing_screen.dart';

enum AuthStatus { initializing, authenticated, unauthenticated }

final tokenStoreProvider =
    Provider<TokenStore>((ref) => const SecureTokenStore());

final authProvider = StateNotifierProvider<AuthNotifier, AuthStatus>((ref) {
  return AuthNotifier(
    apiClient: ref.watch(apiClientProvider),
    tokenStore: ref.watch(tokenStoreProvider),
  );
});

class AuthNotifier extends StateNotifier<AuthStatus> {
  final ApiClient _apiClient;
  final TokenStore _tokenStore;
  final VoidCallback _onSessionExpired;
  late final VoidCallback _refreshFailedCallback;

  AuthNotifier({
    ApiClient? apiClient,
    TokenStore? tokenStore,
    VoidCallback? onSessionExpired,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStore = tokenStore ?? const SecureTokenStore(),
        _onSessionExpired = onSessionExpired ?? _resetToLanding,
        super(AuthStatus.initializing) {
    // refresh token 만료/무효 시 인터셉터에서 이 콜백을 호출 → 강제 로그아웃.
    // login/logout 버튼과 달리 이 트리거는 위젯 트리 밖(인터셉터)에서 일어나
    // BuildContext가 없다 — 로그인 화면이 이미 대시보드 등 다른 화면 위에 깊이
    // push돼 있어도 rootNavigatorKey로 스택을 통째로 리셋해 로그인 화면으로 되돌린다.
    // (state = false만 하고 네비게이션을 안 하면, MaterialApp의 home:은 이미 push된
    // 라우트 위에서는 반영되지 않아 사용자가 로그아웃된 채로 같은 화면에 계속 머문다.)
    _refreshFailedCallback = () async {
      await _tokenStore.clear();
      if (!mounted) return;
      state = AuthStatus.unauthenticated;
      _onSessionExpired();
    };
    _apiClient.onRefreshFailed = _refreshFailedCallback;
    _checkToken();
  }

  Future<void> _checkToken() async {
    try {
      final hasToken = await _tokenStore.hasToken();
      if (mounted) {
        state =
            hasToken ? AuthStatus.authenticated : AuthStatus.unauthenticated;
      }
    } catch (_) {
      if (mounted) state = AuthStatus.unauthenticated;
    }
  }

  Future<void> login(String username, String password) async {
    final result = await _apiClient.login(username, password);
    await _tokenStore.save(
        result['accessToken']!, result['refreshToken']!, username);
    state = AuthStatus.authenticated;
  }

  Future<void> logout() async {
    final refreshToken = await _tokenStore.getRefreshToken();
    if (refreshToken != null) {
      try {
        await _apiClient.logout(refreshToken);
      } catch (_) {
        // 서버 호출이 실패해도(오프라인 등) 클라이언트 로그아웃은 계속 진행한다.
      }
    }
    await _tokenStore.clear();
    state = AuthStatus.unauthenticated;
  }

  @override
  void dispose() {
    if (_apiClient.onRefreshFailed == _refreshFailedCallback) {
      _apiClient.onRefreshFailed = null;
    }
    super.dispose();
  }
}

void _resetToLanding() {
  rootNavigatorKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LandingScreen()),
    (route) => false,
  );
}
