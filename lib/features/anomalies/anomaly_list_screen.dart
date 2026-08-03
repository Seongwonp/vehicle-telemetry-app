import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/models/anomaly.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/anomaly_card.dart';
import 'widgets/empty_view.dart';
import 'widgets/error_view.dart';

class AnomalyListScreen extends StatefulWidget {
  final String vehicleId;
  const AnomalyListScreen({required this.vehicleId, super.key});

  @override
  State<AnomalyListScreen> createState() => _AnomalyListScreenState();
}

class _AnomalyListScreenState extends State<AnomalyListScreen> {
  List<Anomaly> _anomalies = [];
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final data = await ApiClient().getAnomalies(widget.vehicleId);
      if (mounted) {
        setState(() {
          _anomalies = data
              .map((e) => Anomaly.fromJson(e as Map<String, dynamic>))
              .toList();
          _loading = false;
        });
      }
    } catch (_) {
      // 조회 실패를 빈 리스트로 남겨두면 "이상 이벤트 없음(정상)" 화면이 그대로
      // 떠서 실패를 성공처럼 보여주게 된다 — 반드시 별도 에러 뷰로 구분한다.
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
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
            const Text('이상 이력',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(widget.vehicleId,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
        actions: [
          if (!_loading)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _anomalies.isEmpty
                        ? AppTheme.success.withOpacity(0.15)
                        : AppTheme.danger.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_anomalies.length}건',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _anomalies.isEmpty
                          ? AppTheme.success
                          : AppTheme.danger,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error
              ? AnomalyErrorView(onRetry: _load)
              : _anomalies.isEmpty
                  ? const AnomalyEmptyView()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                            itemCount: _anomalies.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) =>
                                AnomalyCard(anomaly: _anomalies[i]),
                          ),
                        ),
                      ),
                    ),
    );
  }
}
