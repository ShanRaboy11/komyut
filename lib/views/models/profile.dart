class ProfileModel {
  final String id;
  final String userId;
  final String role;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? address;
  final int? age;
  final String? sex;
  final String? email;
  
  // Role-specific data
  final CommuterData? commuterData;
  final DriverData? driverData;
  final OperatorData? operatorData;

  ProfileModel({
    required this.id,
    required this.userId,
    required this.role,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.address,
    this.age,
    this.sex,
    this.email,
    this.commuterData,
    this.driverData,
    this.operatorData,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final role = json['role'] as String;
    final roleData = json['role_data'] as Map<String, dynamic>?;

    return ProfileModel(
      id: json['id'],
      userId: json['user_id'],
      role: role,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phone: json['phone'],
      address: json['address'],
      age: json['age'],
      sex: json['sex'],
      email: json['email'],
      commuterData: role == 'commuter' && roleData != null
          ? CommuterData.fromJson(roleData)
          : null,
      driverData: role == 'driver' && roleData != null
          ? DriverData.fromJson(roleData)
          : null,
      operatorData: role == 'operator' && roleData != null
          ? OperatorData.fromJson(roleData)
          : null,
    );
  }

  String get fullName => '$firstName $lastName';
}

class CommuterData {
  final String id;
  final String category;
  final bool idVerified;
  final double wheelTokens;

  CommuterData({
    required this.id,
    required this.category,
    required this.idVerified,
    required this.wheelTokens,
  });

  factory CommuterData.fromJson(Map<String, dynamic> json) {
    return CommuterData(
      id: json['id'],
      category: json['category'] ?? 'regular',
      idVerified: json['id_verified'] ?? false,
      wheelTokens: (json['wheel_tokens'] ?? 0).toDouble(),
    );
  }
}

class DriverData {
  final String id;
  final String licenseNumber;
  final String? licenseImageUrl;
  final String? operatorName;
  final String? vehiclePlate;
  final String? routeCode;

  DriverData({
    required this.id,
    required this.licenseNumber,
    this.licenseImageUrl,
    this.operatorName,
    this.vehiclePlate,
    this.routeCode,
  });

  factory DriverData.fromJson(Map<String, dynamic> json) {
    return DriverData(
      id: json['id'],
      licenseNumber: json['license_number'] ?? '',
      licenseImageUrl: json['license_image_url'],
      operatorName: json['operator_name'] ?? json['operators']?['company_name'],
      vehiclePlate: json['vehicle_plate'],
      routeCode: json['route_code'],
    );
  }
}

class OperatorData {
  final String id;
  final String? companyName;
  final String? companyAddress;
  final String? contactEmail;
  final String? contactPhone;

  OperatorData({
    required this.id,
    this.companyName,
    this.companyAddress,
    this.contactEmail,
    this.contactPhone,
  });

  factory OperatorData.fromJson(Map<String, dynamic> json) {
    return OperatorData(
      id: json['id'],
      companyName: json['company_name'],
      companyAddress: json['company_address'],
      contactEmail: json['contact_email'],
      contactPhone: json['contact_phone'],
    );
  }
}