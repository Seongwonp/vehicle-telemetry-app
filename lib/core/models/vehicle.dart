class Vehicle {
  final String vehicleId;
  final String name;
  final String owner;
  final bool active;
  final DateTime registeredAt;

  // fleet 목록 화면에서 차량마다 대시보드에 들어가지 않고도 상태를 비교할 수
  // 있게 서버가 함께 내려주는 요약 필드 — 텔레메트리 이력이 없으면 null.
  final DateTime? lastSeenAt;
  final double? latestSpeed;
  final int highAnomalyCount;

  Vehicle({
    required this.vehicleId,
    required this.name,
    required this.owner,
    required this.active,
    required this.registeredAt,
    this.lastSeenAt,
    this.latestSpeed,
    this.highAnomalyCount = 0,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      vehicleId: json['vehicleId'] as String,
      name: json['name'] as String,
      owner: json['owner'] as String,
      active: json['active'] as bool? ?? true,
      registeredAt: DateTime.parse(json['registeredAt'] as String),
      lastSeenAt: json['lastSeenAt'] != null
          ? DateTime.parse(json['lastSeenAt'] as String)
          : null,
      latestSpeed: (json['latestSpeed'] as num?)?.toDouble(),
      highAnomalyCount: (json['highAnomalyCount'] as num?)?.toInt() ?? 0,
    );
  }
}
