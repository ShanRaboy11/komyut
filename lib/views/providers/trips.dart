import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

import '../services/trips.dart';
import '../models/trips.dart';

class TripsProvider with ChangeNotifier {
  final TripsService _tripsService = TripsService();
  final AuthService authService = AuthService();

  // State variables
  String _selectedRange = 'Weekly';
  int _currentIndex = 0;
  bool _isLoading = false;
  bool _isAnalyticsLoading = false;
  String? _errorMessage;

  // Analytics data
  AnalyticsData _analyticsData = AnalyticsData(
    period: '',
    totalTrips: 0,
    totalDistance: 0.0,
    totalSpent: 0.0,
  );

  // Chart data
  List<ChartDataPoint> _chartData = [];

  // Recent trips
  List<TripItem> _recentTrips = [];

  // Getters
  String get selectedRange => _selectedRange;
  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  bool get analyticsLoading => _isAnalyticsLoading;
  String? get errorMessage => _errorMessage;
  AnalyticsData get analyticsData => _analyticsData;
  List<ChartDataPoint> get chartData => _chartData;
  List<TripItem> get recentTrips => _recentTrips;

  // Initialize data
  Future<void> initialize() async {
    await loadData();
  }

  TripsProvider() {
    // Keep trips data in sync with auth changes: clear on sign-out, reload on sign-in
    _authSub = authService.authStateChanges.listen((event) {
      final user = event.session?.user;
      if (user == null) {
        _analyticsData = AnalyticsData(period: '', totalTrips: 0, totalDistance: 0.0, totalSpent: 0.0);
        _chartData = [];
        _recentTrips = [];
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
      developer.log('Error fetching role for user $userId: $e', name: 'TripsProvider');
      return null;
    }
  }

  Future<void> _maybeLoadForUser(String userId) async {
    final role = await _fetchRoleForUser(userId);
    developer.log('TripsProvider: user $userId role=$role', name: 'TripsProvider');
    // Only load trips analytics for operators or drivers
    if (role == 'operator' || role == 'driver') {
      await loadData();
    } else {
      _analyticsData = AnalyticsData(period: '', totalTrips: 0, totalDistance: 0.0, totalSpent: 0.0);
      _chartData = [];
      _recentTrips = [];
      notifyListeners();
    }
  }

  // Load all data
  Future<void> loadData() async {
    _isLoading = true;
    _isAnalyticsLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        _loadAnalytics(),
        _loadChartData(),
        _loadRecentTrips(),
      ]);
    } catch (e) {
      _errorMessage = 'Error loading trips data: $e';
    } finally {
      _isLoading = false;
      _isAnalyticsLoading = false;
      notifyListeners();
    }
  }

  // Load analytics
  Future<void> _loadAnalytics() async {
    try {
      final data = await _tripsService.getAnalytics(
        timeRange: _selectedRange,
        rangeOffset: _currentIndex,
      );

      _analyticsData = AnalyticsData(
        period: data['period'] as String,
        totalTrips: data['total_trips'] as int,
        totalDistance: data['total_distance'] as double,
        totalSpent: data['total_spent'] as double,
      );
    } catch (e) {
      developer.log('Error loading analytics: $e', name: 'TripsProvider');
      _errorMessage = 'Error loading analytics: $e';
      // don't rethrow; let loadData handle final state
    }
  }

  // Load chart data
  Future<void> _loadChartData() async {
    try {
      _chartData = await _tripsService.getChartData(
        timeRange: _selectedRange,
        rangeOffset: _currentIndex,
      );
    } catch (e) {
      developer.log('Error loading chart data: $e', name: 'TripsProvider');
      _errorMessage = 'Error loading chart data: $e';
    }
  }

  // Load recent trips
  Future<void> _loadRecentTrips() async {
    try {
      _recentTrips = await _tripsService.getRecentTrips(limit: 3);
    } catch (e) {
      developer.log('Error loading recent trips: $e', name: 'TripsProvider');
      _errorMessage = 'Error loading recent trips: $e';
    }
  }

  // Change selected range
  Future<void> changeRange(String newRange) async {
    if (_selectedRange == newRange) return;

    _selectedRange = newRange;
    _currentIndex = 0;
    notifyListeners();

    // Only reload analytics and chart data; keep recent trips cached.
    _isAnalyticsLoading = true;
    notifyListeners();
    try {
      await _loadAnalytics();
      await _loadChartData();
    } finally {
      _isAnalyticsLoading = false;
      notifyListeners();
    }
  }

  // Navigate to previous range
  Future<void> prevRange() async {
    _currentIndex = (_currentIndex - 1).clamp(-999, 0).toInt();
    notifyListeners();
    _isAnalyticsLoading = true;
    notifyListeners();
    try {
      await _loadAnalytics();
      await _loadChartData();
    } finally {
      _isAnalyticsLoading = false;
      notifyListeners();
    }
  }

  // Navigate to next range
  Future<void> nextRange() async {
    if (_currentIndex >= 0) return; // Don't go into future
    _currentIndex = (_currentIndex + 1).clamp(-999, 0).toInt();
    notifyListeners();
    _isAnalyticsLoading = true;
    notifyListeners();
    try {
      await _loadAnalytics();
      await _loadChartData();
    } finally {
      _isAnalyticsLoading = false;
      notifyListeners();
    }
  }

  // Refresh all data
  Future<void> refresh() async {
    await loadData();
  }
}