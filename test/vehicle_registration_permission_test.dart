import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telemetrix/core/models/vehicle.dart';
import 'package:telemetrix/core/providers/vehicle_providers.dart';
import 'package:telemetrix/features/vehicle_list/vehicle_list_screen.dart';

void main() {
  for (final admin in [true, false]) {
    testWidgets('vehicle registration controls: admin=$admin', (tester) async {
      await tester.pumpWidget(ProviderScope(overrides: [
        vehiclesProvider.overrideWith((ref) async => []),
        canRegisterVehiclesProvider.overrideWith((ref) async => admin),
      ], child: const MaterialApp(home: VehicleListScreen())));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.add), admin ? findsNWidgets(2) : findsNothing);
      expect(find.text('차량 등록과 배정은 관리자에게 요청해 주세요.'),
          admin ? findsNothing : findsOneWidget);
    });
  }
  testWidgets('unknown role fails closed', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [
      vehiclesProvider.overrideWith((ref) async => []),
      canRegisterVehiclesProvider
          .overrideWith((ref) async => throw Exception('offline')),
    ], child: const MaterialApp(home: VehicleListScreen())));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.add), findsNothing);
  });

  for (final admin in [true, false]) {
    testWidgets('vehicle delete menu: admin=$admin', (tester) async {
      final vehicle = Vehicle.fromJson({
        'id': 1,
        'vehicleId': 'SIM-001',
        'name': 'test',
        'owner': 'driver',
        'active': true,
        'registeredAt': '2026-09-29T00:00:00',
      });
      await tester.pumpWidget(ProviderScope(overrides: [
        vehiclesProvider.overrideWith((ref) async => [vehicle]),
        canRegisterVehiclesProvider.overrideWith((ref) async => admin),
      ], child: const MaterialApp(home: VehicleListScreen())));
      await tester.pumpAndSettle();
      // 백엔드는 비활성화도 관리자만 허용한다 — 일반 사용자에게 메뉴를 보이면 403만 받는다.
      expect(
          find.byIcon(Icons.more_vert), admin ? findsOneWidget : findsNothing);
    });
  }
}
