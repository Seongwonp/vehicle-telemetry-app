import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/vehicle.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

// 권한을 확인하기 전이나 조회 실패 시에는 등록 UI를 열지 않는다.
final canRegisterVehiclesProvider = FutureProvider.autoDispose<bool>((ref) {
  return ref.watch(apiClientProvider).canRegisterVehicles();
});

// autoDispose — 다른 계정으로 재로그인했을 때 이전 계정의 목록이 남지 않게 한다.
final vehiclesProvider = FutureProvider.autoDispose<List<Vehicle>>((ref) async {
  final data = await ref.watch(apiClientProvider).getVehicles();
  return data.map((e) => Vehicle.fromJson(e as Map<String, dynamic>)).toList();
});
