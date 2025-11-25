// lib/services/transaction_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transactions.dart';

class TransactionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch transactions with enhanced details (joins with related tables)
  Future<List<TransactionModel>> fetchTransactions({
    String? type,
    int limit = 200,
  }) async {
    try {
      // Create the query with select and ordering
      var query = _supabase
          .from('transactions')
          .select('''
            id,
            transaction_number,
            wallet_id,
            initiated_by_profile_id,
            type,
            amount,
            fee,
            status,
            related_trip_id,
            external_reference,
            metadata,
            created_at,
            processed_at,
            initiator:profiles!transactions_initiated_by_profile_id_fkey(first_name, last_name),
            trip:trips(
              driver_id,
              route_id,
              passengers_count,
              driver:drivers(
                profile:profiles(first_name, last_name),
                vehicle_plate,
                operator_name
              ),
              route:routes(code)
            )
          ''')
          .order('created_at', ascending: false);

      // Apply ordering on server then fetch. We'll apply type filtering and limit client-side
      query = query.order('created_at', ascending: false);

      final response = await query;
      List<dynamic> data = response as List;

      // Client-side filter by type if provided
      if (type != null && type.isNotEmpty) {
        data = data.where((item) => (item['type'] as String?) == type).toList();
      }

      // Apply limit client-side
      if (data.length > limit) {
        data = data.take(limit).toList();
      }

      return data.map((json) {
        final Map<String, dynamic> txData = Map<String, dynamic>.from(json);
        
        // Extract initiator name
        String? initiatorName;
        if (txData['initiator'] != null) {
          final initiator = txData['initiator'] as Map<String, dynamic>;
          initiatorName = '${initiator['first_name']} ${initiator['last_name']}';
        }

        // Extract trip-related data
        String? driverName;
        String? routeCode;
        String? plateNumber;
        String? operatorName;
        int? numPassengers;

        if (txData['trip'] != null) {
          final trip = txData['trip'] as Map<String, dynamic>;
          numPassengers = trip['passengers_count'] as int?;
          
          if (trip['driver'] != null) {
            final driver = trip['driver'] as Map<String, dynamic>;
            plateNumber = driver['vehicle_plate'] as String?;
            operatorName = driver['operator_name'] as String?;
            
            if (driver['profile'] != null) {
              final profile = driver['profile'] as Map<String, dynamic>;
              driverName = '${profile['first_name']} ${profile['last_name']}';
            }
          }

          if (trip['route'] != null) {
            final route = trip['route'] as Map<String, dynamic>;
            routeCode = route['code'] as String?;
          }
        }

        return TransactionModel(
          id: txData['id'],
          transactionNumber: txData['transaction_number'],
          walletId: txData['wallet_id'],
          initiatedByProfileId: txData['initiated_by_profile_id'],
          type: txData['type'],
          amount: (txData['amount'] as num).toDouble(),
          fee: txData['fee'] != null ? (txData['fee'] as num).toDouble() : 0.0,
          status: txData['status'] ?? 'pending',
          relatedTripId: txData['related_trip_id'],
          externalReference: txData['external_reference'],
          metadata: txData['metadata'] as Map<String, dynamic>?,
          createdAt: DateTime.parse(txData['created_at']),
          processedAt: txData['processed_at'] != null 
              ? DateTime.parse(txData['processed_at']) 
              : null,
          initiatorName: initiatorName,
          driverName: driverName,
          passengerName: initiatorName, // For commuter transactions
          routeCode: routeCode,
          plateNumber: plateNumber,
          operatorName: operatorName,
          numPassengers: numPassengers,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch transactions: $e');
    }
  }

  /// Fetch a single transaction by ID with full details
  Future<TransactionModel?> fetchTransactionById(String id) async {
    try {
          final response = await _supabase
            .from('transactions')
            .select('''
            id,
            transaction_number,
            wallet_id,
            initiated_by_profile_id,
            type,
            amount,
            fee,
            status,
            related_trip_id,
            external_reference,
            metadata,
            created_at,
            processed_at,
            initiator:profiles!transactions_initiated_by_profile_id_fkey(first_name, last_name),
            trip:trips(
              driver_id,
              route_id,
              passengers_count,
              driver:drivers(
                profile:profiles(first_name, last_name),
                vehicle_plate,
                operator_name
              ),
              route:routes(code)
            )
          ''')
            .order('created_at', ascending: false)
            .limit(1000);

          final List<dynamic> rows = response as List;
          if (rows.isEmpty) return null;

          final matched = rows.firstWhere((r) => (r['id'] as String?) == id, orElse: () => null);
          if (matched == null) return null;

          final Map<String, dynamic> txData = Map<String, dynamic>.from(matched);
      
      // Extract initiator name
      String? initiatorName;
      if (txData['initiator'] != null) {
        final initiator = txData['initiator'] as Map<String, dynamic>;
        initiatorName = '${initiator['first_name']} ${initiator['last_name']}';
      }

      // Extract trip-related data
      String? driverName;
      String? routeCode;
      String? plateNumber;
      String? operatorName;
      int? numPassengers;

      if (txData['trip'] != null) {
        final trip = txData['trip'] as Map<String, dynamic>;
        numPassengers = trip['passengers_count'] as int?;
        
        if (trip['driver'] != null) {
          final driver = trip['driver'] as Map<String, dynamic>;
          plateNumber = driver['vehicle_plate'] as String?;
          operatorName = driver['operator_name'] as String?;
          
          if (driver['profile'] != null) {
            final profile = driver['profile'] as Map<String, dynamic>;
            driverName = '${profile['first_name']} ${profile['last_name']}';
          }
        }

        if (trip['route'] != null) {
          final route = trip['route'] as Map<String, dynamic>;
          routeCode = route['code'] as String?;
        }
      }

      return TransactionModel(
        id: txData['id'],
        transactionNumber: txData['transaction_number'],
        walletId: txData['wallet_id'],
        initiatedByProfileId: txData['initiated_by_profile_id'],
        type: txData['type'],
        amount: (txData['amount'] as num).toDouble(),
        fee: txData['fee'] != null ? (txData['fee'] as num).toDouble() : 0.0,
        status: txData['status'] ?? 'pending',
        relatedTripId: txData['related_trip_id'],
        externalReference: txData['external_reference'],
        metadata: txData['metadata'] as Map<String, dynamic>?,
        createdAt: DateTime.parse(txData['created_at']),
        processedAt: txData['processed_at'] != null 
            ? DateTime.parse(txData['processed_at']) 
            : null,
        initiatorName: initiatorName,
        driverName: driverName,
        passengerName: initiatorName,
        routeCode: routeCode,
        plateNumber: plateNumber,
        operatorName: operatorName,
        numPassengers: numPassengers,
      );
    } catch (e) {
      throw Exception('Failed to fetch transaction: $e');
    }
  }

  /// Get transaction counts by type
  Future<Map<String, int>> getTransactionCounts() async {
    try {
      final response = await _supabase
          .from('transactions')
          .select('type')
          .order('created_at', ascending: false)
          .limit(1000);

      final List<dynamic> data = response as List;
      final Map<String, int> counts = {};

      for (var item in data) {
        final type = item['type'] as String;
        counts[type] = (counts[type] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      throw Exception('Failed to get transaction counts: $e');
    }
  }
}