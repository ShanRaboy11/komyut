// lib/models/transaction_model.dart

class TransactionModel {
  final String id;
  final String? transactionNumber;
  final String? walletId;
  final String? initiatedByProfileId;
  final String type;
  final double amount;
  final double fee;
  final String status;
  final String? relatedTripId;
  final String? externalReference;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? processedAt;

  // Additional fields from joins
  final String? initiatorName;
  final String? driverName;
  final String? passengerName;
  final String? routeCode;
  final String? plateNumber;
  final String? operatorName;
  final int? numPassengers;

  TransactionModel({
    required this.id,
    this.transactionNumber,
    this.walletId,
    this.initiatedByProfileId,
    required this.type,
    required this.amount,
    this.fee = 0.0,
    required this.status,
    this.relatedTripId,
    this.externalReference,
    this.metadata,
    required this.createdAt,
    this.processedAt,
    this.initiatorName,
    this.driverName,
    this.passengerName,
    this.routeCode,
    this.plateNumber,
    this.operatorName,
    this.numPassengers,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      transactionNumber: json['transaction_number'] as String?,
      walletId: json['wallet_id'] as String?,
      initiatedByProfileId: json['initiated_by_profile_id'] as String?,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      fee: json['fee'] != null ? (json['fee'] as num).toDouble() : 0.0,
      status: json['status'] as String? ?? 'pending',
      relatedTripId: json['related_trip_id'] as String?,
      externalReference: json['external_reference'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'] as String)
          : null,
      initiatorName: json['initiator_name'] as String?,
      driverName: json['driver_name'] as String?,
      passengerName: json['passenger_name'] as String?,
      routeCode: json['route_code'] as String?,
      plateNumber: json['plate_number'] as String?,
      operatorName: json['operator_name'] as String?,
      numPassengers: json['num_passengers'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_number': transactionNumber,
      'wallet_id': walletId,
      'initiated_by_profile_id': initiatedByProfileId,
      'type': type,
      'amount': amount,
      'fee': fee,
      'status': status,
      'related_trip_id': relatedTripId,
      'external_reference': externalReference,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
      'initiator_name': initiatorName,
      'driver_name': driverName,
      'passenger_name': passengerName,
      'route_code': routeCode,
      'plate_number': plateNumber,
      'operator_name': operatorName,
      'num_passengers': numPassengers,
    };
  }

  // Helper method to convert to the format expected by the UI
  Map<String, dynamic> toDisplayMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'created_at': createdAt.toIso8601String(),
      'transaction_number': transactionNumber ?? id,
      'metadata': metadata,
      'related_trip_id': relatedTripId,
      'status': status,
      'passenger': passengerName ?? initiatorName,
      'driver': driverName,
      'route_code': routeCode,
      'plate_number': plateNumber,
      'operator': operatorName,
      'num_passengers': numPassengers,
    };
  }
}