// lib/models/report_model.dart

class Report {
  final String id;
  final String reporterProfileId;
  final String? reporterName;
  final String? reporterRole;
  final String? reportedEntityType;
  final String? reportedEntityId;
  final ReportCategory category;
  final ReportSeverity severity;
  final ReportStatus status;
  final String description;
  final String? attachmentId;
  final String? attachmentUrl;
  final String? assignedToProfileId;
  final String? resolutionNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Report({
    required this.id,
    required this.reporterProfileId,
    this.reporterName,
    this.reporterRole,
    this.reportedEntityType,
    this.reportedEntityId,
    required this.category,
    required this.severity,
    required this.status,
    required this.description,
    this.attachmentId,
    this.attachmentUrl,
    this.assignedToProfileId,
    this.resolutionNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as String,
      reporterProfileId: json['reporter_profile_id'] as String,
      reporterName: json['reporter_name'] as String?,
      reporterRole: json['reporter_role'] as String?,
      reportedEntityType: json['reported_entity_type'] as String?,
      reportedEntityId: json['reported_entity_id'] as String?,
      category: ReportCategory.fromString(json['category'] as String),
      severity: ReportSeverity.fromString(json['severity'] as String),
      status: ReportStatus.fromString(json['status'] as String),
      description: json['description'] as String? ?? '',
      attachmentId: json['attachment_id'] as String?,
      attachmentUrl: json['attachment_url'] as String?,
      assignedToProfileId: json['assigned_to_profile_id'] as String?,
      resolutionNotes: json['resolution_notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporter_profile_id': reporterProfileId,
      'reporter_name': reporterName,
      'reporter_role': reporterRole,
      'reported_entity_type': reportedEntityType,
      'reported_entity_id': reportedEntityId,
      'category': category.value,
      'severity': severity.value,
      'status': status.value,
      'description': description,
      'attachment_id': attachmentId,
      'attachment_url': attachmentUrl,
      'assigned_to_profile_id': assignedToProfileId,
      'resolution_notes': resolutionNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Report copyWith({
    String? id,
    String? reporterProfileId,
    String? reporterName,
    String? reporterRole,
    String? reportedEntityType,
    String? reportedEntityId,
    ReportCategory? category,
    ReportSeverity? severity,
    ReportStatus? status,
    String? description,
    String? attachmentId,
    String? attachmentUrl,
    String? assignedToProfileId,
    String? resolutionNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Report(
      id: id ?? this.id,
      reporterProfileId: reporterProfileId ?? this.reporterProfileId,
      reporterName: reporterName ?? this.reporterName,
      reporterRole: reporterRole ?? this.reporterRole,
      reportedEntityType: reportedEntityType ?? this.reportedEntityType,
      reportedEntityId: reportedEntityId ?? this.reportedEntityId,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      description: description ?? this.description,
      attachmentId: attachmentId ?? this.attachmentId,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      assignedToProfileId: assignedToProfileId ?? this.assignedToProfileId,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  List<String> get tags {
    List<String> tagList = [category.displayName];
    if (reportedEntityType != null) {
      tagList.add(reportedEntityType!);
    }
    return tagList;
  }
}

enum ReportCategory {
  vehicle,
  driver,
  traffic,
  lostItem,
  safetySecurity,
  app,
  miscellaneous,
  route;

  String get value {
    switch (this) {
      case ReportCategory.vehicle:
        return 'vehicle';
      case ReportCategory.driver:
        return 'driver';
      case ReportCategory.traffic:
        return 'traffic';
      case ReportCategory.lostItem:
        return 'lost_item';
      case ReportCategory.safetySecurity:
        return 'safety_security';
      case ReportCategory.app:
        return 'app';
      case ReportCategory.miscellaneous:
        return 'miscellaneous';
      case ReportCategory.route:
        return 'route';
    }
  }

  String get displayName {
    switch (this) {
      case ReportCategory.vehicle:
        return 'Vehicle';
      case ReportCategory.driver:
        return 'Driver';
      case ReportCategory.traffic:
        return 'Traffic';
      case ReportCategory.lostItem:
        return 'Lost Item';
      case ReportCategory.safetySecurity:
        return 'Safety';
      case ReportCategory.app:
        return 'App';
      case ReportCategory.miscellaneous:
        return 'Other';
      case ReportCategory.route:
        return 'Route';
    }
  }

  static ReportCategory fromString(String value) {
    switch (value.toLowerCase()) {
      case 'vehicle':
        return ReportCategory.vehicle;
      case 'driver':
        return ReportCategory.driver;
      case 'traffic':
        return ReportCategory.traffic;
      case 'lost_item':
        return ReportCategory.lostItem;
      case 'safety_security':
        return ReportCategory.safetySecurity;
      case 'app':
        return ReportCategory.app;
      case 'miscellaneous':
        return ReportCategory.miscellaneous;
      case 'route':
        return ReportCategory.route;
      default:
        return ReportCategory.miscellaneous;
    }
  }
}

enum ReportSeverity {
  low,
  medium,
  high;

  String get value {
    switch (this) {
      case ReportSeverity.low:
        return 'low';
      case ReportSeverity.medium:
        return 'medium';
      case ReportSeverity.high:
        return 'high';
    }
  }

  String get displayName {
    switch (this) {
      case ReportSeverity.low:
        return 'Low';
      case ReportSeverity.medium:
        return 'Medium';
      case ReportSeverity.high:
        return 'High';
    }
  }

  static ReportSeverity fromString(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return ReportSeverity.low;
      case 'medium':
        return ReportSeverity.medium;
      case 'high':
        return ReportSeverity.high;
      default:
        return ReportSeverity.low;
    }
  }
}

enum ReportStatus {
  open,
  inReview,
  resolved,
  dismissed,
  closed;

  String get value {
    switch (this) {
      case ReportStatus.open:
        return 'open';
      case ReportStatus.inReview:
        return 'in_review';
      case ReportStatus.resolved:
        return 'resolved';
      case ReportStatus.dismissed:
        return 'dismissed';
      case ReportStatus.closed:
        return 'closed';
    }
  }

  String get displayName {
    switch (this) {
      case ReportStatus.open:
        return 'Open';
      case ReportStatus.inReview:
        return 'In Review';
      case ReportStatus.resolved:
        return 'Resolved';
      case ReportStatus.dismissed:
        return 'Dismissed';
      case ReportStatus.closed:
        return 'Closed';
    }
  }

  static ReportStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'open':
        return ReportStatus.open;
      case 'in_review':
        return ReportStatus.inReview;
      case 'resolved':
        return ReportStatus.resolved;
      case 'dismissed':
        return ReportStatus.dismissed;
      case 'closed':
        return ReportStatus.closed;
      default:
        return ReportStatus.open;
    }
  }
}