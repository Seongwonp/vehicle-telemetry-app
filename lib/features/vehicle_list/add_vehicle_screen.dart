import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';

// OBD-II 동글/시뮬레이터가 보내는 vehicle_id와 실제로 매칭시키려면 백엔드에
// 차량이 미리 등록되어 있어야 한다(VehicleService.register) — 그동안 이
// 등록 API를 호출할 화면이 앱 안에 없어서 curl로만 등록할 수 있었다.
class AddVehicleScreen extends StatefulWidget {
  final ApiClient? apiClient;
  const AddVehicleScreen({this.apiClient, super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _ownerController = TextEditingController();
  final _idPattern = RegExp(r'^[A-Z0-9-]{4,20}$');

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _ownerController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await (widget.apiClient ?? ApiClient()).registerVehicle(
        _idController.text.trim(),
        _nameController.text.trim(),
        _ownerController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on DioException catch (e) {
      // 백엔드가 중복 ID 등 검증 실패를 400 + {message}로 내려준다 —
      // 그대로 보여주면 "왜 등록이 안 되는지" 사용자가 바로 알 수 있다.
      final message = e.response?.data is Map
          ? (e.response?.data as Map)['message'] as String?
          : null;
      if (mounted) {
        setState(() => _error = message ?? '차량 등록에 실패했습니다. 잠시 후 다시 시도하세요.');
      }
    } catch (_) {
      if (mounted) setState(() => _error = '알 수 없는 오류가 발생했습니다.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      appBar: AppBar(title: const Text('차량 추가')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: ContentWidths.form),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(Spacing.md),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(Radii.md),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 18, color: colors.textSecondary),
                        const SizedBox(width: Spacing.sm),
                        Expanded(
                          child: Text(
                            '차량 ID는 OBD-II 동글/시뮬레이터가 전송하는 vehicle_id와 '
                            '정확히 일치해야 실시간 데이터가 연결됩니다.',
                            style: TextStyle(
                                fontSize: FontSizes.caption,
                                color: colors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),
                  TextFormField(
                    controller: _idController,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [UpperCaseTextFormatter()],
                    decoration: const InputDecoration(
                      labelText: '차량 ID',
                      hintText: '예: KR-GA-1234',
                      prefixIcon: Icon(Icons.tag),
                    ),
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return '차량 ID를 입력하세요';
                      if (!_idPattern.hasMatch(value)) {
                        return '대문자/숫자/하이픈 4~20자로 입력하세요';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: Spacing.md),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: '차량 이름',
                      hintText: '예: 현대 아반떼',
                      prefixIcon: Icon(Icons.directions_car_outlined),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? '차량 이름을 입력하세요' : null,
                  ),
                  const SizedBox(height: Spacing.md),
                  TextFormField(
                    controller: _ownerController,
                    decoration: const InputDecoration(
                      labelText: '소유자',
                      hintText: '예: 박성원',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? '소유자를 입력하세요' : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: Spacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.sm, vertical: Spacing.sm),
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(Radii.md),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 16, color: AppTheme.danger),
                          const SizedBox(width: Spacing.xs),
                          Expanded(
                            child: Text(_error!,
                                style: const TextStyle(
                                    color: AppTheme.danger,
                                    fontSize: FontSizes.caption)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: Spacing.lg),
                  FilledButton.icon(
                    onPressed: _loading ? null : _submit,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.add),
                    label: Text(_loading ? '등록 중...' : '등록하기',
                        style: const TextStyle(
                            fontSize: FontSizes.body,
                            fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
