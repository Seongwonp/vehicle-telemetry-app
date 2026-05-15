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

  bool get hasAnomaly =>
      engineTemp > 105 ||
      rpm > 6000 ||
      batteryVoltage < 11.5 ||
      batteryVoltage > 15.0 ||
      speed > 200 ||
      dtcCodes.isNotEmpty;
}
