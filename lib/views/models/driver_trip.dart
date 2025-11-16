class DriverTrip {
  final String id;
  final String routeCode;
  final String originName;
  final String destinationName;
  final String status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double fareAmount;
  final int passengersCount;
  final int? distanceMeters;

  DriverTrip({
    required this.id,
    required this.routeCode,
    required this.originName,
    required this.destinationName,
    required this.status,
    required this.startedAt,
    this.endedAt,
    required this.fareAmount,
    required this.passengersCount,
    this.distanceMeters,
  });

  factory DriverTrip.fromJson(Map<String, dynamic> json) {
    return DriverTrip(
      id: json['id'] as String,
      routeCode: json['route_code'] as String? ?? 'N/A',
      originName: json['origin_name'] as String? ?? 'Unknown',
      destinationName: json['destination_name'] as String? ?? 'Unknown',
      status: json['status'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] != null 
          ? DateTime.parse(json['ended_at'] as String) 
          : null,
      fareAmount: (json['fare_amount'] as num?)?.toDouble() ?? 0.0,
      passengersCount: json['passengers_count'] as int? ?? 0,
      distanceMeters: json['distance_meters'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'route_code': routeCode,
      'origin_name': originName,
      'destination_name': destinationName,
      'status': status,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'fare_amount': fareAmount,
      'passengers_count': passengersCount,
      'distance_meters': distanceMeters,
    };
  }
}