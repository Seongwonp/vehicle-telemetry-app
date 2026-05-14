import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('AI 진단',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(widget.vehicleId,
                style:
                    TextStyle(fontSize: 11, color: Colors.grey.shade400)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 헤더 카드
            _HeaderCard(vehicleId: widget.vehicleId),
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
              _LoadingSection(),
            ],

            // 에러
            if (_error != null) ...[
              const SizedBox(height: 16),
              _ErrorSection(message: _error!),
            ],

            // 진단 결과
            if (_diagnosis != null) ...[
              const SizedBox(height: 16),
              _ResultSection(
                diagnosis: _diagnosis!,
                dataPoints: _dataPoints ?? 0,
                diagnosedAt: _diagnosedAt!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── 헤더 카드 ─────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final String vehicleId;
  const _HeaderCard({required this.vehicleId});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child:
                Icon(Icons.psychology, size: 30, color: cs.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gemini AI 차량 진단',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: cs.primary)),
                const SizedBox(height: 4),
                Text(
                  '최근 센서 데이터 · DTC 코드 · 이상 이벤트를\n종합 분석하여 진단 결과를 제공합니다.',
                  style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withOpacity(0.55),
                      height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 로딩 상태 ─────────────────────────────────────────────────

class _LoadingSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final steps = [
      '센서 데이터 수집 중...',
      '이상 이벤트 조회 중...',
      'Gemini AI 분석 중...',
    ];
    return Column(
      children: steps
          .map((step) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(step,
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 13)),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

// ── 에러 섹션 ─────────────────────────────────────────────────

class _ErrorSection extends StatelessWidget {
  final String message;
  const _ErrorSection({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: Colors.redAccent, fontSize: 13, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

// ── 진단 결과 섹션 ────────────────────────────────────────────

class _ResultSection extends StatelessWidget {
  final String diagnosis;
  final int dataPoints;
  final DateTime diagnosedAt;

  const _ResultSection({
    required this.diagnosis,
    required this.dataPoints,
    required this.diagnosedAt,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final timeStr =
        '${diagnosedAt.hour.toString().padLeft(2, '0')}:${diagnosedAt.minute.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 메타 정보 바
        Row(
          children: [
            const Icon(Icons.check_circle, size: 15, color: Colors.greenAccent),
            const SizedBox(width: 6),
            const Text('진단 완료',
                style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('데이터 $dataPoints개 · $timeStr',
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
        const SizedBox(height: 10),

        // AI 응답 본문
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: cs.onSurface.withOpacity(0.1)),
          ),
          child: SelectableText(
            diagnosis,
            style: const TextStyle(fontSize: 14, height: 1.7),
          ),
        ),

        // 하단 안내
        const SizedBox(height: 10),
        Text(
          '* AI 진단은 참고용입니다. 정확한 진단은 정비사에게 문의하세요.',
          style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}
