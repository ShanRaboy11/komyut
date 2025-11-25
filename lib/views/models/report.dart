class Report {
  final String? id;
  final String? reporterProfileId;
  final String? reportedEntityType;
  final String? reportedEntityId;
  final ReportCategory category;
  final ReportSeverity severity;
  final ReportStatus status;
  final String description;
  final String? attachmentId;
  final String? assignedToProfileId;
  final String? resolutionNotes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Report({
    this.id,
    this.reporterProfileId,
    this.reportedEntityType,
    this.reportedEntityId,
    required this.category,
    required this.severity,
    this.status = ReportStatus.open,
    required this.description,
    this.attachmentId,
    this.assignedToProfileId,
    this.resolutionNotes,
    this.createdAt,
    this.updatedAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'],
      reporterProfileId: json['reporter_profile_id'],
      reportedEntityType: json['reported_entity_type'],
      reportedEntityId: json['reported_entity_id'],
      category: ReportCategory.fromString(json['category']),
      severity: ReportSeverity.fromString(json['severity']),
      status: ReportStatus.fromString(json['status'] ?? 'open'),
      description: json['description'] ?? '',
      attachmentId: json['attachment_id'],
      assignedToProfileId: json['assigned_to_profile_id'],
      resolutionNotes: json['resolution_notes'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (reporterProfileId != null) 'reporter_profile_id': reporterProfileId,
      if (reportedEntityType != null) 'reported_entity_type': reportedEntityType,
      if (reportedEntityId != null) 'reported_entity_id': reportedEntityId,
      'category': category.value,
      'severity': severity.value,
      'status': status.value,
      'description': description,
      if (attachmentId != null) 'attachment_id': attachmentId,
      if (assignedToProfileId != null) 'assigned_to_profile_id': assignedToProfileId,
      if (resolutionNotes != null) 'resolution_notes': resolutionNotes,
    };
  }

  Report copyWith({
    String? id,
    String? reporterProfileId,
    String? reportedEntityType,
    String? reportedEntityId,
    ReportCategory? category,
    ReportSeverity? severity,
    ReportStatus? status,
    String? description,
    String? attachmentId,
    String? assignedToProfileId,
    String? resolutionNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Report(
      id: id ?? this.id,
      reporterProfileId: reporterProfileId ?? this.reporterProfileId,
      reportedEntityType: reportedEntityType ?? this.reportedEntityType,
      reportedEntityId: reportedEntityId ?? this.reportedEntityId,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      description: description ?? this.description,
      attachmentId: attachmentId ?? this.attachmentId,
      assignedToProfileId: assignedToProfileId ?? this.assignedToProfileId,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
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
        return 'Safety & Security';
      case ReportCategory.app:
        return 'App';
      case ReportCategory.miscellaneous:
        return 'Miscellaneous';
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

  static ReportCategory fromDisplayName(String displayName) {
    switch (displayName) {
      case 'Vehicle':
        return ReportCategory.vehicle;
      case 'Driver':
        return ReportCategory.driver;
      case 'Traffic':
        return ReportCategory.traffic;
      case 'Lost Item':
        return ReportCategory.lostItem;
      case 'Safety & Security':
        return ReportCategory.safetySecurity;
      case 'App':
        return ReportCategory.app;
      case 'Miscellaneous':
        return ReportCategory.miscellaneous;
      case 'Route':
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
        return ReportSeverity.medium;
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