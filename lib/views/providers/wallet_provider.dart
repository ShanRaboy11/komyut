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

  // --- State for TransactionHistoryPage ---
  bool _isHistoryLoading = false;
  String? _historyErrorMessage;
  List<Map<String, dynamic>> _fullHistory = [];

  // --- State for Cash-In Flow ---
  bool _isCashInLoading = false;
  String? _cashInErrorMessage;
  Map<String, dynamic>? _pendingTransaction;

  // --- State for Completion Flow ---
  bool _isCompletionLoading = false;
  String? _completionErrorMessage;

  // --- Getters ---
  bool get isWalletLoading => _isWalletLoading;
  String? get walletErrorMessage => _walletErrorMessage;
  double get balance => _balance;
  int get wheelTokens => _wheelTokens;
  List<Map<String, dynamic>> get recentTransactions => _recentTransactions;
  List<Map<String, dynamic>> get recentTokenHistory => _recentTokenHistory;
  Map<String, double> get fareExpenses => _fareExpenses;

  bool get isHistoryLoading => _isHistoryLoading;
  String? get historyErrorMessage => _historyErrorMessage;
  List<Map<String, dynamic>> get fullHistory => _fullHistory;

  bool get isCashInLoading => _isCashInLoading;
  String? get cashInErrorMessage => _cashInErrorMessage;
  Map<String, dynamic>? get pendingTransaction => _pendingTransaction;

  bool get isCompletionLoading => _isCompletionLoading;
  String? get completionErrorMessage => _completionErrorMessage;

  // --- Methods ---

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

  Future<void> fetchFullHistory(HistoryType type) async {
    _isHistoryLoading = true;
    _historyErrorMessage = null;
    _fullHistory = [];
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

  // --- THIS IS THE CORRECTED METHOD ---
  Future<bool> createOtcTransaction({
    required double amount,
    required String transactionCode,
  }) async {
    _isCashInLoading = true;
    _cashInErrorMessage = null;
    notifyListeners();

    try {
      _pendingTransaction = await _dashboardService.createCashInTransaction(
        amount: amount,
        // The name must exactly match the 'name' column in your payment_methods table
        paymentMethodName: 'Over-the-Counter',
        transactionNumber: transactionCode,
      );
      _isCashInLoading = false;
      notifyListeners();
      return true; // Success
    } catch (e) {
      _cashInErrorMessage = 'Error: ${e.toString()}';
      _isCashInLoading = false;
      notifyListeners();
      return false; // Failure
    }
  }

  // --- FOR OTC COMPLETION ---
  Future<bool> completeOtcCashIn({required String transactionId}) async {
    _isCompletionLoading = true;
    _completionErrorMessage = null;
    notifyListeners();

    try {
      await _dashboardService.completeCashInTransaction(
        transactionId: transactionId,
      );
      await fetchWalletData();
      _isCompletionLoading = false;
      notifyListeners();
      return true; // Success
    } catch (e) {
      _completionErrorMessage =
          'Failed to complete transaction: ${e.toString()}';
      _isCompletionLoading = false;
      notifyListeners();
      return false; // Failure
    }
  }

  // --- DIGITAL WALLET TRANSACTION METHOD ---
  Future<bool> createDigitalWalletTransaction({
    required double amount,
    required String source, // The specific source like 'GCash Bills Pay'
    required String transactionCode,
  }) async {
    _isCashInLoading = true;
    _cashInErrorMessage = null;
    notifyListeners();

    try {
      // We re-use the same generic service method, which is great!
      _pendingTransaction = await _dashboardService.createCashInTransaction(
        amount: amount,
        paymentMethodName: source, // Pass the dynamic source from the UI
        transactionNumber: transactionCode,
      );
      _isCashInLoading = false;
      notifyListeners();
      return true; // Success
    } catch (e) {
      _cashInErrorMessage = 'Error: ${e.toString()}';
      _isCashInLoading = false;
      notifyListeners();
      return false; // Failure
    }
  }
}
