import 'package:flutter_test/flutter_test.dart';
import 'package:telemetrix/core/models/telemetry.dart';

Telemetry telemetry({
  double speed = 80,
  int rpm = 2000,
  double engineTemp = 90,
  double batteryVoltage = 13.8,
  double fuelLevel = 50,
}) =>
    Telemetry(
      vehicleId: 'SIM-001',
      timestamp: DateTime.utc(2026, 8, 23),
      speed: speed,
      rpm: rpm,
      engineTemp: engineTemp,
      throttlePosition: 20,
      fuelLevel: fuelLevel,
      batteryVoltage: batteryVoltage,
      dtcCodes: const [],
    );

void main() {
  test('이상 감지 경계값 자체는 정상으로 처리한다', () {
    expect(
      telemetry(
        speed: 200,
        rpm: 6000,
        engineTemp: 105,
        batteryVoltage: 11.5,
      ).hasAnomaly,
      isFalse,
    );
    expect(telemetry(batteryVoltage: 15).hasAnomaly, isFalse);
  });

  test('백엔드 규칙을 벗어난 센서 값은 이상으로 처리한다', () {
    expect(telemetry(speed: 200.1).hasAnomaly, isTrue);
    expect(telemetry(rpm: 6001).hasAnomaly, isTrue);
    expect(telemetry(engineTemp: 105.1).hasAnomaly, isTrue);
    expect(telemetry(batteryVoltage: 11.49).hasAnomaly, isTrue);
    expect(telemetry(batteryVoltage: 15.01).hasAnomaly, isTrue);
  });

  test('연료 잔량만으로 이상 감지 상태를 만들지 않는다', () {
    expect(telemetry(fuelLevel: 5).hasAnomaly, isFalse);
  });
}
