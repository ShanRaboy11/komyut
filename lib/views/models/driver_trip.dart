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
  final String? passengerFirstName;
  final String? passengerLastName;

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
    this.passengerFirstName,
    this.passengerLastName,
  });

  /// Get full passenger name
  String get passengerName {
    if (passengerFirstName != null && passengerLastName != null) {
      return '$passengerFirstName $passengerLastName';
    } else if (passengerFirstName != null) {
      return passengerFirstName!;
    } else if (passengerLastName != null) {
      return passengerLastName!;
    }
    return 'Passenger';
  }

  /// Get formatted distance
  String get formattedDistance {
    if (distanceMeters == null) return 'N/A';
    final km = distanceMeters! / 1000.0;
    return '${km.toStringAsFixed(2)} km';
  }

  /// Get formatted fare
  String get formattedFare {
    return '₱${fareAmount.toStringAsFixed(2)}';
  }

  factory DriverTrip.fromJson(Map<String, dynamic> json) {
    // Parse passenger data from JOIN
    String? firstName;
    String? lastName;

    // PRIORITY 1: Check if service passed combined 'passenger_name'
    if (json['passenger_name'] != null && json['passenger_name'] is String) {
      final fullName = (json['passenger_name'] as String).trim();
      if (fullName.isNotEmpty && fullName != 'Passenger') {
        // Split the full name into first and last name
        final nameParts = fullName.split(' ');
        if (nameParts.length >= 2) {
          firstName = nameParts.first;
          lastName = nameParts.sublist(1).join(' ');
        } else if (nameParts.length == 1) {
          firstName = nameParts.first;
        }
      }
    }

    // PRIORITY 2: Try to get passenger data from the 'creator_profile' object (from JOIN)
    if (firstName == null && lastName == null) {
      if (json['creator_profile'] != null && json['creator_profile'] is Map) {
        final profile = json['creator_profile'] as Map<String, dynamic>;
        firstName = profile['first_name'] as String?;
        lastName = profile['last_name'] as String?;
      }
    }

    // PRIORITY 3: Try to get passenger data from the 'passenger' object (from JOIN)
    if (firstName == null && lastName == null) {
      if (json['passenger'] != null && json['passenger'] is Map) {
        final passenger = json['passenger'] as Map<String, dynamic>;
        firstName = passenger['first_name'] as String?;
        lastName = passenger['last_name'] as String?;
      }
    }
    
    // PRIORITY 4: Fallback to direct fields if they exist
    firstName ??= json['passenger_first_name'] as String?;
    lastName ??= json['passenger_last_name'] as String?;

    // Debug logging
    if (firstName != null || lastName != null) {
      print('🔍 DriverTrip.fromJson - Passenger: $firstName $lastName');
    }

    return DriverTrip(
      id: json['id'] as String,
      routeCode: json['route_code'] as String? ?? 
                 (json['routes'] != null && json['routes'] is Map 
                   ? (json['routes'] as Map)['code'] as String? 
                   : null) ?? 
                 'N/A',
      originName: json['origin_name'] as String? ?? 
                  (json['origin_stop'] != null && json['origin_stop'] is Map 
                    ? (json['origin_stop'] as Map)['name'] as String? 
                    : null) ?? 
                  'Unknown',
      destinationName: json['destination_name'] as String? ?? 
                       (json['destination_stop'] != null && json['destination_stop'] is Map 
                         ? (json['destination_stop'] as Map)['name'] as String? 
                         : null) ?? 
                       'Unknown',
      status: json['status'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] != null 
          ? DateTime.parse(json['ended_at'] as String) 
          : null,
      fareAmount: (json['fare_amount'] as num?)?.toDouble() ?? 0.0,
      passengersCount: json['passengers_count'] as int? ?? 0,
      distanceMeters: json['distance_meters'] as int?,
      passengerFirstName: firstName,
      passengerLastName: lastName,
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
      'passenger_first_name': passengerFirstName,
      'passenger_last_name': passengerLastName,
      'passenger_name': passengerName,
    };
  }

  /// Create a copy with updated fields
  DriverTrip copyWith({
    String? id,
    String? routeCode,
    String? originName,
    String? destinationName,
    String? status,
    DateTime? startedAt,
    DateTime? endedAt,
    double? fareAmount,
    int? passengersCount,
    int? distanceMeters,
    String? passengerFirstName,
    String? passengerLastName,
  }) {
    return DriverTrip(
      id: id ?? this.id,
      routeCode: routeCode ?? this.routeCode,
      originName: originName ?? this.originName,
      destinationName: destinationName ?? this.destinationName,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      fareAmount: fareAmount ?? this.fareAmount,
      passengersCount: passengersCount ?? this.passengersCount,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      passengerFirstName: passengerFirstName ?? this.passengerFirstName,
      passengerLastName: passengerLastName ?? this.passengerLastName,
    );
  }
}