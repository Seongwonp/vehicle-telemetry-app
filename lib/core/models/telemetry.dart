class Telemetry {
  final String vehicleId;
  final DateTime timestamp;
  final double speed;
  final int rpm;
  final double engineTemp;
  final double throttlePosition;
  final double fuelLevel;
  final double batteryVoltage;
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
    required this.fuelLevel,
    required this.batteryVoltage,
    this.lat,
    this.lng,
    required this.dtcCodes,
  });

  factory Telemetry.fromJson(Map<String, dynamic> json) {
    return Telemetry(
      vehicleId: json['vehicleId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      speed: (json['speed'] as num).toDouble(),
      rpm: (json['rpm'] as num).toInt(),
      engineTemp: (json['engineTemp'] as num).toDouble(),
      throttlePosition: (json['throttlePosition'] as num).toDouble(),
      fuelLevel: (json['fuelLevel'] as num).toDouble(),
      batteryVoltage: (json['batteryVoltage'] as num).toDouble(),
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
      engineTemp > 105 ||
      rpm > 6000 ||
      batteryVoltage < 11.5 ||
      batteryVoltage > 15.0 ||
      speed > 200 ||
      dtcCodes.isNotEmpty;
}
