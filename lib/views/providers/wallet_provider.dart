import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/commuter_dashboard.dart';
import '../services/auth_service.dart';
import '../services/driver_dashboard.dart';
import '../services/operator_dashboard.dart';
import '../pages/wallet_history_commuter.dart';

import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WalletProvider extends ChangeNotifier {
  final CommuterDashboardService _dashboardService = CommuterDashboardService();
  final AuthService authService = AuthService();

  final String _baseUrl = Platform.isAndroid
      ? 'http://10.0.2.2:3000'
      : 'http://localhost:3000';

  // --- State for WalletPage ---
  bool _isWalletLoading = false;
  String? _walletErrorMessage;
  double _balance = 0.0;
  double _wheelTokens = 0;
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

  // --- State for Payment Sources Flow ---
  bool _isSourcesLoading = false;
  String? _sourcesErrorMessage;
  List<String> _paymentSources = [];

  // --- State for User Profile ---
  bool _isProfileLoading = false;
  String? _profileErrorMessage;
  Map<String, dynamic>? _userProfile;

  bool _isFareExpensesLoading = false;

  // --- Getters ---
  bool get isWalletLoading => _isWalletLoading;
  String? get walletErrorMessage => _walletErrorMessage;
  double get balance => _balance;
  double get wheelTokens => _wheelTokens;
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

  bool get isSourcesLoading => _isSourcesLoading;
  String? get sourcesErrorMessage => _sourcesErrorMessage;
  List<String> get paymentSources => _paymentSources;

  bool get isProfileLoading => _isProfileLoading;
  String? get profileErrorMessage => _profileErrorMessage;
  Map<String, dynamic>? get userProfile => _userProfile;

  bool _isSendingInstructions = false;
  bool get isSendingInstructions => _isSendingInstructions;

  bool get isFareExpensesLoading => _isFareExpensesLoading;

  // --- Methods ---
  WalletProvider() {
    _authSub = authService.authStateChanges.listen((event) {
      final user = event.session?.user;
      if (user == null) {
        _userProfile = null;
        _balance = 0.0;
        _wheelTokens = 0;
        _recentTransactions = [];
        notifyListeners();
      } else {
        _maybeLoadForUser(user.id);
      }
    });
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
    debugPrint('WalletProvider: user $userId role=$role');
    if (role == 'commuter') {
      await fetchWalletData();
    } else {
      _userProfile = null;
      _balance = 0.0;
      _wheelTokens = 0;
      _recentTransactions = [];
      notifyListeners();
    }
  }

  StreamSubscription? _authSub;

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> fetchWalletData() async {
    _isWalletLoading = true;
    _walletErrorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _dashboardService.getWalletBalance(),
        _dashboardService.getWheelTokens(),
        _dashboardService.getRecentTransactions(),
        _dashboardService.getRecentTokens(),
        _dashboardService.getFareExpensesWeekly(weekOffset: 0),
      ]);
      _balance = (results[0] as num).toDouble();
      _wheelTokens = (results[1] as num).toDouble();
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
        _fullHistory = await _dashboardService.getAllTokens();
      }
    } catch (e) {
      _historyErrorMessage = 'Failed to load history: $e';
    } finally {
      _isHistoryLoading = false;
      notifyListeners();
    }
  }

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
        paymentMethodName: 'Over-the-Counter',
        transactionNumber: transactionCode,
        payerName: 'User',
        payerEmail: 'N/A',
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

  Future<bool> createDigitalWalletTransaction({
    required double amount,
    required String source,
    required String transactionCode,
    required String payerName,
    required String payerEmail,
  }) async {
    _isCashInLoading = true;
    _cashInErrorMessage = null;
    notifyListeners();

    try {
      _pendingTransaction = await _dashboardService.createCashInTransaction(
        amount: amount,
        paymentMethodName: source,
        transactionNumber: transactionCode,
        payerName: payerName,
        payerEmail: payerEmail,
      );
      await fetchWalletData();
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

  Future<void> fetchPaymentSources(String type) async {
    _isSourcesLoading = true;
    _sourcesErrorMessage = null;
    _paymentSources = [];
    notifyListeners();

    try {
      _paymentSources = await _dashboardService.getPaymentSourcesByType(type);
    } catch (e) {
      _sourcesErrorMessage = 'Failed to load payment sources: ${e.toString()}';
    } finally {
      _isSourcesLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserProfile() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (_userProfile != null) {
      final cachedUserId = _userProfile?['user_id'] ?? _userProfile?['id'];
      if (cachedUserId != null && cachedUserId == currentUserId) return;
    }

    _isProfileLoading = true;
    _profileErrorMessage = null;
    notifyListeners();

    try {
      _userProfile = await _dashboardService.getCommuterProfile();
    } catch (e) {
      _profileErrorMessage = 'Failed to load user profile: ${e.toString()}';
    } finally {
      _isProfileLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserNameForForm() async {
    _isProfileLoading = true;
    _profileErrorMessage = null;
    notifyListeners();

    try {
      _userProfile = await _dashboardService.getCommuterName();
    } catch (e) {
      _profileErrorMessage = 'Failed to load user name: ${e.toString()}';
    } finally {
      _isProfileLoading = false;
      notifyListeners();
    }
  }

  Future<bool> redeemWheelTokens({
    required double amount,
    required String transactionCode,
  }) async {
    _isCompletionLoading = true;
    _completionErrorMessage = null;
    notifyListeners();

    try {
      await _dashboardService.redeemTokens(
        amount: amount,
        transactionNumber: transactionCode,
      );

      await fetchWalletData();

      _isCompletionLoading = false;
      notifyListeners();
      return true; // Success
    } catch (e) {
      _completionErrorMessage = 'Redemption failed: ${e.toString()}';
      _isCompletionLoading = false;
      notifyListeners();
      return false; // Failure
    }
  }

  Future<void> sendPaymentInstructions({
    required String name,
    required String email,
    required double amount,
    required String source,
    required String userId,
    required String transactionCode,
  }) async {
    _isSendingInstructions = true;
    notifyListeners();

    final url = Uri.parse('$_baseUrl/send-payment-instructions');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'amount': amount,
          'source': source,
          'userId': userId,
          'transactionCode': transactionCode,
        }),
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        throw Exception('Failed to send instructions: ${errorBody['error']}');
      }
    } catch (e) {
      throw Exception('Could not send instructions. Please try again.');
    } finally {
      _isSendingInstructions = false;
      notifyListeners();
    }
  }

  Future<void> fetchFareExpensesForWeek(int offset) async {
    _isFareExpensesLoading = true;
    notifyListeners();
    try {
      _fareExpenses = await _dashboardService.getFareExpensesWeekly(
        weekOffset: offset,
      );
    } catch (e) {
      debugPrint('Failed to load fare expenses for offset $offset: $e');
      _fareExpenses = {};
    } finally {
      _isFareExpensesLoading = false;
      notifyListeners();
    }
  }
}

