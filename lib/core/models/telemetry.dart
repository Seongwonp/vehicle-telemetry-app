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
    final gps = json['gps'] as Map<String, dynamic>?;
    return Telemetry(
      vehicleId: json['vehicle_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      speed: (json['speed'] as num).toDouble(),
      rpm: json['rpm'] as int,
      engineTemp: (json['engine_temp'] as num).toDouble(),
      throttlePosition: (json['throttle_position'] as num).toDouble(),
      fuelLevel: (json['fuel_level'] as num).toDouble(),
      batteryVoltage: (json['battery_voltage'] as num).toDouble(),
      lat: gps != null ? (gps['lat'] as num?)?.toDouble() : null,
      lng: gps != null ? (gps['lng'] as num?)?.toDouble() : null,
      dtcCodes: (json['dtc_codes'] as List<dynamic>?)
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
