import 'package:flutter/material.dart';

enum ReportCategory {
  vehicle('vehicle'),
  driver('driver'),
  traffic('traffic'),
  lostItem('lost_item'),
  safetySecurity('safety_security'),
  app('app'),
  miscellaneous('miscellaneous'),
  route('route');

  final String value;
  const ReportCategory(this.value);

  static ReportCategory fromString(String value) {
    return ReportCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReportCategory.miscellaneous,
    );
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
}

enum ReportStatus {
  open('open'),
  inReview('in_review'),
  resolved('resolved'),
  dismissed('dismissed'),
  closed('closed');

  final String value;
  const ReportStatus(this.value);

  static ReportStatus fromString(String value) {
    return ReportStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReportStatus.open,
    );
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

  Color get color {
    switch (this) {
      case ReportStatus.open:
        return Colors.blue;
      case ReportStatus.inReview:
        return Colors.orange;
      case ReportStatus.resolved:
        return Colors.green;
      case ReportStatus.dismissed:
        return Colors.grey;
      case ReportStatus.closed:
        return Colors.black54;
    }
  }
}

enum ReportSeverity {
  low('low'),
  medium('medium'),
  high('high');

  final String value;
  const ReportSeverity(this.value);

  static ReportSeverity fromString(String value) {
    return ReportSeverity.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReportSeverity.low,
    );
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

  Color get color {
    switch (this) {
      case ReportSeverity.low:
        return Colors.green;
      case ReportSeverity.medium:
        return Colors.orange;
      case ReportSeverity.high:
        return Colors.red;
    }
  }
}

class Report {
  final String id;
  final String reporterProfileId;
  final ReportCategory category;
  final ReportSeverity severity;
  final ReportStatus status;
  final String description;
  final String? attachmentId;
  final String? reportedEntityType;
  final String? reportedEntityId;
  final String? assignedToProfileId;
  final String? resolutionNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Additional fields for display
  String? reporterName;
  String? attachmentUrl;

  Report({
    required this.id,
    required this.reporterProfileId,
    required this.category,
    required this.severity,
    required this.status,
    required this.description,
    this.attachmentId,
    this.reportedEntityType,
    this.reportedEntityId,
    this.assignedToProfileId,
    this.resolutionNotes,
    required this.createdAt,
    required this.updatedAt,
    this.reporterName,
    this.attachmentUrl,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as String,
      reporterProfileId: json['reporter_profile_id'] as String,
      category: ReportCategory.fromString(json['category'] as String),
      severity: ReportSeverity.fromString(json['severity'] as String),
      status: ReportStatus.fromString(json['status'] as String),
      description: json['description'] as String,
      attachmentId: json['attachment_id'] as String?,
      reportedEntityType: json['reported_entity_type'] as String?,
      reportedEntityId: json['reported_entity_id'] as String?,
      assignedToProfileId: json['assigned_to_profile_id'] as String?,
      resolutionNotes: json['resolution_notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      reporterName: json['reporter_name'] as String?,
      attachmentUrl: json['attachment_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporter_profile_id': reporterProfileId,
      'category': category.value,
      'severity': severity.value,
      'status': status.value,
      'description': description,
      'attachment_id': attachmentId,
      'reported_entity_type': reportedEntityType,
      'reported_entity_id': reportedEntityId,
      'assigned_to_profile_id': assignedToProfileId,
      'resolution_notes': resolutionNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Report copyWith({
    String? id,
    String? reporterProfileId,
    ReportCategory? category,
    ReportSeverity? severity,
    ReportStatus? status,
    String? description,
    String? attachmentId,
    String? reportedEntityType,
    String? reportedEntityId,
    String? assignedToProfileId,
    String? resolutionNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? reporterName,
    String? attachmentUrl,
  }) {
    return Report(
      id: id ?? this.id,
      reporterProfileId: reporterProfileId ?? this.reporterProfileId,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      description: description ?? this.description,
      attachmentId: attachmentId ?? this.attachmentId,
      reportedEntityType: reportedEntityType ?? this.reportedEntityType,
      reportedEntityId: reportedEntityId ?? this.reportedEntityId,
      assignedToProfileId: assignedToProfileId ?? this.assignedToProfileId,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reporterName: reporterName ?? this.reporterName,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
    );
  }
}