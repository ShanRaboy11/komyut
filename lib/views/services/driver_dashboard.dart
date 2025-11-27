import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverDashboardService {
  final _supabase = Supabase.instance.client;

  /// Get driver's profile information
  Future<Map<String, dynamic>> getDriverProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('No authenticated user');

      final profileData = await _supabase
          .from('profiles')
          .select('id, first_name, last_name, role')
          .eq('user_id', userId)
          .single();

      return profileData;
    } catch (e) {
      debugPrint('❌ Error fetching profile: $e');
      rethrow;
    }
  }

  /// Return full report rows assigned to the driver or referencing the driver entity.
  Future<List<Map<String, dynamic>>> getAssignedReports({int? limit}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final profileResp = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      if (profileResp == null || profileResp['id'] == null) return [];
      final profileId = profileResp['id'] as String;

      final driverId = await _getCurrentDriverId();

      // Query for assigned reports
      final assigned = await _supabase
          .from('reports')
          .select('id, reporter_profile_id, category, severity, status, description, assigned_to_profile_id, reported_entity_type, reported_entity_id, created_at')
          .eq('assigned_to_profile_id', profileId)
          .order('created_at', ascending: false);

      // Query for referenced reports (by driver entity)
      List<dynamic> referenced = [];
      if (driverId != null) {
        referenced = await _supabase
            .from('reports')
            .select('id, reporter_profile_id, category, severity, status, description, assigned_to_profile_id, reported_entity_type, reported_entity_id, created_at')
            .eq('reported_entity_type', 'driver')
            .eq('reported_entity_id', driverId)
            .order('created_at', ascending: false);
      }

      // Merge unique rows by id
      final Map<String, Map<String, dynamic>> map = {};
      for (var r in assigned) {
        final id = r['id'] as String?;
        if (id != null) map[id] = Map<String, dynamic>.from(r as Map);
      }
      for (var r in referenced) {
        final id = r['id'] as String?;
        if (id != null) map[id] = Map<String, dynamic>.from(r as Map);
      }

      final list = map.values.toList()
        ..sort((a, b) => (b['created_at'] ?? '').toString().compareTo((a['created_at'] ?? '').toString()));

      if (limit != null && list.length > limit) return list.sublist(0, limit);
      return list;
    } catch (e) {
      debugPrint('❌ Error fetching assigned reports: $e');
      return [];
    }
  }

  /// Get driver's vehicle and route information
  Future<Map<String, dynamic>> getDriverVehicleInfo() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('No authenticated user');

      final data = await _supabase
          .from('profiles')
          .select('''
            id,
            driver:drivers!drivers_profile_id_fkey (
              id,
              vehicle_plate,
              license_number,
              operator_name,
              status,
              routes:route_id (
                code,
                name,
                description
              )
            )
          ''')
          .eq('user_id', userId)
          .single();

      if (data['driver'] == null) {
        return {};
      }

      return data['driver'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ Error fetching driver vehicle info: $e');
      rethrow;
    }
  }

  Future<String?> _getCurrentDriverId() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await _supabase
        .from('profiles')
        .select('drivers!drivers_profile_id_fkey(id)')
        .eq('user_id', userId)
        .maybeSingle();

    if (data == null || data['drivers'] == null) return null;
    return data['drivers']['id'] as String?;
  }

  Future<String?> _getCurrentWalletId() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final profile = await _supabase
        .from('profiles')
        .select('id')
        .eq('user_id', userId)
        .single();

    final wallet = await _supabase
        .from('wallets')
        .select('id')
        .eq('owner_profile_id', profile['id'])
        .single();

    return wallet['id'] as String?;
  }

  /// Get driver's wallet balance
  Future<double> getWalletBalance() async {
    try {
      final walletId = await _getCurrentWalletId();
      if (walletId == null) return 0.0;

      final walletData = await _supabase
          .from('wallets')
          .select('balance')
          .eq('id', walletId)
          .maybeSingle();

      if (walletData == null) return 0.0;

      return (walletData['balance'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      debugPrint('❌ Error fetching wallet balance: $e');
      return 0.0;
    }
  }

  /// Get today's earnings
  Future<double> getTodayEarnings() async {
    try {
      final driverId = await _getCurrentDriverId();
      if (driverId == null) return 0.0;

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final trips = await _supabase
          .from('trips')
          .select('fare_amount')
          .eq('driver_id', driverId)
          .eq('status', 'completed')
          .gte('started_at', startOfDay.toIso8601String());

      double totalEarnings = 0.0;
      for (var trip in trips) {
        totalEarnings += (trip['fare_amount'] as num?)?.toDouble() ?? 0.0;
      }
      return totalEarnings;
    } catch (e) {
      debugPrint('❌ Error fetching today\'s earnings: $e');
      return 0.0;
    }
  }

  Future<Map<String, double>> getWeeklyEarnings({int weekOffset = 0}) async {
    try {
      final response = await _supabase.rpc(
        'get_driver_weekly_earnings',
        params: {'week_offset': weekOffset},
      );

      if (response is List) {
        return {
          for (var item in response)
            (item['day_name'] as String): (item['total'] as num).toDouble(),
        };
      }
      return {};
    } catch (e) {
      debugPrint('❌ Error fetching weekly earnings: $e');
      return {};
    }
  }

  /// Get all dashboard data at once
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final results = await Future.wait([
        getDriverProfile(),
        getWalletBalance(),
        getTodayEarnings(),
        getAverageRating(),
        getReportsCount(),
        getDriverVehicleInfo(),
      ]);

      return {
        'profile': results[0],
        'balance': results[1],
        'todayEarnings': results[2],
        'rating': results[3],
        'reportsCount': results[4],
        'vehicleInfo': results[5],
      };
    } catch (e) {
      debugPrint('❌ Error fetching dashboard data: $e');
      rethrow;
    }
  }

  // Wrappers for rating/reports to keep existing code working
  Future<double> getAverageRating() async => 0.0; // Implement if needed
  Future<int> getReportsCount() async => 0; // Implement if needed

  /// Get recent transactions
  Future<List<Map<String, dynamic>>> getRecentTransactions() async {
    return getAllTransactions(limit: 5);
  }

  /// Get all transactions (Merged History)
  ///
  /// 1. Fetches standard wallet transactions (Cash Out, Remittance)
  /// 2. Fetches 'fare_payment' transactions linked to this Driver's trips
  Future<List<Map<String, dynamic>>> getAllTransactions({int? limit}) async {
    try {
      final driverId = await _getCurrentDriverId();
      final walletId = await _getCurrentWalletId();

      if (driverId == null || walletId == null) {
        throw Exception('Driver or Wallet not found');
      }

      // 1. Fetch Wallet Actions (Cash Out, Remittance, Payouts)
      // These are directly linked to the wallet_id
      final walletTxFuture = _supabase
          .from('transactions')
          .select('transaction_number, type, amount, created_at, metadata')
          .eq('wallet_id', walletId)
          .inFilter('type', [
            'operator_payout',
            'driver_payout',
            'remittance',
            'cash_out',
          ])
          .order('created_at', ascending: false);

      // 2. Fetch Trip Earnings (Fare Payments)
      // These are linked to the TRIPS table where driver_id = current_driver
      // We use !inner join to enforce the driver check
      final tripTxFuture = _supabase
          .from('transactions')
          .select('''
            transaction_number, 
            type, 
            amount, 
            created_at, 
            metadata,
            trip:trips!inner(driver_id)
          ''')
          .eq('trip.driver_id', driverId)
          .eq('type', 'fare_payment')
          .order('created_at', ascending: false);

      // Execute both
      final results = await Future.wait([walletTxFuture, tripTxFuture]);

      final walletTx = List<Map<String, dynamic>>.from(results[0]);
      final tripTx = List<Map<String, dynamic>>.from(results[1]);

      // Merge results
      final List<Map<String, dynamic>> allTx = [...walletTx, ...tripTx];

      // Sort by Date (Newest first)
      allTx.sort((a, b) {
        final dateA = DateTime.parse(a['created_at']);
        final dateB = DateTime.parse(b['created_at']);
        return dateB.compareTo(dateA);
      });

      // Apply limit if requested
      if (limit != null && allTx.length > limit) {
        return allTx.sublist(0, limit);
      }

      return allTx;
    } catch (e) {
      debugPrint('❌ Error fetching merged transactions: $e');
      return [];
    }
  }

  /// Process a remittance to the operator
  Future<void> remitEarnings(double amount, String transactionCode) async {
    try {
      await _supabase.rpc(
        'process_driver_remittance',
        params: {
          'amount_to_remit': amount,
          'transaction_code': transactionCode,
        },
      );
    } catch (e) {
      debugPrint('❌ Error processing remittance: $e');
      rethrow;
    }
  }

  /// Process a Cash Out Request
  Future<void> requestCashOut({
    required double amount,
    required String transactionCode,
  }) async {
    await _supabase.rpc(
      'request_driver_cash_out',
      params: {
        'amount_val': amount,
        'fee_val': 15.00,
        'transaction_code': transactionCode,
      },
    );
  }

  Future<void> completeCashOut(String transactionCode) async {
    await _supabase.rpc(
      'complete_driver_cash_out',
      params: {'transaction_code_arg': transactionCode},
    );
  }
}
