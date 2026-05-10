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
  bool _loading = false;
  String? _error;

  Future<void> _requestDiagnosis() async {
    setState(() {
      _loading = true;
      _error = null;
      _diagnosis = null;
    });

    try {
      final result = await ApiClient().getDiagnosis(widget.vehicleId);
      setState(() {
        _diagnosis = result['diagnosis'] as String?;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'AI 진단을 사용할 수 없습니다.\nPhase 7 백엔드 구현 후 이용 가능합니다.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI 진단 — ${widget.vehicleId}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF1565C0).withOpacity(0.3)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.psychology, size: 48, color: Color(0xFF1565C0)),
                  SizedBox(height: 8),
                  Text(
                    'AI 차량 진단',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '최근 센서 데이터와 DTC 코드를 분석하여\n차량 상태를 진단합니다',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loading ? null : _requestDiagnosis,
              icon: _loading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.search),
              label: Text(_loading ? '분석 중...' : '진단 시작'),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.orange)),
              ),
            if (_diagnosis != null)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _diagnosis!,
                      style: const TextStyle(height: 1.6),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
