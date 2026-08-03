import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/anomaly.dart';

// family — 차량별로 독립적인 캐시를 가진다. autoDispose — 화면을 벗어나면 정리.
final anomaliesProvider = FutureProvider.autoDispose
    .family<List<Anomaly>, String>((ref, vehicleId) async {
  final data = await ApiClient().getAnomalies(vehicleId);
  return data.map((e) => Anomaly.fromJson(e as Map<String, dynamic>)).toList();
});
