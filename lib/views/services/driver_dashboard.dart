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

  /// Get driver's average rating
  Future<double> getAverageRating() async {
    try {
      final driverId = await _getCurrentDriverId();
      if (driverId == null) return 0.0;

      final ratings = await _supabase
          .from('ratings')
          .select('overall')
          .eq('driver_id', driverId);

      if (ratings.isEmpty) return 0.0;

      double sum = 0.0;
      for (var rating in ratings) {
        sum += (rating['overall'] as num?)?.toDouble() ?? 0.0;
      }

      return sum / ratings.length;
    } catch (e) {
      debugPrint('❌ Error fetching average rating: $e');
      return 0.0;
    }
  }

  /// Get count of reports filed against this driver
  Future<int> getReportsCount() async {
    try {
      // Get current driver's profile id and driver id
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final profileResp = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (profileResp == null || profileResp['id'] == null) return 0;
      final profileId = profileResp['id'] as String;

      final driverId = await _getCurrentDriverId();

      // Fetch reports assigned to this driver's profile
      // Fetch reports assigned to this driver's profile (include metadata for debugging)
      final assignedReports = await _supabase
          .from('reports')
          .select('id, assigned_to_profile_id, reported_entity_type, reported_entity_id')
          .eq('assigned_to_profile_id', profileId);

      // Also fetch reports that explicitly reference this driver entity
      List<dynamic> referencedReports = [];
      if (driverId != null) {
        referencedReports = await _supabase
            .from('reports')
            .select('id, assigned_to_profile_id, reported_entity_type, reported_entity_id')
            .eq('reported_entity_type', 'driver')
            .eq('reported_entity_id', driverId);
      }

      // Debug: print what we fetched so we can troubleshoot RLS / mismatches
      debugPrint('🔎 Driver reports debug: profileId=$profileId driverId=$driverId');
      debugPrint('🔎 Assigned reports count (raw): ${assignedReports.length}');
      debugPrint('🔎 Referenced reports count (raw): ${referencedReports.length}');

      // Combine unique report ids
      final ids = <String>{};
      for (var r in assignedReports) {
        final id = r['id'] as String?;
        if (id != null) ids.add(id);
      }
      for (var r in referencedReports) {
        final id = r['id'] as String?;
        if (id != null) ids.add(id);
      }

      debugPrint('🔎 Combined unique report ids: ${ids.toList()}');
      return ids.length;
    } catch (e) {
      debugPrint('❌ Error fetching reports count: $e');
      return 0;
    }
  }

  /// Get driver's wallet balance
  Future<double> getWalletBalance() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0.0;

      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (profile == null) {
        debugPrint('ℹ️ No profile found for user when fetching wallet balance');
        return 0.0;
      }

      final walletData = await _supabase
          .from('wallets')
          .select('balance')
          .eq('owner_profile_id', profile['id'])
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
      debugPrint('🔄 Fetching all dashboard data...');

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

  /// Get recent transactions
  Future<List<Map<String, dynamic>>> getRecentTransactions() async {
    return _getTransactions(limit: 5);
  }

  /// Get all transactions
  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    return _getTransactions();
  }

  Future<List<Map<String, dynamic>>> _getTransactions({int? limit}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated.');

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

      var query = _supabase
          .from('transactions')
          .select('transaction_number, type, amount, created_at, metadata')
          .eq('wallet_id', wallet['id'])
          .inFilter('type', [
            'fare_payment',
            'operator_payout',
            'driver_payout',
            'remittance',
            'cash_out',
          ])
          .order('created_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final transactions = await query;
      return transactions;
    } catch (e) {
      debugPrint('❌ Error fetching driver transactions: $e');
      rethrow;
    }
  }

  /// Process a remittance to the operator
  Future<void> remitEarnings(double amount, String transactionCode) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated.');

      await _supabase.rpc(
        'process_driver_remittance',
        params: {
          'amount_to_remit': amount,
          'transaction_code': transactionCode,
        },
      );

      debugPrint('✅ Remittance successful. Code: $transactionCode');
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
