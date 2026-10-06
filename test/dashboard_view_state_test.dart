import 'package:flutter_test/flutter_test.dart';
import 'package:telemetrix/core/models/telemetry.dart';
import 'package:telemetrix/core/models/telemetry_limits.dart';
import 'package:telemetrix/features/dashboard/dashboard_view_state.dart';

Telemetry _t({
  double speed = 60,
  double rpm = 2000,
  double engineTemp = 90,
  double battery = 13.8,
  List<String> dtc = const [],
}) =>
    Telemetry(
      vehicleId: 'SIM-001',
      timestamp: DateTime.utc(2026, 8, 4, 10),
      speed: speed,
      rpm: rpm,
      engineTemp: engineTemp,
      throttlePosition: 18.5,
      fuelLevel: 58,
      batteryVoltage: battery,
      dtcCodes: dtc,
    );

DashboardViewState _state(
  Telemetry t, {
  DashboardConnectionState connection = DashboardConnectionState.connected,
}) =>
    DashboardViewState.from(
      latest: t,
      connection: connection,
      receivedAt: DateTime(2026, 8, 4, 9, 5, 7),
    );

void main() {
  group('TelemetryLimits — 경계값은 정상', () {
    test('속도', () {
      expect(TelemetryLimits.speedOver(200), isFalse);
      expect(TelemetryLimits.speedOver(200.1), isTrue);
    });
    test('RPM — OBD-II 0.25 단위', () {
      expect(TelemetryLimits.rpmOver(6000), isFalse);
      expect(TelemetryLimits.rpmOver(6000.25), isTrue);
    });
    test('엔진 온도', () {
      expect(TelemetryLimits.engineTempOver(105), isFalse);
      expect(TelemetryLimits.engineTempOver(105.1), isTrue);
    });
    test('배터리 — 범위 양끝 포함', () {
      expect(TelemetryLimits.batteryOut(11.5), isFalse);
      expect(TelemetryLimits.batteryOut(15.0), isFalse);
      expect(TelemetryLimits.batteryOut(11.49), isTrue);
      expect(TelemetryLimits.batteryOut(15.01), isTrue);
    });
    test('hasAnomaly가 같은 기준을 쓴다', () {
      expect(_t(engineTemp: 105).hasAnomaly, isFalse);
      expect(_t(engineTemp: 105.1).hasAnomaly, isTrue);
      expect(_t(dtc: ['P0217']).hasAnomaly, isTrue);
    });
  });

  group('기준 초과 건수', () {
    test('없음 0', () => expect(_state(_t()).overCount, 0));
    test('온도만 1', () => expect(_state(_t(engineTemp: 118.4)).overCount, 1));
    test('DTC만 1', () => expect(_state(_t(dtc: ['P0217'])).overCount, 1));
    test('온도 + DTC 2', () {
      expect(_state(_t(engineTemp: 118.4, dtc: ['P0217'])).overCount, 2);
    });
    test('DTC가 여러 개여도 1로 센다', () {
      expect(_state(_t(dtc: ['P0217', 'P0301'])).overCount, 1);
    });
    test('네 계측값 모두 + DTC 5', () {
      final s = _state(_t(
          speed: 201,
          rpm: 6001,
          engineTemp: 106,
          battery: 15.1,
          dtc: ['U0100']));
      expect(s.overCount, 5);
    });
  });

  group('수신 중이 아니면 지난 값으로 판정하지 않는다', () {
    for (final connection in [
      DashboardConnectionState.reconnecting,
      DashboardConnectionState.stale,
      DashboardConnectionState.connecting,
    ]) {
      test(connection.name, () {
        final s = _state(_t(engineTemp: 118.4, dtc: ['P0217']),
            connection: connection);
        expect(s.isLive, isFalse);
        expect(s.overCount, 0);
        final temp =
            s.readings.singleWhere((r) => r.kind == MetricKind.engineTemp);
        expect(temp.over, isTrue, reason: '값 자체의 판정은 남긴다');
        expect(s.showsOver(temp), isFalse, reason: '화면에는 드러내지 않는다');
      });
    }
  });

  group('표시 문자열', () {
    final s = _state(
        _t(speed: 62.44, rpm: 2140.25, engineTemp: 118.4, battery: 13.925));

    String value(MetricKind k) =>
        s.readings.singleWhere((r) => r.kind == k).valueText;
    String limit(MetricKind k) =>
        s.readings.singleWhere((r) => r.kind == k).limitText;

    test('계측값 순서와 자릿수', () {
      expect(s.readings.map((r) => r.kind), MetricKind.values);
      expect(value(MetricKind.speed), '62.4');
      expect(value(MetricKind.rpm), '2140');
      expect(value(MetricKind.engineTemp), '118.4');
      expect(value(MetricKind.battery), '13.93');
    });
    test('기준 문구', () {
      expect(limit(MetricKind.speed), '기준 200 이하');
      expect(limit(MetricKind.rpm), '기준 6000 이하');
      expect(limit(MetricKind.engineTemp), '기준 105°C 초과');
      expect(limit(MetricKind.battery), '기준 11.5–15.0V 안');
    });
    test('연료·스로틀은 기준 없이', () {
      expect(s.extras.map((e) => e.label), ['연료', '스로틀 개도']);
    });
    test('수신 시각은 받은 시각을 그대로 — 두 자리', () {
      expect(s.receivedClock, '09:05:07');
    });
  });

  // 백엔드 ADR-030 — 연료량·전압은 선택 필드다. 없으면 null이고 0이 아니다.
  group('선택 센서 — 연료량·전압이 없을 때', () {
    Map<String, dynamic> json() => {
          'vehicleId': 'SIM-001',
          'timestamp': '2026-08-04T10:00:00Z',
          'speed': 60.0,
          'rpm': 2000,
          'engineTemp': 90.0,
          'throttlePosition': 18.5,
          'dtcCodes': <String>[],
        };

    test('모델이 키 없음과 null을 모두 받고 null로 둔다 (0으로 채우지 않는다)', () {
      final absent = Telemetry.fromJson(json());
      expect(absent.fuelLevel, isNull);
      expect(absent.batteryVoltage, isNull);

      final nulls = Telemetry.fromJson(
          {...json(), 'fuelLevel': null, 'batteryVoltage': null});
      expect(nulls.fuelLevel, isNull);
      expect(nulls.batteryVoltage, isNull);

      final present =
          Telemetry.fromJson({...json(), 'fuelLevel': 0, 'batteryVoltage': 0});
      expect(present.fuelLevel, 0.0, reason: '실제 0은 0이다 — 없음과 다르다');
      expect(present.batteryVoltage, 0.0);
    });

    test('필수 값이 없으면 여전히 파싱 실패다 — 선택화 범위는 두 필드뿐', () {
      final noSpeed = json()..remove('speed');
      expect(() => Telemetry.fromJson(noSpeed), throwsA(isA<TypeError>()));
      expect(Telemetry.tryFromJson(noSpeed), isNull);
    });

    test('전압이 없으면 hasAnomaly가 전압 기준으로 켜지지 않는다', () {
      expect(Telemetry.fromJson(json()).hasAnomaly, isFalse);
      // 실제 0V는 기준 밖이다 — 없음과 0을 구분한다.
      expect(Telemetry.fromJson({...json(), 'batteryVoltage': 0}).hasAnomaly,
          isTrue);
    });

    test('전압 타일은 "미수신"·판정 안 함, 연료는 "미수신"', () {
      final s = _state(Telemetry.fromJson(json()));
      final battery =
          s.readings.singleWhere((r) => r.kind == MetricKind.battery);
      expect(battery.available, isFalse);
      expect(battery.valueText, DashboardViewState.missingText);
      expect(battery.valueText, '미수신');
      expect(battery.unit, '');
      expect(battery.over, isFalse);
      expect(s.overCount, 0);
      expect(s.readings.map((r) => r.kind), MetricKind.values,
          reason: '타일 자리는 그대로 둔다 — 레이아웃이 차량마다 흔들리지 않게');

      final fuel = s.extras.singleWhere((e) => e.label == '연료');
      expect(fuel.available, isFalse);
      expect(fuel.valueText, '미수신');
      expect(fuel.unit, '');
    });
  });
}
