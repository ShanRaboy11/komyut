import 'package:flutter/foundation.dart';
import '../services/commuter_dashboard.dart';

class WalletProvider extends ChangeNotifier {
  final CommuterDashboardService _dashboardService = CommuterDashboardService();

  bool _isLoading = false;
  String? _errorMessage;
  double _balance = 0.0;
  int _wheelTokens = 0;
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _tokenHistory = [];
  Map<String, double> _fareExpenses = {};

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get balance => _balance;
  int get wheelTokens => _wheelTokens;
  List<Map<String, dynamic>> get transactions => _transactions;
  List<Map<String, dynamic>> get tokenHistory => _tokenHistory;
  Map<String, double> get fareExpenses => _fareExpenses;

  Future<void> fetchWalletData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch all data in parallel
      final results = await Future.wait([
        _dashboardService.getWalletBalance(),
        _dashboardService.getWheelTokens(),
        _dashboardService.getRecentTransactions(),
        _dashboardService.getTokenHistory(), // New service call
        _dashboardService.getFareExpensesWeekly(), // New service call
      ]);

      _balance = results[0] as double;
      _wheelTokens = results[1] as int;
      _transactions = results[2] as List<Map<String, dynamic>>;
      _tokenHistory = results[3] as List<Map<String, dynamic>>;
      _fareExpenses = results[4] as Map<String, double>;

      debugPrint('✅ Wallet data fetched successfully');
    } catch (e) {
      _errorMessage = 'Failed to load wallet data: $e';
      debugPrint('❌ Error in WalletProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
