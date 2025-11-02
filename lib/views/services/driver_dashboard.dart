import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverDashboardService {
  final _supabase = Supabase.instance.client;

  /// Get driver's profile information
  Future<Map<String, dynamic>> getDriverProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user');
      }

      // Get profile with driver info
      final profileData = await _supabase
          .from('profiles')
          .select('id, first_name, last_name, role')
          .eq('user_id', userId)
          .single();

      debugPrint('✅ Profile fetched: ${profileData['first_name']}');
      return profileData;
    } catch (e) {
      debugPrint('❌ Error fetching profile: $e');
      rethrow;
    }
  }

  /// Get driver's wallet balance
  Future<double> getWalletBalance() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0.0;

      // Get profile_id first
      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .single();

      // Get wallet balance
      final walletData = await _supabase
          .from('wallets')
          .select('balance')
          .eq('owner_profile_id', profile['id'])
          .maybeSingle();

      if (walletData == null) return 0.0;

      final balance = (walletData['balance'] as num?)?.toDouble() ?? 0.0;
      debugPrint('✅ Wallet balance fetched: $balance');
      return balance;
    } catch (e) {
      debugPrint('❌ Error fetching wallet balance: $e');
      return 0.0;
    }
  }

  /// Get today's earnings from completed trips
  Future<double> getTodayEarnings() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0.0;

      // Get profile_id and driver_id
      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (profile == null) return 0.0;

      final driver = await _supabase
          .from('drivers')
          .select('id')
          .eq('profile_id', profile['id'])
          .maybeSingle();

      if (driver == null) return 0.0;

      // Get today's date range
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      // Simplified: Get today's completed trips for this driver
      final trips = await _supabase
          .from('trips')
          .select('id, fare_amount')
          .eq('driver_id', driver['id'])
          .eq('status', 'completed')
          .gte('started_at', startOfDay.toIso8601String());

      // Sum up fare amounts from today's trips
      double totalEarnings = 0.0;
      for (var trip in trips) {
        totalEarnings += (trip['fare_amount'] as num?)?.toDouble() ?? 0.0;
      }

      debugPrint('✅ Today\'s earnings fetched: $totalEarnings (${trips.length} trips)');
      return totalEarnings;
    } catch (e) {
      debugPrint('❌ Error fetching today\'s earnings: $e');
      return 0.0;
    }
  }

  /// Get driver's average rating
  Future<double> getAverageRating() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0.0;

      // Get driver_id
      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (profile == null) return 0.0;

      final driver = await _supabase
          .from('drivers')
          .select('id')
          .eq('profile_id', profile['id'])
          .maybeSingle();

      if (driver == null) return 0.0;

      // Get all ratings for this driver
      final ratings = await _supabase
          .from('ratings')
          .select('overall')
          .eq('driver_id', driver['id']);

      if (ratings.isEmpty) return 0.0;

      // Calculate average
      double sum = 0.0;
      for (var rating in ratings) {
        sum += (rating['overall'] as num?)?.toDouble() ?? 0.0;
      }

      final average = sum / ratings.length;
      debugPrint('✅ Average rating fetched: $average (${ratings.length} ratings)');
      return average;
    } catch (e) {
      debugPrint('❌ Error fetching average rating: $e');
      return 0.0;
    }
  }

  /// Get count of reports filed against this driver
  Future<int> getReportsCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      // Get driver_id
      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (profile == null) return 0;

      final driver = await _supabase
          .from('drivers')
          .select('id')
          .eq('profile_id', profile['id'])
          .maybeSingle();

      if (driver == null) return 0;

      // Count reports where this driver is the reported entity
      final reports = await _supabase
          .from('reports')
          .select('id')
          .eq('reported_entity_type', 'driver')
          .eq('reported_entity_id', driver['id']);

      debugPrint('✅ Reports count fetched: ${reports.length}');
      return reports.length;
    } catch (e) {
      debugPrint('❌ Error fetching reports count: $e');
      return 0;
    }
  }

  /// Get driver's vehicle and route information
  Future<Map<String, dynamic>> getDriverVehicleInfo() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user');
      }

      // Get profile_id
      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .single();

      // Get driver info with route details
      final driverData = await _supabase
          .from('drivers')
          .select('''
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
          ''')
          .eq('profile_id', profile['id'])
          .single();

      debugPrint('✅ Driver vehicle info fetched');
      return driverData;
    } catch (e) {
      debugPrint('❌ Error fetching driver vehicle info: $e');
      rethrow;
    }
  }

  /// Get all dashboard data at once
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      debugPrint('🔄 Fetching all dashboard data...');

      final profile = await getDriverProfile();
      final balance = await getWalletBalance();
      final todayEarnings = await getTodayEarnings();
      final rating = await getAverageRating();
      final reportsCount = await getReportsCount();
      final vehicleInfo = await getDriverVehicleInfo();

      debugPrint('✅ All dashboard data fetched successfully');

      return {
        'profile': profile,
        'balance': balance,
        'todayEarnings': todayEarnings,
        'rating': rating,
        'reportsCount': reportsCount,
        'vehicleInfo': vehicleInfo,
      };
    } catch (e) {
      debugPrint('❌ Error fetching dashboard data: $e');
      rethrow;
    }
  }
}