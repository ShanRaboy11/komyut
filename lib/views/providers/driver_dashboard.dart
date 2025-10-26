// lib/providers/driver_dashboard_provider.dart
import 'package:flutter/foundation.dart';
import '../services/driver_dashboard.dart';

class DriverDashboardProvider extends ChangeNotifier {
  final DriverDashboardService _dashboardService = DriverDashboardService();

  bool _isLoading = false;
  String? _errorMessage;

  // Driver data
  String _firstName = '';
  String _lastName = '';
  double _balance = 0.0;
  double _todayEarnings = 0.0;
  double _rating = 0.0;
  int _reportsCount = 0;
  String _vehiclePlate = '';
  String _routeCode = '';
  String _routeName = '';

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get firstName => _firstName;
  String get lastName => _lastName;
  String get fullName => '$_firstName $_lastName';
  double get balance => _balance;
  double get todayEarnings => _todayEarnings;
  double get rating => _rating;
  int get reportsCount => _reportsCount;
  String get vehiclePlate => _vehiclePlate;
  String get routeCode => _routeCode;
  String get routeName => _routeName;

  /// Load all dashboard data
  Future<void> loadDashboardData() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final data = await _dashboardService.getDashboardData();

      // Update state with fetched data
      _firstName = data['profile']['first_name'] ?? '';
      _lastName = data['profile']['last_name'] ?? '';
      _balance = data['balance'] ?? 0.0;
      _todayEarnings = data['todayEarnings'] ?? 0.0;
      _rating = data['rating'] ?? 0.0;
      _reportsCount = data['reportsCount'] ?? 0;

      // Vehicle and route info
      final vehicleInfo = data['vehicleInfo'];
      _vehiclePlate = vehicleInfo['vehicle_plate'] ?? '';
      
      // Route info (nested)
      final routeData = vehicleInfo['routes'];
      if (routeData != null) {
        _routeCode = routeData['code'] ?? '';
        _routeName = routeData['name'] ?? '';
      }

      debugPrint('✅ Dashboard data loaded in provider');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load dashboard data: $e';
      debugPrint('❌ Error in provider: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh balance only
  Future<void> refreshBalance() async {
    try {
      _balance = await _dashboardService.getWalletBalance();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error refreshing balance: $e');
    }
  }

  /// Refresh today's earnings only
  Future<void> refreshEarnings() async {
    try {
      _todayEarnings = await _dashboardService.getTodayEarnings();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error refreshing earnings: $e');
    }
  }

  /// Refresh rating only
  Future<void> refreshRating() async {
    try {
      _rating = await _dashboardService.getAverageRating();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error refreshing rating: $e');
    }
  }

  /// Clear all data (for logout)
  void clearData() {
    _firstName = '';
    _lastName = '';
    _balance = 0.0;
    _todayEarnings = 0.0;
    _rating = 0.0;
    _reportsCount = 0;
    _vehiclePlate = '';
    _routeCode = '';
    _routeName = '';
    _errorMessage = null;
    notifyListeners();
  }
}