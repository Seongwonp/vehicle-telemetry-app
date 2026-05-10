class Anomaly {
  final String vehicleId;
  final String anomalyType;
  final String description;
  final String severity;
  final DateTime detectedAt;

  Anomaly({
    required this.vehicleId,
    required this.anomalyType,
    required this.description,
    required this.severity,
    required this.detectedAt,
  });

  factory Anomaly.fromJson(Map<String, dynamic> json) {
    return Anomaly(
      vehicleId: json['vehicleId'] as String,
      anomalyType: json['anomalyType'] as String,
      description: json['description'] as String,
      severity: json['severity'] as String,
      detectedAt: DateTime.parse(json['detectedAt'] as String),
    );
  }

  bool get isHigh => severity == 'HIGH';
}
