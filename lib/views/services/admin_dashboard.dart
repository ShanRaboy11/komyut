import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AnalyticsPeriod { weekly, monthly, yearly }

class AdminDashboardService {
  final _supabase = Supabase.instance.client;

  /// Fetch user type breakdown statistics
  Future<UserTypeBreakdown> fetchUserTypeBreakdown() async {
    try {
      debugPrint('🔍 Fetching user type breakdown...');

      // Get counts for each role
      final profiles = await _supabase
          .from('profiles')
          .select('role')
          .neq('role', 'admin');

      final commuters = profiles.where((p) => p['role'] == 'commuter').length;
      final drivers = profiles.where((p) => p['role'] == 'driver').length;
      final operators = profiles.where((p) => p['role'] == 'operator').length;

      debugPrint('✅ Breakdown - Commuters: $commuters, Drivers: $drivers, Operators: $operators');

      return UserTypeBreakdown(
        commuters: commuters,
        drivers: drivers,
        operators: operators,
      );
    } catch (e) {
      debugPrint('❌ Error fetching user type breakdown: $e');
      rethrow;
    }
  }

  /// Fetch fare analytics based on period
  Future<List<DailyFareData>> fetchFareAnalytics(AnalyticsPeriod period) async {
    switch (period) {
      case AnalyticsPeriod.weekly:
        return _fetchWeeklyFareAnalytics();
      case AnalyticsPeriod.monthly:
        return _fetchMonthlyFareAnalytics();
      case AnalyticsPeriod.yearly:
        return _fetchYearlyFareAnalytics();
    }
  }

  /// Fetch weekly fare analytics (last 7 days)
  Future<List<DailyFareData>> _fetchWeeklyFareAnalytics() async {
    try {
      debugPrint('🔍 Fetching weekly fare analytics...');

      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 6));

      final transactions = await _supabase
          .from('transactions')
          .select('amount, created_at')
          .eq('type', 'fare_payment')
          .eq('status', 'completed')
          .gte('created_at', sevenDaysAgo.toIso8601String())
          .lte('created_at', now.toIso8601String())
          .order('created_at', ascending: true);

      debugPrint('✅ Fetched ${transactions.length} fare transactions');

      // Group by day
      Map<String, double> dailyTotals = {};
      
