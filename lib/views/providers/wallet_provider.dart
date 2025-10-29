import 'package:flutter/foundation.dart';
import '../services/commuter_dashboard.dart';
import '../pages/wallet_history.dart';

class WalletProvider extends ChangeNotifier {
  final CommuterDashboardService _dashboardService = CommuterDashboardService();

  // --- State for WalletPage ---
  bool _isWalletLoading = false;
  String? _walletErrorMessage;
  double _balance = 0.0;
  int _wheelTokens = 0;
  List<Map<String, dynamic>> _recentTransactions = [];
  List<Map<String, dynamic>> _recentTokenHistory = [];
  Map<String, double> _fareExpenses = {};

  // --- State for TransactionHistoryPage (This was missing) ---
  bool _isHistoryLoading = false;
  String? _historyErrorMessage;
  List<Map<String, dynamic>> _fullHistory = [];

  // --- Getters for WalletPage ---
  bool get isWalletLoading => _isWalletLoading;
  String? get walletErrorMessage => _walletErrorMessage;
  double get balance => _balance;
  int get wheelTokens => _wheelTokens;
  List<Map<String, dynamic>> get recentTransactions => _recentTransactions;
  List<Map<String, dynamic>> get recentTokenHistory => _recentTokenHistory;
  Map<String, double> get fareExpenses => _fareExpenses;

  // --- Getters for TransactionHistoryPage
  bool get isHistoryLoading => _isHistoryLoading;
  String? get historyErrorMessage => _historyErrorMessage;
  List<Map<String, dynamic>> get fullHistory => _fullHistory;

  // Method for WalletPage
  Future<void> fetchWalletData() async {
    _isWalletLoading = true;
    _walletErrorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _dashboardService.getWalletBalance(),
        _dashboardService.getWheelTokens(),
        _dashboardService.getRecentTransactions(),
        _dashboardService.getTokenHistory(),
        _dashboardService.getFareExpensesWeekly(),
      ]);
      _balance = results[0] as double;
      _wheelTokens = results[1] as int;
      _recentTransactions = results[2] as List<Map<String, dynamic>>;
      _recentTokenHistory = results[3] as List<Map<String, dynamic>>;
      _fareExpenses = results[4] as Map<String, double>;
    } catch (e) {
      _walletErrorMessage = 'Failed to load wallet data: $e';
    } finally {
      _isWalletLoading = false;
      notifyListeners();
    }
  }

  // Method for TransactionHistoryPage
  Future<void> fetchFullHistory(HistoryType type) async {
    _isHistoryLoading = true;
    _historyErrorMessage = null;
    _fullHistory = []; // Clear previous history
    notifyListeners();
    try {
      if (type == HistoryType.transactions) {
        _fullHistory = await _dashboardService.getAllTransactions();
      } else {
        _fullHistory = await _dashboardService.getAllTokenHistory();
      }
    } catch (e) {
      _historyErrorMessage = 'Failed to load history: $e';
    } finally {
      _isHistoryLoading = false;
      notifyListeners();
    }
  }
}
