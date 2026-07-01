import 'package:flutter_test/flutter_test.dart';
import 'package:telemetrix/core/models/anomaly.dart';

void main() {
  group('Anomaly.fromJson', () {
    test('백엔드 AnomalyResponse 실제 응답 형태를 크래시 없이 파싱한다', () {
      // com.telemetry.dto.response.AnomalyResponse 실제 필드 — description은 없음
      final json = {
        'id': 1,
        'vehicleId': 'SIM-001',
        'anomalyType': '엔진 과열',
        'field': 'engine_temp',
        'value': 108.5,
        'threshold': 'engine_temp > 105°C',
        'severity': 'HIGH',
        'detector': 'RULE',
        'vehicleTimestamp': '2026-05-09T10:00:00Z',
        'detectedAt': '2026-05-09T10:00:01Z',
      };

      final anomaly = Anomaly.fromJson(json);

      expect(anomaly.vehicleId, 'SIM-001');
      expect(anomaly.anomalyType, '엔진 과열');
      expect(anomaly.isHigh, isTrue);
      expect(anomaly.description, 'engine_temp > 105°C');
    });

    test('threshold가 없으면 field/value 조합으로 설명을 대체한다', () {
      final json = {
        'vehicleId': 'SIM-001',
        'anomalyType': 'DTC 코드 감지',
        'field': 'dtc_codes',
        'value': 1.0,
        'severity': 'HIGH',
        'detectedAt': '2026-05-09T10:00:01Z',
      };

      final anomaly = Anomaly.fromJson(json);

      expect(anomaly.description, 'dtc_codes = 1.0');
    });

    test('threshold, field, value 모두 없으면 빈 문자열을 반환한다', () {
      final json = {
        'vehicleId': 'SIM-001',
        'anomalyType': '알 수 없음',
        'severity': 'MEDIUM',
        'detectedAt': '2026-05-09T10:00:01Z',
      };

      final anomaly = Anomaly.fromJson(json);

      expect(anomaly.description, '');
    });
  });
}
