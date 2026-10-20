import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../vehicle_list/vehicle_list_screen.dart';
import '../../core/theme/design_tokens.dart';

String loginErrorMessage(DioException e) {
  final statusCode = e.response?.statusCode;
  if (statusCode == 401 || statusCode == 403) {
    return '아이디 또는 비밀번호가 올바르지 않습니다.';
  }
  if (statusCode == 429) {
    return '로그인 시도가 너무 많습니다. 잠시 후 다시 시도하세요.';
  }
  if (statusCode != null && statusCode >= 500) {
    return '서버에 일시적인 문제가 발생했습니다. 잠시 후 다시 시도하세요.';
  }
  if (statusCode != null) {
    return '로그인 요청을 처리할 수 없습니다. 입력 내용을 확인하세요.';
  }
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return '백엔드 서버에 연결할 수 없습니다. 서버 주소와 네트워크 상태를 확인하세요.';
    default:
      return '로그인에 실패했습니다. 잠시 후 다시 시도하세요.';
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).login(
            _usernameController.text.trim(),
            _passwordController.text,
          );
      // 이 화면은 push된 상태라 home:이 바뀌어도 반영되지 않는다. 스택을 비우고 직접 전환한다.
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const VehicleListScreen()),
          (route) => false,
        );
      }
    } on DioException catch (e) {
      // 401만 "아이디/비밀번호 오류"로 뭉뚱그린다(계정 존재 여부를 숨긴다).
      // 네트워크·타임아웃·서버 장애는 따로 알린다.
      if (mounted) {
        setState(() => _error = loginErrorMessage(e));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = '알 수 없는 오류가 발생했습니다.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final colors = context.appColors;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.7),
            radius: 1.2,
            colors: [
              Color.lerp(colors.background, cs.primary, 0.06)!,
              colors.background
            ],
            stops: const [0.0, 0.75],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.xl, vertical: Spacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: ContentWidths.form),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── 헤더 ───────────────────────────────────
                      Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: Spacing.lg),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 100,
                              width: 240,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // 가로로 긴 로고라 원형으로 자르지 않고 뒤에 글로우만 깐다.
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: cs.primary
                                              .withValues(alpha: 0.18),
                                          blurRadius: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Image.asset(
                                    'assets/logo_icon.png',
                                    height: 80,
                                    fit: BoxFit.contain,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: Spacing.lg),
                            Text(
                              '차량 텔레메트리 모니터링',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: colors.textSecondary,
                                    letterSpacing: 0.3,
                                  ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: Spacing.sm),

                      // ── 입력 폼 ─────────────────────────────────
                      // integration_test가 이 Key로 필드를 찾는다 — 바꾸지 말 것.
                      TextFormField(
                        key: const Key('login_username_field'),
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: '아이디',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? '아이디를 입력하세요'
                            : null,
                      ),
                      const SizedBox(height: Spacing.md),
                      TextFormField(
                        key: const Key('login_password_field'),
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: '비밀번호',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _login(),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? '비밀번호를 입력하세요' : null,
                      ),

                      // ── 에러 메시지 ──────────────────────────────
                      if (_error != null) ...[
                        const SizedBox(height: Spacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: Spacing.sm, vertical: Spacing.sm),
                          decoration: BoxDecoration(
                            color: cs.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(Radii.md),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 16, color: cs.error),
                              const SizedBox(width: Spacing.xs),
                              Expanded(
                                child: Text(_error!,
                                    style: TextStyle(
                                        color: cs.error,
                                        fontSize: FontSizes.caption)),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: Spacing.xl),

                      // ── 로그인 버튼 ──────────────────────────────
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: colors.primaryGradient,
                          borderRadius: BorderRadius.circular(Radii.md),
                          boxShadow: [
                            BoxShadow(
                              color: cs.primary.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            key: const Key('login_submit_button'),
                            borderRadius: BorderRadius.circular(Radii.md),
                            onTap: _loading ? null : _login,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: Spacing.md),
                              child: Center(
                                child: _loading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(
                                              Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        '로그인',
                                        style: TextStyle(
                                          fontSize: FontSizes.body,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
