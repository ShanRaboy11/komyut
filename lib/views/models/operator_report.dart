import 'report.dart';

class OperatorReport {
  final Report report;
  final ReporterInfo? reporter;
  final DriverInfo? assignedDriver;
  final AttachmentInfo? attachment;

  OperatorReport({
    required this.report,
    this.reporter,
    this.assignedDriver,
    this.attachment,
  });

  factory OperatorReport.fromJson(Map<String, dynamic> json) {
    return OperatorReport(
      report: Report.fromJson(json),
      reporter: json['reporter'] != null 
          ? ReporterInfo.fromJson(json['reporter'])
          : null,
      assignedDriver: json['assigned_driver'] != null
          ? DriverInfo.fromJson(json['assigned_driver'])
          : null,
      attachment: json['attachment'] != null
          ? AttachmentInfo.fromJson(json['attachment'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ...report.toJson(),
      if (reporter != null) 'reporter': reporter!.toJson(),
      if (assignedDriver != null) 'assigned_driver': assignedDriver!.toJson(),
      if (attachment != null) 'attachment': attachment!.toJson(),
    };
  }
}

class ReporterInfo {
  final String id;
  final String firstName;
  final String lastName;
  final String role;

  ReporterInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.role,
  });

  String get fullName => '$firstName $lastName';

  factory ReporterInfo.fromJson(Map<String, dynamic> json) {
    return ReporterInfo(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      role: json['role'] ?? 'commuter',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
    };
  }
}

class DriverInfo {
  final String id;
  final String firstName;
  final String lastName;
  final String role;
  final DriverDetails? driverDetails;

  DriverInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.driverDetails,
  });

  String get fullName => '$firstName $lastName';

  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    // Handle drivers field which could be a Map or List
    DriverDetails? details;
    if (json['drivers'] != null) {
      if (json['drivers'] is Map) {
        details = DriverDetails.fromJson(json['drivers']);
      } else if (json['drivers'] is List && (json['drivers'] as List).isNotEmpty) {
        details = DriverDetails.fromJson((json['drivers'] as List).first);
      }
    }

    return DriverInfo(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      role: json['role'] ?? 'driver',
      driverDetails: details,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
      if (driverDetails != null) 'drivers': driverDetails!.toJson(),
    };
  }
}

class DriverDetails {
  final String id;
  final String? licenseNumber;
  final String? vehiclePlate;
  final String? routeCode;
  final String? operatorId;

  DriverDetails({
    required this.id,
    this.licenseNumber,
    this.vehiclePlate,
    this.routeCode,
    this.operatorId,
  });

  factory DriverDetails.fromJson(Map<String, dynamic> json) {
    return DriverDetails(
      id: json['id'],
      licenseNumber: json['license_number'],
      vehiclePlate: json['vehicle_plate'],
      // route_code may come directly or via nested relation 'routes'
      routeCode: json['route_code'] ?? (json['routes'] is Map ? json['routes']['code'] : null),
      operatorId: json['operator_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (licenseNumber != null) 'license_number': licenseNumber,
      if (vehiclePlate != null) 'vehicle_plate': vehiclePlate,
      if (routeCode != null) 'route_code': routeCode,
      if (operatorId != null) 'operator_id': operatorId,
    };
  }
}

class AttachmentInfo {
  final String id;
  final String url;
  final String? contentType;

  AttachmentInfo({
    required this.id,
    required this.url,
    this.contentType,
  });

  bool get isImage => contentType?.startsWith('image/') ?? false;
  bool get isPdf => contentType == 'application/pdf';

  factory AttachmentInfo.fromJson(Map<String, dynamic> json) {
    return AttachmentInfo(
      id: json['id'],
      url: json['url'],
      contentType: json['content_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      if (contentType != null) 'content_type': contentType,
    };
  }
}