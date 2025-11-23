import 'package:flutter/material.dart';
import '../services/admin_dashboard.dart';

class AdminDashboardProvider extends ChangeNotifier {
  final AdminDashboardService _service = AdminDashboardService();

  // User type breakdown
  UserTypeBreakdown? _userTypeBreakdown;
  bool _isLoadingBreakdown = false;
  String? _breakdownError;

  // Weekly fare analytics
  List<DailyFareData> _weeklyFareData = [];
  bool _isLoadingFareData = false;
  String? _fareDataError;

  // Overall stats
  OverallStats? _overallStats;
  bool _isLoadingStats = false;
  String? _statsError;

  // Getters
  UserTypeBreakdown? get userTypeBreakdown => _userTypeBreakdown;
  bool get isLoadingBreakdown => _isLoadingBreakdown;
  String? get breakdownError => _breakdownError;

  List<DailyFareData> get weeklyFareData => _weeklyFareData;
  bool get isLoadingFareData => _isLoadingFareData;
  String? get fareDataError => _fareDataError;

  OverallStats? get overallStats => _overallStats;
  bool get isLoadingStats => _isLoadingStats;
  String? get statsError => _statsError;

  bool get isLoading => _isLoadingBreakdown || _isLoadingFareData || _isLoadingStats;

  /// Load all dashboard data
  Future<void> loadDashboardData() async {
    await loadUserTypeBreakdown();
    await loadWeeklyFareData();
    await loadOverallStats();
  }

  /// Load user type breakdown
  Future<void> loadUserTypeBreakdown() async {
    _isLoadingBreakdown = true;
    _breakdownError = null;
    notifyListeners();

    try {
      _userTypeBreakdown = await _service.fetchUserTypeBreakdown();
      debugPrint('✅ Loaded user type breakdown: ${_userTypeBreakdown?.total} users');
    } catch (e) {
      _breakdownError = 'Failed to load user breakdown: $e';
      debugPrint('❌ Error in loadUserTypeBreakdown: $e');
    } finally {
      _isLoadingBreakdown = false;
      notifyListeners();
    }
  }

  /// Load weekly fare data
  Future<void> loadWeeklyFareData() async {
    _isLoadingFareData = true;
    _fareDataError = null;
    notifyListeners();

    try {
      _weeklyFareData = await _service.fetchWeeklyFareAnalytics();
      debugPrint('✅ Loaded weekly fare data: ${_weeklyFareData.length} days');
    } catch (e) {
      _fareDataError = 'Failed to load fare data: $e';
      debugPrint('❌ Error in loadWeeklyFareData: $e');
    } finally {
      _isLoadingFareData = false;
      notifyListeners();
    }
  }

  /// Load overall stats
  Future<void> loadOverallStats() async {
    _isLoadingStats = true;
    _statsError = null;
    notifyListeners();

    try {
      _overallStats = await _service.fetchOverallStats();
      debugPrint('✅ Loaded overall stats');
    } catch (e) {
      _statsError = 'Failed to load stats: $e';
      debugPrint('❌ Error in loadOverallStats: $e');
    } finally {
      _isLoadingStats = false;
      notifyListeners();
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    await loadDashboardData();
  }
}