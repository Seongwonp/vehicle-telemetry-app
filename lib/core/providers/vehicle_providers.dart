import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/vehicle.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

// autoDispose — 차량 목록 화면을 벗어나면 캐시를 정리한다(로그아웃 후 다른 계정으로
// 재로그인했을 때 이전 계정의 목록이 잠깐이라도 남아있지 않도록).
final vehiclesProvider = FutureProvider.autoDispose<List<Vehicle>>((ref) async {
  final data = await ref.watch(apiClientProvider).getVehicles();
  return data.map((e) => Vehicle.fromJson(e as Map<String, dynamic>)).toList();
});
