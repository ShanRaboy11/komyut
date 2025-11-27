class OperatorDriver {
  final String id;
  final String profileId;
  final String firstName;
  final String lastName;
  final String licenseNumber;
  final String? licenseImageUrl;
  final bool status;
  final String? vehiclePlate;
  final String? routeCode;
  final String? routeId;
  final String? routeName;
  final String? puvType;
  final bool active;
  final DateTime createdAt;

  OperatorDriver({
    required this.id,
    required this.profileId,
    required this.firstName,
    required this.lastName,
    required this.licenseNumber,
    this.licenseImageUrl,
    required this.status,
    this.vehiclePlate,
    this.routeCode,
    this.routeId,
    this.routeName,
    this.puvType,
    required this.active,
    required this.createdAt,
  });

  factory OperatorDriver.fromJson(Map<String, dynamic> json) {
    // Handle nested profile data
    final profile = json['profiles'] as Map<String, dynamic>?;
    final route = json['routes'] as Map<String, dynamic>?;

    return OperatorDriver(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      firstName: profile?['first_name'] as String? ?? '',
      lastName: profile?['last_name'] as String? ?? '',
      licenseNumber: json['license_number'] as String? ?? '',
      licenseImageUrl: json['license_image_url'] as String?,
      status: json['status'] as bool? ?? false,
      vehiclePlate: json['vehicle_plate'] as String?,
      routeCode: json['route_code'] as String? ?? (route?['code'] as String?),
      routeId: json['route_id'] as String? ?? (route?['id'] as String?),
      routeName: route?['name'] as String?,
      puvType: json['puv_type'] as String?,
      active: json['active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'first_name': firstName,
      'last_name': lastName,
      'license_number': licenseNumber,
      'license_image_url': licenseImageUrl,
      'status': status,
      'vehicle_plate': vehiclePlate,
      'route_id': routeId,
      'route_code': routeCode,
      'route_name': routeName,
      'puv_type': puvType,
      'active': active,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class OperatorInfo {
  final String id;
  final String profileId;
  final String? companyName;
  final String? companyAddress;
  final String? contactEmail;
  final String? contactPhone;
  final int driverCount;

  OperatorInfo({
    required this.id,
    required this.profileId,
    this.companyName,
    this.companyAddress,
    this.contactEmail,
    this.contactPhone,
    required this.driverCount,
  });

  factory OperatorInfo.fromJson(Map<String, dynamic> json) {
    return OperatorInfo(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      companyName: json['company_name'] as String?,
      companyAddress: json['company_address'] as String?,
      contactEmail: json['contact_email'] as String?,
      contactPhone: json['contact_phone'] as String?,
      driverCount: json['driver_count'] as int? ?? 0,
    );
  }
}