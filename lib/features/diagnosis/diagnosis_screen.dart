import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import 'widgets/error_section.dart';
import 'widgets/header_card.dart';
import 'widgets/loading_section.dart';
import 'widgets/result_section.dart';

// 차량 상세 화면(VehicleDetailScreen)의 세 번째 탭 — 자체 Scaffold/AppBar 없이
// 본문만 그린다.
class DiagnosisTab extends StatefulWidget {
  final String vehicleId;
  const DiagnosisTab({required this.vehicleId, super.key});

  @override
  State<DiagnosisTab> createState() => _DiagnosisTabState();
}

class _DiagnosisTabState extends State<DiagnosisTab>
    with AutomaticKeepAliveClientMixin {
  // 탭을 멀리 스와이프했다 돌아왔을 때 진단 결과가 날아가면 안 된다 —
  // Gemini 호출이 20~35초씩 걸리는데 그걸 매번 다시 하게 만들 순 없다.
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
      _diagnosis = null;
      _dataPoints = null;
      _grade = null;
      _score = null;
      _diagnosedAt = null;
    });

    try {
      final result = await ApiClient().getDiagnosis(widget.vehicleId);
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
    super.build(context); // AutomaticKeepAliveClientMixin 필수 호출
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 헤더 카드
              DiagnosisHeaderCard(vehicleId: widget.vehicleId),
              const SizedBox(height: 16),

              // 진단 시작/재진단 버튼 — 이미 결과가 있어도 눌러서 최신 데이터
              // 기준으로 새 진단을 다시 요청할 수 있다. 처음과 재진단을 라벨로
              // 구분해 "다시 눌러도 새로 진단되는지" 헷갈리지 않게 한다.
              FilledButton.icon(
                onPressed: _loading ? null : _requestDiagnosis,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFF241503)),
                      )
                    : Icon(_diagnosis != null ? Icons.refresh : Icons.search),
                label: Text(
                  _loading
                      ? 'AI 분석 중...'
                      : (_diagnosis != null ? '다시 진단하기' : '고장진단하기'),
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
