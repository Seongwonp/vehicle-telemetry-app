import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telemetrix/core/models/trip.dart';
import 'package:telemetrix/core/models/vehicle.dart';
import 'package:telemetrix/core/providers/vehicle_providers.dart';
import 'package:telemetrix/features/vehicle_list/vehicle_list_screen.dart';
import 'package:telemetrix/features/vehicle_list/widgets/vehicle_card.dart';

void main() {
  test('Trip.fromJson이 백엔드 트립 응답의 숫자 타입을 안전하게 변환한다', () {
    final trip = Trip.fromJson({
      'startTime': '2026-08-05T01:00:00Z',
      'endTime': '2026-08-05T01:42:00Z',
      'durationMinutes': 42,
      'distanceKm': 18,
      'avgSpeedKmh': 25.7,
      'maxSpeedKmh': 61,
      'pointCount': 15,
    });

    expect(trip.startTime, DateTime.utc(2026, 8, 5, 1));
    expect(trip.durationMinutes, 42);
    expect(trip.distanceKm, 18.0);
    expect(trip.maxSpeedKmh, 61.0);
  });

  test('Vehicle.fromJson은 막 등록한 차량의 fleet null/0 필드를 처리한다', () {
    final vehicle = Vehicle.fromJson({
      'vehicleId': 'NEW-001',
      'name': '새 차량',
      'owner': 'tester',
      'active': true,
      'registeredAt': '2026-08-05T01:00:00Z',
      'lastSeenAt': null,
      'latestSpeed': null,
      'highAnomalyCount': null,
    });

    expect(vehicle.lastSeenAt, isNull);
    expect(vehicle.latestSpeed, isNull);
    expect(vehicle.highAnomalyCount, 0);
  });

  test('fleet 신호 시각을 정상/지연/오프라인/데이터 없음으로 분류한다', () {
    final now = DateTime.utc(2026, 8, 5, 1);

    expect(fleetSignalState(now.subtract(const Duration(minutes: 4)), now),
        FleetSignalState.recent);
    expect(fleetSignalState(now.subtract(const Duration(minutes: 10)), now),
        FleetSignalState.delayed);
    expect(fleetSignalState(now.subtract(const Duration(minutes: 30)), now),
        FleetSignalState.offline);
    expect(fleetSignalState(null, now), FleetSignalState.noData);
  });

  testWidgets('태블릿 2열 fleet 카드가 큰 글자에서도 overflow하지 않는다', (tester) async {
    tester.view.physicalSize = const Size(700, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final vehicle = Vehicle(
      vehicleId: 'SIM-001-LONG-ID',
      name: '테스트 차량 이름',
      owner: 'long-owner-name',
      active: true,
      registeredAt: DateTime.utc(2026, 8, 1),
      lastSeenAt: DateTime.now().subtract(const Duration(minutes: 10)),
      latestSpeed: 123,
      highAnomalyCount: 3,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vehiclesProvider.overrideWith((_) async => [vehicle]),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: VehicleListScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(VehicleCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
