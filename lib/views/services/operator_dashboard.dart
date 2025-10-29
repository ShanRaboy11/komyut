// lib/services/operator_dashboard_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OperatorDashboardService {
  final _supabase = Supabase.instance.client;

  /// Get operator's profile and operator details
  Future<Map<String, dynamic>> getOperatorProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user');
      }

      // Get profile with operator info
      final profileData = await _supabase
          .from('profiles')
          .select('id, first_name, last_name, role, is_verified')
          .eq('user_id', userId)
          .single();

      // Get operator details
      final operatorData = await _supabase
          .from('operators')
          .select('id, company_name, company_address, contact_email')
          .eq('profile_id', profileData['id'])
          .maybeSingle();

      debugPrint('✅ Operator profile fetched: ${profileData['first_name']}');
      return {
        'profile': profileData,
        'operator': operatorData,
      };
    } catch (e) {
      debugPrint('❌ Error fetching operator profile: $e');
      rethrow;
    }
  }

  /// Get operator ID from current user
  Future<String?> _getOperatorId() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .single();

      final operator = await _supabase
          .from('operators')
          .select('id')
          .eq('profile_id', profile['id'])
          .maybeSingle();

      return operator?['id'];
    } catch (e) {
      debugPrint('❌ Error getting operator ID: $e');
      return null;
    }
  }

  /// Get today's revenue for the operator
  Future<double> getTodaysRevenue() async {
    try {
      final operatorId = await _getOperatorId();
      if (operatorId == null) return 0.0;

      // Get today's start and end timestamps
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      // Get all drivers for this operator
      final drivers = await _supabase
          .from('drivers')
          .select('id')
          .eq('operator_id', operatorId);

      if (drivers.isEmpty) return 0.0;

      final driverIds = drivers.map((d) => d['id']).toList();

      // Get trips for these drivers today
      final trips = await _supabase
          .from('trips')
          .select('id')
          .inFilter('driver_id', driverIds)
          .gte('started_at', todayStart.toIso8601String())
          .lt('started_at', todayEnd.toIso8601String());

      if (trips.isEmpty) return 0.0;

      final tripIds = trips.map((t) => t['id']).toList();

      // Sum up fare payments for these trips
      final transactions = await _supabase
          .from('transactions')
          .select('amount')
          .inFilter('related_trip_id', tripIds)
          .eq('type', 'fare_payment')
          .eq('status', 'completed');

      double totalRevenue = 0.0;
      for (var transaction in transactions) {
        totalRevenue += (transaction['amount'] as num?)?.toDouble() ?? 0.0;
      }

      debugPrint('✅ Today\'s revenue fetched: ₱$totalRevenue');
      return totalRevenue;
    } catch (e) {
      debugPrint('❌ Error fetching today\'s revenue: $e');
      return 0.0;
    }
  }

  /// Get total number of drivers for this operator
  Future<int> getTotalDriversCount() async {
    try {
      final operatorId = await _getOperatorId();
      if (operatorId == null) return 0;

      final drivers = await _supabase
          .from('drivers')
          .select('id')
          .eq('operator_id', operatorId)
          .eq('active', true);

      debugPrint('✅ Total drivers count: ${drivers.length}');
      return drivers.length;
    } catch (e) {
      debugPrint('❌ Error fetching drivers count: $e');
      return 0;
    }
  }

  /// Get count of active (ongoing) trips for operator's drivers
  Future<int> getActiveTripsCount() async {
    try {
      final operatorId = await _getOperatorId();
      if (operatorId == null) return 0;

      // Get all drivers for this operator
      final drivers = await _supabase
          .from('drivers')
          .select('id')
          .eq('operator_id', operatorId);

      if (drivers.isEmpty) return 0;

      final driverIds = drivers.map((d) => d['id']).toList();

      // Count ongoing trips
      final trips = await _supabase
          .from('trips')
          .select('id')
          .inFilter('driver_id', driverIds)
          .eq('status', 'ongoing');

      debugPrint('✅ Active trips count: ${trips.length}');
      return trips.length;
    } catch (e) {
      debugPrint('❌ Error fetching active trips count: $e');
      return 0;
    }
  }

  /// Get driver performance data (top drivers by revenue with ratings)
  Future<List<Map<String, dynamic>>> getDriverPerformance({int limit = 10}) async {
    try {
      final operatorId = await _getOperatorId();
      if (operatorId == null) return [];

      // Get drivers for this operator with their profiles
      final drivers = await _supabase
          .from('drivers')
          .select('''
            id,
            vehicle_plate,
            profiles:profile_id (
              id,
              first_name,
              last_name
            )
          ''')
          .eq('operator_id', operatorId)
          .eq('active', true);

      if (drivers.isEmpty) return [];

      // Calculate performance for each driver
      List<Map<String, dynamic>> driverPerformance = [];

      for (var driver in drivers) {
        final driverId = driver['id'];
        final profile = driver['profiles'];
        
        if (profile == null) continue;

        final firstName = profile['first_name'] ?? '';
        final lastName = profile['last_name'] ?? '';
        final fullName = '$firstName $lastName';

        // Get completed trips for revenue calculation
        final trips = await _supabase
            .from('trips')
            .select('id')
            .eq('driver_id', driverId)
            .eq('status', 'completed');

        if (trips.isEmpty) {
          driverPerformance.add({
            'driver_id': driverId,
            'name': fullName,
            'revenue': 0.0,
            'rating': 0.0,
            'total_trips': 0,
          });
          continue;
        }

        final tripIds = trips.map((t) => t['id']).toList();

        // Calculate total revenue
        final transactions = await _supabase
            .from('transactions')
            .select('amount')
            .inFilter('related_trip_id', tripIds)
            .eq('type', 'fare_payment')
            .eq('status', 'completed');

        double revenue = 0.0;
        for (var transaction in transactions) {
          revenue += (transaction['amount'] as num?)?.toDouble() ?? 0.0;
        }

        // Calculate average rating
        final ratings = await _supabase
            .from('ratings')
            .select('overall')
            .eq('driver_id', driverId);

        double averageRating = 0.0;
        if (ratings.isNotEmpty) {
          int totalRating = 0;
          for (var rating in ratings) {
            totalRating += (rating['overall'] as int?) ?? 0;
          }
          averageRating = totalRating / ratings.length;
        }

        driverPerformance.add({
          'driver_id': driverId,
          'name': fullName,
          'revenue': revenue,
          'rating': averageRating,
          'total_trips': trips.length,
        });
      }

      // Sort by revenue (descending) and limit
      driverPerformance.sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));
      final limitedPerformance = driverPerformance.take(limit).toList();

      debugPrint('✅ Driver performance fetched: ${limitedPerformance.length} drivers');
      return limitedPerformance;
    } catch (e) {
      debugPrint('❌ Error fetching driver performance: $e');
      return [];
    }
  }

  /// Get recent reports related to operator's drivers/vehicles
  Future<List<Map<String, dynamic>>> getRecentReports({int limit = 10}) async {
    try {
      final operatorId = await _getOperatorId();
      if (operatorId == null) return [];

      // Get all drivers for this operator
      final drivers = await _supabase
          .from('drivers')
          .select('id, vehicle_plate')
          .eq('operator_id', operatorId);

      if (drivers.isEmpty) return [];

      final driverIds = drivers.map((d) => d['id'] as String).toList();

      // Create a map for quick vehicle plate lookup
      final driverPlateMap = <String, String>{};
      for (var driver in drivers) {
        driverPlateMap[driver['id']] = driver['vehicle_plate'] ?? 'N/A';
      }

      // Get reports related to these drivers
      final reports = await _supabase
          .from('reports')
          .select('''
            id,
            reported_entity_type,
            reported_entity_id,
            category,
            severity,
            status,
            description,
            created_at
          ''')
          .inFilter('reported_entity_id', driverIds)
          .order('created_at', ascending: false)
          .limit(limit);

      // Format reports with vehicle plate numbers
      final formattedReports = reports.map((report) {
        final entityId = report['reported_entity_id'] as String?;
        final plate = entityId != null ? (driverPlateMap[entityId] ?? 'N/A') : 'N/A';
        
        return {
          'id': report['id'],
          'title': _getReportTitle(report['category']),
          'plate': plate,
          'status': report['status'] ?? 'open',
          'severity': report['severity'] ?? 'medium',
          'description': report['description'],
          'created_at': report['created_at'],
        };
      }).toList();

      debugPrint('✅ Recent reports fetched: ${formattedReports.length} reports');
      return formattedReports;
    } catch (e) {
      debugPrint('❌ Error fetching recent reports: $e');
      return [];
    }
  }

  /// Helper method to get user-friendly report titles
  String _getReportTitle(String? category) {
    switch (category) {
      case 'vehicle':
        return 'Vehicle Issue';
      case 'driver':
        return 'Driver Behavior';
      case 'traffic':
        return 'Traffic Incident';
      case 'lost_item':
        return 'Lost Item';
      case 'safety_security':
        return 'Safety Concern';
      case 'route':
        return 'Route Issue';
      default:
        return 'General Report';
    }
  }

  /// Get total revenue for a time period
  Future<double> getTotalRevenue({DateTime? startDate, DateTime? endDate}) async {
    try {
      final operatorId = await _getOperatorId();
      if (operatorId == null) return 0.0;

      // Get all drivers for this operator
      final drivers = await _supabase
          .from('drivers')
          .select('id')
          .eq('operator_id', operatorId);

      if (drivers.isEmpty) return 0.0;

      final driverIds = drivers.map((d) => d['id']).toList();

      // Build query for trips
      var tripsQuery = _supabase
          .from('trips')
          .select('id')
          .inFilter('driver_id', driverIds);

      if (startDate != null) {
        tripsQuery = tripsQuery.gte('started_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        tripsQuery = tripsQuery.lt('started_at', endDate.toIso8601String());
      }

      final trips = await tripsQuery;

      if (trips.isEmpty) return 0.0;

      final tripIds = trips.map((t) => t['id']).toList();

      // Sum up fare payments
      final transactions = await _supabase
          .from('transactions')
          .select('amount')
          .inFilter('related_trip_id', tripIds)
          .eq('type', 'fare_payment')
          .eq('status', 'completed');

      double totalRevenue = 0.0;
      for (var transaction in transactions) {
        totalRevenue += (transaction['amount'] as num?)?.toDouble() ?? 0.0;
      }

      return totalRevenue;
    } catch (e) {
      debugPrint('❌ Error fetching total revenue: $e');
      return 0.0;
    }
  }

  /// Get all dashboard data at once
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      debugPrint('🔄 Fetching all operator dashboard data...');

      final profileData = await getOperatorProfile();
      final todaysRevenue = await getTodaysRevenue();
      final totalDrivers = await getTotalDriversCount();
      final activeTrips = await getActiveTripsCount();
      final driverPerformance = await getDriverPerformance(limit: 5);
      final recentReports = await getRecentReports(limit: 5);

      debugPrint('✅ All operator dashboard data fetched successfully');

      return {
        'profile': profileData['profile'],
        'operator': profileData['operator'],
        'todaysRevenue': todaysRevenue,
        'totalDrivers': totalDrivers,
        'activeTrips': activeTrips,
        'driverPerformance': driverPerformance,
        'recentReports': recentReports,
      };
    } catch (e) {
      debugPrint('❌ Error fetching dashboard data: $e');
      rethrow;
    }
  }
}