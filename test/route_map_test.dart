import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telemetrix/core/models/telemetry.dart';
import 'package:telemetrix/features/dashboard/widgets/route_map.dart';

Telemetry telemetry(double? lat, double? lng) => Telemetry(
      vehicleId: 'SIM-001',
      timestamp: DateTime.utc(2026, 8, 5),
      speed: 10,
      rpm: 1000,
      engineTemp: 90,
      throttlePosition: 10,
      fuelLevel: 50,
      batteryVoltage: 13,
      lat: lat,
      lng: lng,
      dtcCodes: const [],
    );

void main() {
  test('RouteMap은 finite하고 범위 안인 GPS 좌표만 사용한다', () {
    final points = validRoutePoints([
      telemetry(37.5, 127.0),
      telemetry(91, 127.0),
      telemetry(double.nan, 127.0),
      telemetry(37.4, 181),
      telemetry(37.3, 126.9),
    ]);

    expect(points, hasLength(2));
    expect(points.first.latitude, 37.3);
    expect(points.last.latitude, 37.5);
  });

  testWidgets('좌표가 부족하면 숨기고 잘못된 좌표가 반복되면 오류를 표시한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
          home: Scaffold(body: RouteMap(history: [telemetry(37, 127)]))),
    );

    expect(find.text('주행 경로'), findsNothing);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RouteMap(history: [telemetry(91, 0), telemetry(37, 181)]),
      ),
    ));
    expect(find.textContaining('유효하지 않은 GPS 좌표'), findsOneWidget);
  });
}
