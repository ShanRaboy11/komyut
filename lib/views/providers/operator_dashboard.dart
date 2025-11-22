import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/operator_dashboard.dart';
import '../services/auth_service.dart';

class OperatorDashboardProvider extends ChangeNotifier {
  final OperatorDashboardService _dashboardService = OperatorDashboardService();

  bool _isLoading = false;
  String? _errorMessage;

  // Profile data
  String _firstName = '';
  String _lastName = '';
  bool _isVerified = false;

  // Operator data
  String _companyName = '';
  String _companyAddress = '';
  String _contactEmail = '';
  String _contactPhone = '';

  // Financial data
  double _todaysRevenue = 0.0;

  // Statistics
  int _totalDrivers = 0;
  int _activeTrips = 0;

  // Driver performance data
  List<Map<String, dynamic>> _driverPerformance = [];

  // Reports data
  List<Map<String, dynamic>> _recentReports = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Profile getters
  String get firstName => _firstName;
  String get lastName => _lastName;
  String get fullName => '$_firstName $_lastName';
  bool get isVerified => _isVerified;

  // Operator getters
  String get companyName => _companyName;
  String get companyAddress => _companyAddress;
  String get contactEmail => _contactEmail;
  String get contactPhone => _contactPhone;

  // Financial getters
  double get todaysRevenue => _todaysRevenue;
  String get todaysRevenueFormatted => '₱${_todaysRevenue.toStringAsFixed(2)}';

  // Statistics getters
  int get totalDrivers => _totalDrivers;
  int get activeTrips => _activeTrips;
  String get totalDriversDisplay => _totalDrivers.toString();
  String get activeTripsDisplay => _activeTrips.toString();

  // Driver performance getters
  List<Map<String, dynamic>> get driverPerformance => _driverPerformance;

  // Reports getters
  List<Map<String, dynamic>> get recentReports => _recentReports;

  /// Load all dashboard data
  StreamSubscription? _authSub;

  OperatorDashboardProvider() {
    final AuthService authService = AuthService();
    _authSub = authService.authStateChanges.listen((event) {
      final user = event.session?.user;
      if (user == null) {
        clearData();
      } else {
        _maybeLoadForUser(user.id);
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<String?> _fetchRoleForUser(String userId) async {
    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('user_id', userId)
          .maybeSingle();
      if (res == null) return null;
      return res['role'] as String?;
    } catch (e) {
      debugPrint('Error fetching role for user $userId: $e');
      return null;
    }
  }

  Future<void> _maybeLoadForUser(String userId) async {
    final role = await _fetchRoleForUser(userId);
    debugPrint('OperatorDashboardProvider: user $userId role=$role');
    if (role == 'operator') {
      await loadDashboardData();
    } else {
      clearData();
    }
  }

  Future<void> loadDashboardData() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final data = await _dashboardService.getDashboardData();

      // Update profile data
      final profile = data['profile'] as Map<String, dynamic>?;
      _firstName = profile?['first_name'] ?? '';
      _lastName = profile?['last_name'] ?? '';
      _isVerified = profile?['is_verified'] ?? false;

      // Update operator data
      final operatorData = data['operator'];
      if (operatorData != null) {
        _companyName = operatorData['company_name'] ?? '';
        _companyAddress = operatorData['company_address'] ?? '';
        _contactEmail = operatorData['contact_email'] ?? '';
      }

      // Update financial data
      _todaysRevenue = data['todaysRevenue'] ?? 0.0;

      // Update statistics
      _totalDrivers = data['totalDrivers'] ?? 0;
      _activeTrips = data['activeTrips'] ?? 0;

      // Update driver performance
      _driverPerformance = List<Map<String, dynamic>>.from(data['driverPerformance'] ?? []);

      // Update reports
      _recentReports = List<Map<String, dynamic>>.from(data['recentReports'] ?? []);

      debugPrint('✅ Operator dashboard data loaded in provider');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load dashboard data: $e';
      debugPrint('❌ Error in provider: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh today's revenue only
  Future<void> refreshTodaysRevenue() async {
    try {
      _todaysRevenue = await _dashboardService.getTodaysRevenue();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error refreshing today\'s revenue: $e');
    }
  }

  /// Refresh statistics only
  Future<void> refreshStatistics() async {
    try {
      _totalDrivers = await _dashboardService.getTotalDriversCount();
      _activeTrips = await _dashboardService.getActiveTripsCount();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error refreshing statistics: $e');
    }
  }

  /// Refresh driver performance only
  Future<void> refreshDriverPerformance() async {
    try {
      _driverPerformance = await _dashboardService.getDriverPerformance(limit: 5);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error refreshing driver performance: $e');
    }
  }

  /// Refresh reports only
  Future<void> refreshReports() async {
    try {
      _recentReports = await _dashboardService.getRecentReports(limit: 5);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error refreshing reports: $e');
    }
  }

  /// Get formatted driver revenue
  String getDriverRevenueFormatted(Map<String, dynamic> driver) {
    final revenue = driver['revenue'] ?? 0.0;
    return '₱${revenue.toStringAsFixed(2)}';
  }

  /// Get formatted driver rating
  String getDriverRatingFormatted(Map<String, dynamic> driver) {
    final rating = driver['rating'] ?? 0.0;
    return rating.toStringAsFixed(1);
  }

  /// Get report status color name
  String getReportStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'in_review':
      case 'in progress':
        return 'orange';
      case 'resolved':
      case 'closed':
        return 'green';
      case 'open':
        return 'blue';
      case 'dismissed':
        return 'grey';
      default:
        return 'blue';
    }
  }

  /// Get report status display text
  String getReportStatusDisplay(String status) {
    switch (status.toLowerCase()) {
      case 'in_review':
        return 'In progress';
      case 'resolved':
        return 'Resolved';
      case 'open':
        return 'Open';
      case 'dismissed':
        return 'Dismissed';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }

  /// Get report action button text
  String getReportButtonText(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
      case 'closed':
      case 'dismissed':
        return 'Details';
      case 'in_review':
      case 'in progress':
        return 'Track';
      case 'open':
        return 'Review';
      default:
        return 'View';
    }
  }

  /// Clear all data (for logout)
  void clearData() {
    _firstName = '';
    _lastName = '';
    _isVerified = false;
    _companyName = '';
    _companyAddress = '';
    _contactEmail = '';
    _contactPhone = '';
    _todaysRevenue = 0.0;
    _totalDrivers = 0;
    _activeTrips = 0;
    _driverPerformance = [];
    _recentReports = [];
    _errorMessage = null;
    notifyListeners();
  }
}