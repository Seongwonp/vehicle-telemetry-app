class Vehicle {
  final String vehicleId;
  final String name;
  final String owner;
  final bool active;
  final DateTime registeredAt;

  Vehicle({
    required this.vehicleId,
    required this.name,
    required this.owner,
    required this.active,
    required this.registeredAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      vehicleId: json['vehicleId'] as String,
      name: json['name'] as String,
      owner: json['owner'] as String,
      active: json['active'] as bool? ?? true,
      registeredAt: DateTime.parse(json['registeredAt'] as String),
    );
  }
}
