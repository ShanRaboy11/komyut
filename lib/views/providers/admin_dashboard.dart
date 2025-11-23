import 'package:flutter/material.dart';
import '../services/admin_dashboard.dart';

class AdminDashboardProvider extends ChangeNotifier {
  final AdminDashboardService _service = AdminDashboardService();

  // User type breakdown
  UserTypeBreakdown? _userTypeBreakdown;
  bool _isLoadingBreakdown = false;
  String? _breakdownError;

  // Weekly fare analytics
  List<DailyFareData> _fareData = [];
  bool _isLoadingFareData = false;
  String? _fareDataError;
  AnalyticsPeriod _currentPeriod = AnalyticsPeriod.weekly;

  // Overall stats
  OverallStats? _overallStats;
  bool _isLoadingStats = false;
  String? _statsError;

  // Getters
  UserTypeBreakdown? get userTypeBreakdown => _userTypeBreakdown;
  bool get isLoadingBreakdown => _isLoadingBreakdown;
  String? get breakdownError => _breakdownError;

  List<DailyFareData> get fareData => _fareData;
  bool get isLoadingFareData => _isLoadingFareData;
  String? get fareDataError => _fareDataError;
  AnalyticsPeriod get currentPeriod => _currentPeriod;

  OverallStats? get overallStats => _overallStats;
  bool get isLoadingStats => _isLoadingStats;
  String? get statsError => _statsError;

  bool get isLoading => _isLoadingBreakdown || _isLoadingFareData || _isLoadingStats;

  /// Load all dashboard data
  Future<void> loadDashboardData() async {
    await loadUserTypeBreakdown();
    await loadFareData(_currentPeriod);
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

  /// Load fare data with selected period
  Future<void> loadFareData(AnalyticsPeriod period) async {
    _isLoadingFareData = true;
    _fareDataError = null;
    _currentPeriod = period;
    notifyListeners();

    try {
      _fareData = await _service.fetchFareAnalytics(period);
      debugPrint('✅ Loaded fare data: ${_fareData.length} data points for $period');
    } catch (e) {
      _fareDataError = 'Failed to load fare data: $e';
      debugPrint('❌ Error in loadFareData: $e');
    } finally {
      _isLoadingFareData = false;
      notifyListeners();
    }
  }

  /// Change analytics period
  Future<void> changePeriod(AnalyticsPeriod period) async {
    if (_currentPeriod != period) {
      await loadFareData(period);
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