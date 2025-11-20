import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/commuter_dashboard.dart';
import '../services/auth_service.dart';

class CommuterDashboardProvider extends ChangeNotifier {
  final CommuterDashboardService _dashboardService = CommuterDashboardService();

  bool _isLoading = false;
  String? _errorMessage;

  // Profile data
  String _firstName = '';
  String _lastName = '';
  bool _isVerified = false;

  // Commuter data
  String _category = 'regular';
  double _wheelTokens = 0.0;
  bool _idVerified = false;

  // Financial data
  double _balance = 0.0;
  double _totalSpent = 0.0;

  // Trip data
  int _totalTripsCount = 0;
  List<Map<String, dynamic>> _recentTrips = [];
  Map<String, dynamic>? _activeTrip;

  // Notifications
  int _unreadNotifications = 0;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Profile getters
  String get firstName => _firstName;
  String get lastName => _lastName;
  String get fullName => '$_firstName $_lastName';
  bool get isVerified => _isVerified;

  // Commuter getters
  String get category => _category;
  double get wheelTokens => _wheelTokens;
  bool get idVerified => _idVerified;

  // Get user-friendly category name
  String get categoryDisplay {
    switch (_category) {
      case 'senior':
        return 'Senior Citizen';
      case 'student':
        return 'Student';
      case 'pwd':
        return 'PWD';
      case 'regular':
      default:
        return 'Regular';
    }
  }

  // Financial getters
  double get balance => _balance;
  double get totalSpent => _totalSpent;

  // Trip getters
  int get totalTripsCount => _totalTripsCount;
  List<Map<String, dynamic>> get recentTrips => _recentTrips;
  Map<String, dynamic>? get activeTrip => _activeTrip;
  bool get hasActiveTrip => _activeTrip != null;

  // Notifications getter
  int get unreadNotifications => _unreadNotifications;

  StreamSubscription? _authSub;

  CommuterDashboardProvider() {
    // Listen to auth changes and load only for commuter role
    final AuthService _authService = AuthService();
    _authSub = _authService.authStateChanges.listen((event) {
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
    debugPrint('CommuterDashboardProvider: user $userId role=$role');
    if (role == 'commuter') {
      await loadDashboardData();
    } else {
      clearData();
    }
  }

  /// Load all dashboard data
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

      // Update commuter details
      final commuterDetails = data['commuterDetails'];
      _category = commuterDetails['category'] ?? 'regular';
      _wheelTokens =
          (commuterDetails['wheel_tokens'] as num?)?.toDouble() ?? 0.0;
      _idVerified = commuterDetails['id_verified'] ?? false;

      // Update financial data
      _balance = data['balance'] ?? 0.0;
      _totalSpent = data['totalSpent'] ?? 0.0;

      // Update trip data
      _totalTripsCount = data['totalTripsCount'] ?? 0;
      _recentTrips = List<Map<String, dynamic>>.from(data['recentTrips'] ?? []);
      _activeTrip = data['activeTrip'];

      // Update notifications
      _unreadNotifications = data['unreadNotifications'] ?? 0;

      debugPrint('✅ Commuter dashboard data loaded in provider');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load dashboard data: $e';
      debugPrint('❌ Error in provider: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh wallet balance only
  Future<void> refreshBalance() async {
    try {
      _balance = await _dashboardService.getWalletBalance();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error refreshing balance: $e');
    }
  }

  /// Refresh wheel tokens only
  Future<void> refreshWheelTokens() async {
    try {
      _wheelTokens = await _dashboardService.getWheelTokens();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error refreshing wheel tokens: $e');
    }
  }

  /// Refresh recent trips only
  Future<void> refreshRecentTrips() async {
    try {
      _recentTrips = await _dashboardService.getRecentTrips();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error refreshing recent trips: $e');
    }
  }

  /// Refresh active trip only
  Future<void> refreshActiveTrip() async {
    try {
      _activeTrip = await _dashboardService.getActiveTrip();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error refreshing active trip: $e');
    }
  }

  /// Refresh notifications count only
  Future<void> refreshNotifications() async {
    try {
      _unreadNotifications = await _dashboardService
          .getUnreadNotificationsCount();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error refreshing notifications: $e');
    }
  }

  /// Refresh trip stats (count and total spent)
  Future<void> refreshTripStats() async {
    try {
      _totalTripsCount = await _dashboardService.getTotalTripsCount();
      _totalSpent = await _dashboardService.getTotalSpent();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error refreshing trip stats: $e');
    }
  }

  /// Clear all data (for logout)
  void clearData() {
    _firstName = '';
    _lastName = '';
    _isVerified = false;
    _category = 'regular';
    _wheelTokens = 0;
    _idVerified = false;
    _balance = 0.0;
    _totalSpent = 0.0;
    _totalTripsCount = 0;
    _recentTrips = [];
    _activeTrip = null;
    _unreadNotifications = 0;
    _errorMessage = null;
    notifyListeners();
  }
}