import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import 'widgets/error_section.dart';
import '../../core/theme/design_tokens.dart';
import 'widgets/header_card.dart';
import 'widgets/loading_section.dart';
import 'widgets/result_section.dart';

String diagnosisErrorMessage(DioException e) {
  final statusCode = e.response?.statusCode;
  if (statusCode == 401 || statusCode == 403) {
    return '로그인 세션이 만료되었습니다. 다시 로그인해 주세요.';
  }
  if (statusCode == 404 || statusCode == 422) {
    return '진단할 센서 데이터가 부족합니다. 차량 데이터를 먼저 수집해 주세요.';
  }
  if (statusCode == 429) {
    return '진단 요청이 많습니다. 잠시 후 다시 시도하세요.';
  }
  if (statusCode != null && statusCode >= 500) {
    return '진단 서버에 일시적인 문제가 발생했습니다. 잠시 후 다시 시도하세요.';
  }
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return '진단 응답 시간이 초과되었습니다. 잠시 후 다시 시도하세요.';
    case DioExceptionType.connectionError:
      return '서버에 연결할 수 없습니다. 네트워크 상태를 확인하세요.';
    default:
      return '진단 요청에 실패했습니다. 잠시 후 다시 시도하세요.';
  }
}

class DiagnosisTab extends StatefulWidget {
  final String vehicleId;
  final ApiClient? apiClient;
  const DiagnosisTab({required this.vehicleId, this.apiClient, super.key});

  @override
  State<DiagnosisTab> createState() => _DiagnosisTabState();
}

class _DiagnosisTabState extends State<DiagnosisTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String? _diagnosis;
  int? _dataPoints;
  String? _grade;
  int? _score;
  bool _loading = false;
  String? _error;
  DateTime? _diagnosedAt;

  Future<void> _requestDiagnosis() async {
    setState(() {
      _loading = true;
      _error = null;
      // 재진단 중에도 마지막 정상 결과를 유지한다. 성공했을 때만 교체한다.
    });

    try {
      final result = await (widget.apiClient ?? ApiClient())
          .getDiagnosis(widget.vehicleId);
      if (mounted) {
        setState(() {
          _diagnosis = result['diagnosis'] as String?;
          _dataPoints = result['dataPoints'] as int?;
          _grade = result['grade'] as String?;
          _score = result['score'] as int?;
          _loading = false;
          _diagnosedAt = DateTime.now();
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _error = diagnosisErrorMessage(e);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = '진단 응답을 처리하지 못했습니다. 잠시 후 다시 시도하세요.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 필수 호출
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          Spacing.md, Spacing.sm, Spacing.md, Spacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: ContentWidths.reading),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DiagnosisHeaderCard(vehicleId: widget.vehicleId),
              const SizedBox(height: Spacing.md),
              FilledButton.icon(
                onPressed: _loading ? null : _requestDiagnosis,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(_diagnosis != null ? Icons.refresh : Icons.search),
                label: Text(
                  _loading
                      ? '분석 중...'
                      : (_diagnosis != null ? '다시 확인하기' : '진단 요청'),
                  style: const TextStyle(
                      fontSize: FontSizes.subtitle,
                      fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                ),
              ),
              if (_loading) ...[
                const SizedBox(height: Spacing.lg),
                const DiagnosisLoadingSection(),
              ],
              if (_error != null) ...[
                const SizedBox(height: Spacing.md),
                DiagnosisErrorSection(message: _error!),
              ],
              if (_diagnosis != null) ...[
                const SizedBox(height: Spacing.md),
                DiagnosisResultSection(
                  diagnosis: _diagnosis!,
                  dataPoints: _dataPoints ?? 0,
                  grade: _grade ?? '?',
                  score: _score ?? 0,
                  diagnosedAt: _diagnosedAt!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
