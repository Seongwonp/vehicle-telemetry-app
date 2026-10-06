import 'telemetry_limits.dart';

class Telemetry {
  final String vehicleId;
  final DateTime timestamp;
  final double speed;
  final double rpm;
  final double engineTemp;
  final double throttlePosition;

  /// 연료량(PID 012F). **null = 이 레코드에 값이 없다**(차량 미지원 또는 미수신) — 0이 아니다.
  ///
  /// 백엔드 계약에서 선택 필드다(백엔드 ADR-030). 저장 시 필드를 쓰지 않으므로 응답에서도 null로 온다.
  final double? fuelLevel;

  /// 제어 모듈 전압(PID 0142). null이면 값 없음 — **기준(11.5–15V) 판정을 하지 않는다.**
  /// 0으로 보면 "기준 밖"으로 빨갛게 뜬다.
  final double? batteryVoltage;
  final double? lat;
  final double? lng;
  final List<String> dtcCodes;

  Telemetry({
    required this.vehicleId,
    required this.timestamp,
    required this.speed,
    required this.rpm,
    required this.engineTemp,
    required this.throttlePosition,
    this.fuelLevel,
    this.batteryVoltage,
    this.lat,
    this.lng,
    required this.dtcCodes,
  });

  factory Telemetry.fromJson(Map<String, dynamic> json) {
    return Telemetry(
      vehicleId: json['vehicleId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      speed: (json['speed'] as num).toDouble(),
      rpm: (json['rpm'] as num).toDouble(),
      engineTemp: (json['engineTemp'] as num).toDouble(),
      throttlePosition: (json['throttlePosition'] as num).toDouble(),
      // 선택 필드 — 키가 없거나 null이면 null. 0으로 채우지 않는다.
      fuelLevel: (json['fuelLevel'] as num?)?.toDouble(),
      batteryVoltage: (json['batteryVoltage'] as num?)?.toDouble(),
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      dtcCodes: (json['dtcCodes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  /// 실시간 스트림처럼 개별 레코드 하나의 실패가 전체 구독을 깨면 안 되는 곳에서
  /// 사용한다. REST 응답은 기존 [fromJson]을 유지해 잘못된 계약을 즉시 드러낸다.
  static Telemetry? tryFromJson(
    Map<String, dynamic> json, {
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    try {
      return Telemetry.fromJson(json);
    } catch (error, stackTrace) {
      onError?.call(error, stackTrace);
      return null;
    }
  }

  bool get hasAnomaly =>
      TelemetryLimits.engineTempOver(engineTemp) ||
      TelemetryLimits.rpmOver(rpm) ||
      // 전압이 없으면 판정하지 않는다 — 감지기(rules.py)도 같은 규칙이다.
      (batteryVoltage != null && TelemetryLimits.batteryOut(batteryVoltage!)) ||
      TelemetryLimits.speedOver(speed) ||
      dtcCodes.isNotEmpty;
}
