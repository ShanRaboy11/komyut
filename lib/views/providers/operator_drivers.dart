import 'package:flutter/material.dart';
import '../models/operator_drivers.dart';
import '../services/operator_drivers.dart';

class OperatorProvider extends ChangeNotifier {
  final OperatorService _operatorService = OperatorService();

  List<OperatorDriver> _drivers = [];
  List<OperatorDriver> _filteredDrivers = [];
  OperatorInfo? _operatorInfo;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  // Return ALL drivers (not filtered)
  List<OperatorDriver> get drivers => _drivers;
  
  // Return filtered drivers for search functionality
  List<OperatorDriver> get filteredDrivers => _filteredDrivers;
  
  OperatorInfo? get operatorInfo => _operatorInfo;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  int get totalDrivers => _drivers.length;
  int get activeDrivers => _drivers.where((d) => d.status && d.active).length;

  /// Load operator information
  Future<void> loadOperatorInfo() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _operatorInfo = await _operatorService.getCurrentOperatorInfo();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load all drivers for the operator
  Future<void> loadDrivers() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _drivers = await _operatorService.getOperatorDriversWithRoutes();
      _applySearch();
    } catch (e) {
      _error = e.toString();
      _drivers = [];
      _filteredDrivers = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh drivers list
  Future<void> refreshDrivers() async {
    await loadDrivers();
  }

  /// Search drivers
  void searchDrivers(String query) {
    _searchQuery = query.toLowerCase();
    _applySearch();
    notifyListeners();
  }

  /// Apply search filter
  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredDrivers = List.from(_drivers);
    } else {
      _filteredDrivers = _drivers.where((driver) {
        final fullName = driver.fullName.toLowerCase();
        final license = driver.licenseNumber.toLowerCase();
        final vehiclePlate = driver.vehiclePlate?.toLowerCase() ?? '';
        final routeCode = driver.routeCode?.toLowerCase() ?? '';
        final routeName = driver.routeName?.toLowerCase() ?? '';

        return fullName.contains(_searchQuery) ||
            license.contains(_searchQuery) ||
            vehiclePlate.contains(_searchQuery) ||
            routeCode.contains(_searchQuery) ||
            routeName.contains(_searchQuery);
      }).toList();
    }
  }

  /// Clear search
  void clearSearch() {
    _searchQuery = '';
    _applySearch();
    notifyListeners();
  }

  /// Filter by active status
  void filterByActiveStatus(bool? isActive) {
    if (isActive == null) {
      _filteredDrivers = List.from(_drivers);
    } else {
      _filteredDrivers = _drivers.where((d) => d.active == isActive).toList();
    }
    notifyListeners();
  }

  /// Filter by online status
  void filterByOnlineStatus(bool? isOnline) {
    if (isOnline == null) {
      _filteredDrivers = List.from(_drivers);
    } else {
      _filteredDrivers = _drivers.where((d) => d.status == isOnline).toList();
    }
    notifyListeners();
  }

  /// Get driver by ID
  OperatorDriver? getDriverById(String id) {
    try {
      return _drivers.firstWhere((d) => d.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Clear all data
  void clear() {
    _drivers = [];
    _filteredDrivers = [];
    _operatorInfo = null;
    _searchQuery = '';
    _error = null;
    notifyListeners();
  }
}