class Trip {
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final double distanceKm;
  final double avgSpeedKmh;
  final double maxSpeedKmh;
  final int pointCount;

  Trip({
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.distanceKm,
    required this.avgSpeedKmh,
    required this.maxSpeedKmh,
    required this.pointCount,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      distanceKm: (json['distanceKm'] as num).toDouble(),
      avgSpeedKmh: (json['avgSpeedKmh'] as num).toDouble(),
      maxSpeedKmh: (json['maxSpeedKmh'] as num).toDouble(),
      pointCount: (json['pointCount'] as num).toInt(),
    );
  }
}