class DriverWalletProvider extends ChangeNotifier {
  final DriverDashboardService _dashboardService = DriverDashboardService();

  // Loading states
  bool _isPageLoading = false;
  bool _isChartLoading = false;
  bool _isHistoryLoading = false;
  String? _errorMessage;

  // Data
  double _totalBalance = 0.0;
  double _todayEarnings = 0.0;
  String _operatorName = '';
  Map<String, double> _weeklyEarnings = {};
  List<Map<String, dynamic>> _recentTransactions = [];
  List<Map<String, dynamic>> _allTransactions = [];

  // Getters
  bool get isPageLoading => _isPageLoading;
  bool get isChartLoading => _isChartLoading;
  bool get isHistoryLoading => _isHistoryLoading;
  String? get errorMessage => _errorMessage;

  double get totalBalance => _totalBalance;
  double get todayEarnings => _todayEarnings;
  String get operatorName => _operatorName;
  Map<String, double> get weeklyEarnings => _weeklyEarnings;
  List<Map<String, dynamic>> get recentTransactions => _recentTransactions;
  List<Map<String, dynamic>> get allTransactions => _allTransactions;

  Future<void> fetchWalletData() async {
    _isPageLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _dashboardService.getWalletBalance(),
        _dashboardService.getTodayEarnings(),
        _dashboardService.getWeeklyEarnings(weekOffset: 0),
        _dashboardService.getRecentTransactions(),
        _dashboardService.getDriverVehicleInfo(),
      ]);

      _totalBalance = (results[0] as num).toDouble();
      _todayEarnings = (results[1] as num).toDouble();
      _weeklyEarnings = results[2] as Map<String, double>;
      _recentTransactions = results[3] as List<Map<String, dynamic>>;

      final vehicleInfo = results[4] as Map<String, dynamic>;
      _operatorName = vehicleInfo['operator_name'] ?? 'Unknown Operator';
    } catch (e) {
      _errorMessage = 'Failed to load wallet data: $e';
    } finally {
      _isPageLoading = false;
      notifyListeners();
    }
  }

  /// Fetches earnings for a specific week
  Future<void> fetchWeeklyEarnings(int offset) async {
    _isChartLoading = true;
    notifyListeners();
    try {
      _weeklyEarnings = await _dashboardService.getWeeklyEarnings(
        weekOffset: offset,
      );
    } catch (e) {
      debugPrint('Failed to load weekly earnings for offset $offset: $e');
      _weeklyEarnings = {};
    } finally {
      _isChartLoading = false;
      notifyListeners();
    }
  }

  /// Fetches transaction history
  Future<void> fetchFullDriverHistory() async {
    _isHistoryLoading = true;
    _errorMessage = null;
    _allTransactions = [];
    notifyListeners();
    try {
      _allTransactions = await _dashboardService.getAllTransactions();
    } catch (e) {
      _errorMessage = 'Failed to load history: $e';
    } finally {
      _isHistoryLoading = false;
      notifyListeners();
    }
  }

  /// Process Remittance
  Future<bool> submitRemittance(double amount, String transactionCode) async {
    if (amount <= 0) {
      _errorMessage = 'Amount must be greater than 0';
      notifyListeners();
      return false;
    }

    if (amount > _totalBalance) {
      _errorMessage = 'Insufficient balance';
      notifyListeners();
      return false;
    }

    _isPageLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _dashboardService.remitEarnings(amount, transactionCode);

      await fetchWalletData();

      _isPageLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Remittance failed: ${e.toString()}';
      _isPageLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Process Cash Out
  Future<bool> requestCashOut({
    required double amount,
    required String transactionCode,
  }) async {
    _isPageLoading = true;
    notifyListeners();
    try {
      await _dashboardService.requestCashOut(
        amount: amount,
        transactionCode: transactionCode,
      );
      await fetchWalletData();
      _isPageLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isPageLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeCashOut(String transactionCode) async {
    _isPageLoading = true;
    notifyListeners();
    try {
      await _dashboardService.completeCashOut(transactionCode);
      await fetchFullDriverHistory();
      _isPageLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint(e.toString());
      _isPageLoading = false;
      notifyListeners();
      return false;
    }
  }
}

class OperatorWalletProvider extends ChangeNotifier {
  final OperatorDashboardService _service = OperatorDashboardService();

  bool _isLoading = false;
  bool _isHistoryLoading = false;
  bool _isChartLoading = false;

  double _currentBalance = 0.0;
  Map<String, double> _weeklyEarnings = {};
  List<Map<String, dynamic>> _recentTransactions = [];
  List<Map<String, dynamic>> _allTransactions = [];

  // Getters
  bool get isLoading => _isLoading;
  bool get isHistoryLoading => _isHistoryLoading;
  bool get isChartLoading => _isChartLoading;
  double get currentBalance => _currentBalance;
  Map<String, double> get weeklyEarnings => _weeklyEarnings;
  List<Map<String, dynamic>> get recentTransactions => _recentTransactions;
  List<Map<String, dynamic>> get allTransactions => _allTransactions;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadWalletDashboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getWalletBalance(),
        _service.getWeeklyEarnings(weekOffset: 0),
        _service.getTransactions(limit: 5),
      ]);

      _currentBalance = results[0] as double;
      _weeklyEarnings = results[1] as Map<String, double>;
      _recentTransactions = results[2] as List<Map<String, dynamic>>;

      _recentTransactions.sort(
        (a, b) =>
            DateTime.parse(b["date"]).compareTo(DateTime.parse(a["date"])),
      );

      debugPrint("💰 Dashboard Loaded: ${_recentTransactions.length} recent");
    } catch (e) {
      debugPrint("❌ Wallet Provider Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshRecentTransactions() async {
    try {
      _recentTransactions = await _service.getTransactions(limit: 5);
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to refresh recent transactions: $e");
    }
  }

  Future<void> refreshWallet() async {
    try {
      await loadWalletDashboard();
    } catch (e) {
      debugPrint("❌ Refresh Wallet Error: $e");
    }
  }

  Future<void> fetchWeeklyEarnings(int offset) async {
    _isChartLoading = true;
    notifyListeners();
    try {
      _weeklyEarnings = await _service.getWeeklyEarnings(weekOffset: offset);
    } catch (e) {
      debugPrint("Chart error: $e");
    } finally {
      _isChartLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFullHistory() async {
    _isHistoryLoading = true;
    notifyListeners();

    try {
      _allTransactions = await _service.getTransactions(limit: 50);
      debugPrint("📜 History Loaded: ${_allTransactions.length} items");
    } catch (e) {
      debugPrint("❌ History Error: $e");
    } finally {
      _isHistoryLoading = false;
      notifyListeners();
    }
  }

  Future<bool> requestCashOut({
    required double amount,
    required String transactionCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.requestCashOut(
        amount: amount,
        transactionCode: transactionCode,
      );

      await loadWalletDashboard();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeCashOut(String transactionCode) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.completeCashOut(transactionCode);

      await loadWalletDashboard();
      await refreshRecentTransactions();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Cashout error: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
