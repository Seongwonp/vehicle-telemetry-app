import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'token_storage.dart';
import '../api/api_client.dart';
import '../navigation/navigator_key.dart';
import '../providers/vehicle_providers.dart';
import '../../features/vehicle_list/vehicle_list_screen.dart';

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
    // refresh 거부 시 강제 로그아웃. 위젯 트리 밖이라 BuildContext가 없어 rootNavigatorKey로
    // 스택을 리셋한다 — state만 바꾸면 push된 화면에 그대로 머문다.
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
    MaterialPageRoute(
        builder: (_) => const VehicleListScreen(requireLogin: true)),
    (route) => false,
  );
}
