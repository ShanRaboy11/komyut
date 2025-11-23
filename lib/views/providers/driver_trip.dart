import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/driver_trip.dart';
import '../models/driver_trip.dart';
import '../services/auth_service.dart';

class DriverTripProvider extends ChangeNotifier {
  final DriverTripService _tripService = DriverTripService();
  final AuthService authService = AuthService();
  
  List<DriverTrip> _trips = [];
  List<DriverTrip> _filteredTrips = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _currentFilter = 'all'; // all, ongoing, completed, cancelled

  List<DriverTrip> get trips => _filteredTrips;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get currentFilter => _currentFilter;

  // Statistics
  int get totalTrips => _trips.length;
  int get completedTrips => _trips.where((t) => t.status == 'completed').length;
  int get ongoingTrips => _trips.where((t) => t.status == 'ongoing').length;
  int get cancelledTrips => _trips.where((t) => t.status == 'cancelled').length;
  
  double get totalEarnings => _trips
      .where((t) => t.status == 'completed')
      .fold(0.0, (sum, trip) => sum + trip.fareAmount);

  /// Load all trips for the driver
  DriverTripProvider() {
    // Clear or reload trips on auth changes (only for drivers)
    _authSub = authService.authStateChanges.listen((event) {
      final user = event.session?.user;
      if (user == null) {
        _trips = [];
        _filteredTrips = [];
        notifyListeners();
      } else {
        _maybeLoadForUser(user.id);
      }
    });
  }
  StreamSubscription? _authSub;

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
    debugPrint('DriverTripProvider: user $userId role=$role');
    if (role == 'driver') {
      await loadTrips();
    } else {
      _trips = [];
      _filteredTrips = [];
      notifyListeners();
    }
  }
  Future<void> loadTrips() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _trips = await _tripService.getDriverTripHistory();
      _applyFilter(_currentFilter);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh trips (for pull-to-refresh)
  Future<void> refreshTrips() async {
    await loadTrips();
  }

  /// Filter trips by status
  void filterByStatus(String status) {
    _currentFilter = status;
    _applyFilter(status);
    notifyListeners();
  }

  void _applyFilter(String status) {
    if (status == 'all') {
      _filteredTrips = List.from(_trips);
    } else {
      _filteredTrips = _trips.where((trip) => trip.status == status).toList();
    }
  }

  /// Get trip by ID
  Future<DriverTrip?> getTripById(String tripId) async {
    try {
      return await _tripService.getTripById(tripId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get trips for a specific date range
  List<DriverTrip> getTripsByDateRange(DateTime start, DateTime end) {
    return _trips.where((trip) {
      return trip.startedAt.isAfter(start) && trip.startedAt.isBefore(end);
    }).toList();
  }

  /// Get trips for today
  List<DriverTrip> getTodayTrips() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getTripsByDateRange(startOfDay, endOfDay);
  }

  /// Get trips for this week
  List<DriverTrip> getWeekTrips() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endOfWeek = startOfWeekDay.add(const Duration(days: 7));
    return getTripsByDateRange(startOfWeekDay, endOfWeek);
  }

  /// Get trips for this month
  List<DriverTrip> getMonthTrips() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);
    return getTripsByDateRange(startOfMonth, endOfMonth);
  }

  /// Calculate earnings for a date range
  double getEarningsForDateRange(DateTime start, DateTime end) {
    return getTripsByDateRange(start, end)
        .where((t) => t.status == 'completed')
        .fold(0.0, (sum, trip) => sum + trip.fareAmount);
  }

  /// Get today's earnings
  double get todayEarnings {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getEarningsForDateRange(startOfDay, endOfDay);
  }

  /// Get this week's earnings
  double get weekEarnings {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endOfWeek = startOfWeekDay.add(const Duration(days: 7));
    return getEarningsForDateRange(startOfWeekDay, endOfWeek);
  }

  /// Get this month's earnings
  double get monthEarnings {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);
    return getEarningsForDateRange(startOfMonth, endOfMonth);
  }
}