import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../vehicle_list/vehicle_list_screen.dart';

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
      // MaterialApp의 home: isLoggedIn ? ... : ... 은 이 화면이 랜딩페이지 위에
      // push된 상태라 authProvider 값만 바뀌어서는 반영되지 않는다(Flutter의 잘 알려진
      // 함정 — 이미 push된 라우트는 부모의 home이 바뀌어도 자동으로 안 바뀜).
      // 로그인 성공 시 스택을 통째로 비우고 명시적으로 전환한다.
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const VehicleListScreen()),
          (route) => false,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = '아이디 또는 비밀번호가 올바르지 않습니다.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: DecoratedBox(
        // 배경에 은은한 블루 글로우를 깔아 순수 단색 배경보다 입체감을 준다.
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.7),
            radius: 1.2,
            colors: [Color.lerp(AppTheme.bg, AppTheme.primary, 0.06)!, AppTheme.bg],
            stops: const [0.0, 0.75],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── 헤더 ───────────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withOpacity(0.18),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/logo.png',
                                  height: 96,
                                  width: 96,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              '차량 실시간 모니터링 · AI 진단',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.textSecondary,
                                    letterSpacing: 0.3,
                                  ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── 입력 폼 ─────────────────────────────────
                      TextFormField(
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
                      const SizedBox(height: 14),
                      TextFormField(
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
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: cs.error.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 16, color: cs.error),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_error!,
                                    style: TextStyle(
                                        color: cs.error, fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 28),

                      // ── 로그인 버튼 ──────────────────────────────
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.28),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: _loading ? null : _login,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: _loading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        '로그인',
                                        style: TextStyle(
                                          fontSize: 15,
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
