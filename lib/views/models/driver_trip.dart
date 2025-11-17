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
  final String? passengerName;

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
    this.passengerName,
  });

  factory DriverTrip.fromJson(Map<String, dynamic> json) {
    String? _passengerName;
    try {
      if (json['passenger_name'] != null) {
        _passengerName = json['passenger_name'] as String?;
      } else if (json['passenger'] != null && json['passenger'] is Map) {
        _passengerName = (json['passenger'] as Map)['name'] as String?;
      } else if (json['passengers'] != null && json['passengers'] is List && (json['passengers'] as List).isNotEmpty) {
        final first = (json['passengers'] as List).first;
        if (first != null && first is Map && first['name'] != null) {
          _passengerName = first['name'] as String?;
        }
      }
    } catch (_) {
      _passengerName = null;
    }

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
      passengerName: _passengerName,
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
      'passenger_name': passengerName,
    };
  }
}