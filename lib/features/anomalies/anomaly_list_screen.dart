import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/anomaly_providers.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/anomaly_card.dart';
import 'widgets/empty_view.dart';
import 'widgets/error_view.dart';

class AnomalyListScreen extends ConsumerWidget {
  final String vehicleId;
  const AnomalyListScreen({required this.vehicleId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anomaliesAsync = ref.watch(anomaliesProvider(vehicleId));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('이상 이력',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(vehicleId,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
        actions: [
          // 로딩/에러 중엔 건수 배지를 안 보여준다 — 로딩 중엔 아직 값이 없고,
          // 에러 중엔 0건처럼 보이면 "정상"으로 오인될 수 있다.
          anomaliesAsync.maybeWhen(
            data: (anomalies) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: anomalies.isEmpty
                        ? AppTheme.success.withOpacity(0.15)
                        : AppTheme.danger.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${anomalies.length}건',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: anomalies.isEmpty
                          ? AppTheme.success
                          : AppTheme.danger,
                    ),
                  ),
                ),
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      // 조회 실패(error)와 "이상 이벤트 없음"(data가 빈 리스트, 정상)을
      // AsyncValue가 애초에 서로 다른 상태로 분리해주기 때문에, 예전처럼 catch에서
      // 빈 리스트로 남겨둬 실패가 "정상"으로 위장되는 실수 자체가 구조적으로 불가능하다.
      body: anomaliesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => AnomalyErrorView(
          onRetry: () => ref.invalidate(anomaliesProvider(vehicleId)),
        ),
        data: (anomalies) => anomalies.isEmpty
            ? const AnomalyEmptyView()
            : RefreshIndicator(
                onRefresh: () =>
                    ref.refresh(anomaliesProvider(vehicleId).future),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      itemCount: anomalies.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) =>
                          AnomalyCard(anomaly: anomalies[i]),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