      // Initialize all days with 0
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateKey = _getDateKey(date);
        dailyTotals[dateKey] = 0.0;
      }

      // Sum up transactions by day
      for (var transaction in transactions) {
        final createdAt = DateTime.parse(transaction['created_at'] as String);
        final dateKey = _getDateKey(createdAt);
        final amount = (transaction['amount'] as num).toDouble();
        dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0) + amount;
      }

      // Convert to list
      final List<DailyFareData> result = [];
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateKey = _getDateKey(date);
        
        result.add(DailyFareData(
          date: date,
          dayName: _getDayName(date.weekday),
          amount: dailyTotals[dateKey] ?? 0.0,
        ));
      }

      debugPrint('✅ Weekly fare data prepared: ${result.length} days');
      return result;
    } catch (e) {
      debugPrint('❌ Error fetching weekly fare analytics: $e');
      rethrow;
    }
  }

  /// Fetch monthly fare analytics (last 30 days)
  Future<List<DailyFareData>> _fetchMonthlyFareAnalytics() async {
    try {
      debugPrint('🔍 Fetching monthly fare analytics...');

      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 29));

      final transactions = await _supabase
          .from('transactions')
          .select('amount, created_at')
          .eq('type', 'fare_payment')
          .eq('status', 'completed')
          .gte('created_at', thirtyDaysAgo.toIso8601String())
          .lte('created_at', now.toIso8601String())
          .order('created_at', ascending: true);

      debugPrint('✅ Fetched ${transactions.length} fare transactions');

      // Group by week (4 weeks)
      Map<int, double> weeklyTotals = {0: 0.0, 1: 0.0, 2: 0.0, 3: 0.0};

      for (var transaction in transactions) {
        final createdAt = DateTime.parse(transaction['created_at'] as String);
        final daysDiff = now.difference(createdAt).inDays;
        final weekIndex = 3 - (daysDiff ~/ 7).clamp(0, 3);
        final amount = (transaction['amount'] as num).toDouble();
        weeklyTotals[weekIndex] = (weeklyTotals[weekIndex] ?? 0) + amount;
      }

      // Convert to list
      final List<DailyFareData> result = [];
      for (int i = 0; i < 4; i++) {
        result.add(DailyFareData(
          date: now.subtract(Duration(days: (3 - i) * 7)),
          dayName: 'Week ${i + 1}',
          amount: weeklyTotals[i] ?? 0.0,
        ));
      }

      debugPrint('✅ Monthly fare data prepared: ${result.length} weeks');
      return result;
    } catch (e) {
      debugPrint('❌ Error fetching monthly fare analytics: $e');
      rethrow;
    }
  }

  /// Fetch yearly fare analytics (last 12 months)
  Future<List<DailyFareData>> _fetchYearlyFareAnalytics() async {
    try {
      debugPrint('🔍 Fetching yearly fare analytics...');

      final now = DateTime.now();
      final oneYearAgo = DateTime(now.year - 1, now.month, 1);

      final transactions = await _supabase
          .from('transactions')
          .select('amount, created_at')
          .eq('type', 'fare_payment')
          .eq('status', 'completed')
          .gte('created_at', oneYearAgo.toIso8601String())
          .lte('created_at', now.toIso8601String())
          .order('created_at', ascending: true);

      debugPrint('✅ Fetched ${transactions.length} fare transactions');

      // Group by month
      Map<String, double> monthlyTotals = {};
      
      // Initialize all 12 months with 0
      for (int i = 11; i >= 0; i--) {
        final date = DateTime(now.year, now.month - i, 1);
        final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        monthlyTotals[monthKey] = 0.0;
      }

      // Sum up transactions by month
      for (var transaction in transactions) {
        final createdAt = DateTime.parse(transaction['created_at'] as String);
        final monthKey = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}';
        final amount = (transaction['amount'] as num).toDouble();
        monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0) + amount;
      }

      // Convert to list
      final List<DailyFareData> result = [];
      for (int i = 11; i >= 0; i--) {
        final date = DateTime(now.year, now.month - i, 1);
        final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        
        result.add(DailyFareData(
          date: date,
          dayName: _getMonthName(date.month),
          amount: monthlyTotals[monthKey] ?? 0.0,
        ));
      }

      debugPrint('✅ Yearly fare data prepared: ${result.length} months');
      return result;
    } catch (e) {
      debugPrint('❌ Error fetching yearly fare analytics: $e');
      rethrow;
    }
  }

  /// Fetch overall statistics
  Future<OverallStats> fetchOverallStats() async {
    try {
      debugPrint('🔍 Fetching overall stats...');

      // Get total users (excluding admins)
      final usersResponse = await _supabase
          .from('profiles')
          .select('id')
          .neq('role', 'admin');
      final usersCount = usersResponse.length;

      // Get total completed trips
      final tripsResponse = await _supabase
          .from('trips')
          .select('id')
          .eq('status', 'completed');
      final tripsCount = tripsResponse.length;

      // Get total fare revenue
      final fareRevenue = await _supabase
          .from('transactions')
          .select('amount')
          .eq('type', 'fare_payment')
          .eq('status', 'completed');

      double totalRevenue = 0.0;
      for (var transaction in fareRevenue) {
        totalRevenue += (transaction['amount'] as num).toDouble();
      }

      // Get pending verifications count
      final pendingResponse = await _supabase
          .from('verifications')
          .select('id')
          .eq('status', 'pending');
      final pendingVerifications = pendingResponse.length;

      debugPrint('✅ Overall stats fetched');

      return OverallStats(
        totalUsers: usersCount,
        totalTrips: tripsCount,
        totalRevenue: totalRevenue,
        pendingVerifications: pendingVerifications,
      );
    } catch (e) {
      debugPrint('❌ Error fetching overall stats: $e');
      rethrow;
    }
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1: return 'Jan';
      case 2: return 'Feb';
      case 3: return 'Mar';
      case 4: return 'Apr';
      case 5: return 'May';
      case 6: return 'Jun';
      case 7: return 'Jul';
      case 8: return 'Aug';
      case 9: return 'Sep';
      case 10: return 'Oct';
      case 11: return 'Nov';
      case 12: return 'Dec';
      default: return '';
    }
  }
}

// Models
class UserTypeBreakdown {
  final int commuters;
  final int drivers;
  final int operators;

  UserTypeBreakdown({
    required this.commuters,
    required this.drivers,
    required this.operators,
  });

  int get total => commuters + drivers + operators;
}

class DailyFareData {
  final DateTime date;
  final String dayName;
  final double amount;

  DailyFareData({
    required this.date,
    required this.dayName,
    required this.amount,
  });
}

class OverallStats {
  final int totalUsers;
  final int totalTrips;
  final double totalRevenue;
  final int pendingVerifications;

  OverallStats({
    required this.totalUsers,
    required this.totalTrips,
    required this.totalRevenue,
    required this.pendingVerifications,
  });
}