class Anomaly {
  final String vehicleId;
  final String anomalyType;
  final String? field;
  final double? value;
  final String? threshold;
  final String severity;
  final String? detector;
  final DateTime detectedAt;

  Anomaly({
    required this.vehicleId,
    required this.anomalyType,
    this.field,
    this.value,
    this.threshold,
    required this.severity,
    this.detector,
    required this.detectedAt,
  });

  factory Anomaly.fromJson(Map<String, dynamic> json) {
    return Anomaly(
      vehicleId: json['vehicleId'] as String,
      anomalyType: json['anomalyType'] as String,
      field: json['field'] as String?,
      value: (json['value'] as num?)?.toDouble(),
      threshold: json['threshold'] as String?,
      severity: json['severity'] as String,
      detector: json['detector'] as String?,
      detectedAt: DateTime.parse(json['detectedAt'] as String),
    );
  }

  bool get isHigh => severity == 'HIGH';

  // 백엔드 AnomalyResponse엔 description 필드가 없다. threshold(예: "engine_temp > 105°C")가
  // 가장 설명에 가까운 필드라 이를 부가 설명으로 쓰고, 없으면 field/value 조합으로 대체한다.
  String get description {
    if (threshold != null && threshold!.isNotEmpty) return threshold!;
    if (field != null && value != null) return '$field = $value';
    return '';
  }
}
