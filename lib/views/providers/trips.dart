import 'package:flutter/material.dart';

class TripsProvider with ChangeNotifier {
  final TripsService _tripsService = TripsService();

  // State variables
  String _selectedRange = 'Weekly';
  int _currentIndex = 0;
  bool _isLoading = false;
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
  String? get errorMessage => _errorMessage;
  AnalyticsData get analyticsData => _analyticsData;
  List<ChartDataPoint> get chartData => _chartData;
  List<TripItem> get recentTrips => _recentTrips;

  // Initialize data
  Future<void> initialize() async {
    await loadData();
  }

  // Load all data
  Future<void> loadData() async {
    _isLoading = true;
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
        period: data['period'],
        totalTrips: data['total_trips'],
        totalDistance: data['total_distance'],
        totalSpent: data['total_spent'],
      );
    } catch (e) {
      print('Error loading analytics: $e');
      rethrow;
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
      print('Error loading chart data: $e');
      rethrow;
    }
  }

  // Load recent trips
  Future<void> _loadRecentTrips() async {
    try {
      _recentTrips = await _tripsService.getRecentTrips(limit: 3);
    } catch (e) {
      print('Error loading recent trips: $e');
      rethrow;
    }
  }

  // Change selected range
  Future<void> changeRange(String newRange) async {
    if (_selectedRange == newRange) return;

    _selectedRange = newRange;
    _currentIndex = 0;
    notifyListeners();

    await loadData();
  }

  // Navigate to previous range
  Future<void> prevRange() async {
    _currentIndex = (_currentIndex - 1).clamp(-999, 0);
    notifyListeners();
    await _loadAnalytics();
    await _loadChartData();
  }

  // Navigate to next range
  Future<void> nextRange() async {
    if (_currentIndex >= 0) return; // Don't go into future
    
    _currentIndex = (_currentIndex + 1).clamp(-999, 0);
    notifyListeners();
    await _loadAnalytics();
    await _loadChartData();
  }

  // Refresh all data
  Future<void> refresh() async {
    await loadData();
  }
}