import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/anomaly.dart';
import 'vehicle_providers.dart';

// family — 차량별로 독립적인 캐시를 가진다. autoDispose — 화면을 벗어나면 정리.
final anomaliesProvider = FutureProvider.autoDispose
    .family<List<Anomaly>, String>((ref, vehicleId) async {
  final data = await ref.watch(apiClientProvider).getAnomalies(vehicleId);
  return data.map((e) => Anomaly.fromJson(e as Map<String, dynamic>)).toList();
});

class AnomalyQuery {
  final String vehicleId;
  final String? severity;
  final String period;
  final int page;

  const AnomalyQuery({
    required this.vehicleId,
    this.severity,
    this.period = 'all',
    this.page = 0,
  });

  @override
  bool operator ==(Object other) =>
      other is AnomalyQuery &&
      vehicleId == other.vehicleId &&
      severity == other.severity &&
      period == other.period &&
      page == other.page;

  @override
  int get hashCode => Object.hash(vehicleId, severity, period, page);
}

class AnomalyPage {
  final List<Anomaly> content;
  final int totalElements;
  final int page;
  final bool hasNext;

  const AnomalyPage({
    required this.content,
    required this.totalElements,
    required this.page,
    required this.hasNext,
  });
}

final anomalyPageProvider = FutureProvider.autoDispose
    .family<AnomalyPage, AnomalyQuery>((ref, query) async {
  final from = switch (query.period) {
    'day' => DateTime.now().subtract(const Duration(hours: 24)),
    'week' => DateTime.now().subtract(const Duration(days: 7)),
    _ => null,
  };
  final data = await ref.watch(apiClientProvider).getAnomalyPage(
        query.vehicleId,
        severity: query.severity,
        from: from,
        page: query.page,
      );
  return AnomalyPage(
    content: (data['content'] as List<dynamic>)
        .map((e) => Anomaly.fromJson(e as Map<String, dynamic>))
        .toList(),
    totalElements: (data['totalElements'] as num).toInt(),
    page: (data['page'] as num).toInt(),
    hasNext: data['hasNext'] as bool,
  );
});
