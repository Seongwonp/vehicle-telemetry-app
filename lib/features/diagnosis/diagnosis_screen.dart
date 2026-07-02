import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/error_section.dart';
import 'widgets/header_card.dart';
import 'widgets/loading_section.dart';
import 'widgets/result_section.dart';

class DiagnosisScreen extends StatefulWidget {
  final String vehicleId;
  const DiagnosisScreen({required this.vehicleId, super.key});

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  String? _diagnosis;
  int? _dataPoints;
  bool _loading = false;
  String? _error;
  DateTime? _diagnosedAt;

  Future<void> _requestDiagnosis() async {
    setState(() {
      _loading = true;
      _error = null;
      _diagnosis = null;
      _dataPoints = null;
      _diagnosedAt = null;
    });

    try {
      final result = await ApiClient().getDiagnosis(widget.vehicleId);
      if (mounted) {
        setState(() {
          _diagnosis = result['diagnosis'] as String?;
          _dataPoints = result['dataPoints'] as int?;
          _loading = false;
          _diagnosedAt = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '진단 요청에 실패했습니다.\n백엔드 연결 또는 API 키를 확인하세요.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('AI 진단',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(widget.vehicleId,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 헤더 카드
                DiagnosisHeaderCard(vehicleId: widget.vehicleId),
                const SizedBox(height: 16),

                // 진단 시작 버튼
                FilledButton.icon(
                  onPressed: _loading ? null : _requestDiagnosis,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.search),
                  label: Text(
                    _loading ? 'AI 분석 중...' : '진단 시작',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),

                // 로딩 상태
                if (_loading) ...[
                  const SizedBox(height: 24),
                  const DiagnosisLoadingSection(),
                ],

                // 에러
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  DiagnosisErrorSection(message: _error!),
                ],

                // 진단 결과
                if (_diagnosis != null) ...[
                  const SizedBox(height: 16),
                  DiagnosisResultSection(
                    diagnosis: _diagnosis!,
                    dataPoints: _dataPoints ?? 0,
                    diagnosedAt: _diagnosedAt!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
