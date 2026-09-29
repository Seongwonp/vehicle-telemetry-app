import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/providers/vehicle_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../landing/landing_screen.dart';

// 백엔드 PasswordPolicy와 같은 값 — 서버가 최종 판정하고, 여기서는 요청을 아끼기 위해 먼저 거른다.
const int _minLength = 8;
const int _maxLength = 72;

const String _policyMessage = '새 비밀번호는 $_minLength~$_maxLength자로 입력하세요';
const String _sameAsCurrentMessage = '현재 비밀번호와 다른 비밀번호를 입력하세요';

/// 본인 비밀번호 변경. 성공하면 서버가 refresh token을 모두 폐기하므로(다음 refresh가
/// 실패하기 전에) 로컬 세션을 지우고 처음 화면으로 돌아간다.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _loading = false;

  String? _currentError;
  String? _newError;
  String? _confirmError;
  // 특정 칸에 귀속되지 않는 오류(일시 장애·연결 실패·세션 만료).
  String? _generalError;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  /// 클라이언트에서 판정 가능한 규칙. 오류가 하나라도 있으면 요청을 보내지 않는다.
  bool _validate() {
    final current = _currentController.text;
    final next = _newController.text;
    final confirm = _confirmController.text;

    String? currentError;
    String? newError;
    String? confirmError;

    if (current.isEmpty) currentError = '현재 비밀번호를 입력하세요';
    if (next.trim().isEmpty ||
        next.length < _minLength ||
        next.length > _maxLength) {
      newError = _policyMessage;
    } else if (next == current) {
      newError = _sameAsCurrentMessage;
    }
    if (confirm != next) confirmError = '새 비밀번호가 일치하지 않습니다';

    setState(() {
      _currentError = currentError;
      _newError = newError;
      _confirmError = confirmError;
      _generalError = null;
    });
    return currentError == null && newError == null && confirmError == null;
  }

  Future<void> _submit() async {
    if (_loading || !_validate()) return;

    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(apiClientProvider)
          .changePassword(_currentController.text, _newController.text);
    } on DioException catch (e) {
      if (mounted) {
        _showFailure(e);
        setState(() => _loading = false);
      }
      return;
    } catch (_) {
      if (mounted) {
        setState(() {
          _generalError = '알 수 없는 오류가 발생했습니다. 비밀번호는 바뀌지 않았을 수 있습니다.';
          _loading = false;
        });
      }
      return;
    }

    // 성공 — 서버는 이미 이 사용자의 refresh token을 모두 폐기했다.
    // 기존 로그아웃 경로가 로컬 토큰을 지운다(서버 폐기 호출 실패는 그쪽에서 삼킨다).
    messenger.showSnackBar(
        const SnackBar(content: Text('비밀번호를 바꿨습니다. 다시 로그인해 주세요.')));
    await ref.read(authProvider.notifier).logout();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LandingScreen()),
      (route) => false,
    );
  }

  void _showFailure(DioException e) {
    final status = e.response?.statusCode;
    final code = ApiClient.errorCode(e);
    setState(() {
      _currentError = null;
      _newError = null;
      _confirmError = null;
      _generalError = null;
      if (code == 'CURRENT_PASSWORD_INCORRECT') {
        _currentError = '현재 비밀번호가 맞지 않습니다';
      } else if (code == 'VALIDATION_FAILED') {
        _newError = _policyMessage;
      } else if (code == 'BAD_REQUEST' && status == 400) {
        _newError = _sameAsCurrentMessage;
      } else if (status == 503) {
        _generalError = '일시적인 장애로 처리하지 못했습니다. 비밀번호는 바뀌지 않았습니다. '
            '잠시 뒤 다시 시도해 주세요.';
      } else if (status == 401) {
        _generalError = '로그인이 만료되었습니다. 다시 로그인해 주세요.';
      } else if (e.response == null) {
        _generalError = '서버에 연결하지 못했습니다. 연결을 확인한 뒤 다시 시도해 주세요.';
      } else {
        _generalError = '비밀번호를 바꾸지 못했습니다. 잠시 뒤 다시 시도해 주세요.';
      }
    });
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required bool visible,
    required VoidCallback onToggle,
    required String? error,
    required VoidCallback onChanged,
    TextInputAction action = TextInputAction.next,
    VoidCallback? onSubmitted,
    String? helper,
  }) {
    return TextField(
      controller: controller,
      obscureText: !visible,
      enabled: !_loading,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: action,
      onChanged: (_) => onChanged(),
      onSubmitted: onSubmitted == null ? null : (_) => onSubmitted(),
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        errorText: error,
        errorMaxLines: 3,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: visible ? '$label 가리기' : '$label 보기',
          icon: Icon(visible
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined),
          onPressed: onToggle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      appBar: AppBar(title: const Text('비밀번호 변경')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: ContentWidths.form),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _field(
                  controller: _currentController,
                  label: '현재 비밀번호',
                  visible: _showCurrent,
                  onToggle: () => setState(() => _showCurrent = !_showCurrent),
                  error: _currentError,
                  onChanged: () {
                    if (_currentError != null) {
                      setState(() => _currentError = null);
                    }
                  },
                ),
                const SizedBox(height: Spacing.md),
                _field(
                  controller: _newController,
                  label: '새 비밀번호',
                  helper: '$_minLength~$_maxLength자',
                  visible: _showNew,
                  onToggle: () => setState(() => _showNew = !_showNew),
                  error: _newError,
                  onChanged: () {
                    if (_newError != null) setState(() => _newError = null);
                  },
                ),
                const SizedBox(height: Spacing.md),
                _field(
                  controller: _confirmController,
                  label: '새 비밀번호 확인',
                  visible: _showConfirm,
                  onToggle: () => setState(() => _showConfirm = !_showConfirm),
                  error: _confirmError,
                  action: TextInputAction.done,
                  onSubmitted: _submit,
                  onChanged: () {
                    if (_confirmError != null) {
                      setState(() => _confirmError = null);
                    }
                  },
                ),
                if (_generalError != null) ...[
                  const SizedBox(height: Spacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.sm, vertical: Spacing.sm),
                    decoration: BoxDecoration(
                      color: colors.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error_outline,
                            size: 16, color: colors.danger),
                        const SizedBox(width: Spacing.xs),
                        Expanded(
                          child: Text(_generalError!,
                              style: TextStyle(
                                  color: colors.danger,
                                  fontSize: FontSizes.caption)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: Spacing.md),
                Text(
                  '바꾸면 이 계정의 로그인이 모두 해제되어 다시 로그인해야 합니다.',
                  style: TextStyle(
                      fontSize: FontSizes.caption, color: colors.textSecondary),
                ),
                const SizedBox(height: Spacing.lg),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                  ),
                  child: Text(_loading ? '변경 중...' : '비밀번호 변경',
                      style: const TextStyle(
                          fontSize: FontSizes.body,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
