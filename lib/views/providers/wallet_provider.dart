import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import '../services/commuter_dashboard.dart';
import '../pages/wallet_history.dart';

class WalletProvider extends ChangeNotifier {
  final CommuterDashboardService _dashboardService = CommuterDashboardService();
  final String _baseUrl = 'http://192.168.1.13:8000/api';

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

  // --- State for sending instructions
  bool _isSendingInstructions = false;
  bool get isSendingInstructions => _isSendingInstructions;

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
        _dashboardService.getRecentTokens(),
        _dashboardService.getFareExpensesWeekly(),
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
    if (_userProfile != null) return;

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

  // NEW METHOD for sending payment instructions
  Future<void> sendPaymentInstructions({
    required String name,
    required String email,
    required double amount,
    required String source,
  }) async {
    _isSendingInstructions = true;
    notifyListeners();

    final String emailBody = _generateEmailBody(name, amount, source);
    final String subject = 'Komyut: Payment Instructions for $source';

    final url = Uri.parse('$_baseUrl/send-payment-instructions');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'to': email, 'subject': subject, 'html': emailBody}),
      );

      await Future.delayed(const Duration(seconds: 2));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to send instructions. Server responded with ${response.statusCode}',
        );
      }
    } catch (e) {
      // --- FIX #2: Removed the print() statement ---
      // The error is still thrown, so the UI can catch it and show a message.
      // ---------------------------------------------
      throw Exception(
        'Could not send instructions. Please check your connection and try again.',
      );
    } finally {
      _isSendingInstructions = false;
      notifyListeners();
    }
  }

  // Helper method to generate email body
  String _generateEmailBody(String name, double amount, String source) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_PH',
      symbol: 'PHP',
    );
    final formattedAmount = currencyFormat.format(amount);

    String instructions = _getInstructionsForSource(source, formattedAmount);

    return """
    <p>Dear $name,</p>
    <p>Good day and thank you for choosing our service. Please find your payment instructions below for your cash-in request of <strong>$formattedAmount</strong>.</p>
    <hr>
    <h3>Payment via $source</h3>
    $instructions
    <hr>
    <p>Please ensure you complete the payment within 24 hours. The amount will be credited to your komyut wallet upon confirmation.</p>
    <p>For payment-specific inquiries, you may call, email or chat with us.</p>
    <br>
    <p>Sincerely,<br><strong>komyut</strong></p>
    """;
  }

  // Helper method for source-specific instructions
  String _getInstructionsForSource(String source, String formattedAmount) {
    switch (source) {
      case 'GCash':
        return """
        <p>Please transfer exactly <strong>$formattedAmount</strong> to the following GCash account:</p>
        <ul>
          <li><strong>Account Name:</strong> Komyut Inc.</li>
          <li><strong>Account Number:</strong> 0917-123-4567</li>
        </ul>
        <p><strong>IMPORTANT:</strong> After sending, please take a screenshot of your transaction receipt and reply to this email with the screenshot attached for verification.</p>
        """;
      case 'Maya':
        return """
        <p>Please transfer exactly <strong>$formattedAmount</strong> to the following Maya account:</p>
        <ul>
          <li><strong>Account Name:</strong> Komyut Inc.</li>
          <li><strong>Account Number:</strong> 0918-123-4567</li>
        </ul>
        <p><strong>IMPORTANT:</strong> After transferring, please save your transaction receipt and reply to this email with a screenshot for faster verification.</p>
        """;
      case 'BPI':
      case 'BPI Direct BanKo':
        return """
        <p>Please transfer exactly <strong>$formattedAmount</strong> to the following BPI account via BPI Online or the BPI Mobile App:</p>
        <ul>
          <li><strong>Account Name:</strong> Komyut Inc.</li>
          <li><strong>Account Number:</strong> 1234-5678-90</li>
          <li><strong>Account Type:</strong> Savings</li>
        </ul>
        <p><strong>NOTE:</strong> Please use your User ID as the reference number. After payment, reply to this email with the transaction confirmation.</p>
        """;
      case 'BDO':
        return """
        <p>Please transfer exactly <strong>$formattedAmount</strong> to the following BDO account via BDO Online Banking:</p>
        <ul>
          <li><strong>Account Name:</strong> komyut Inc.</li>
          <li><strong>Account Number:</strong> 001230987654</li>
          <li><strong>Account Type:</strong> Savings</li>
        </ul>
        <p><strong>NOTE:</strong> In the remarks section, please enter your full name. Keep a copy of the transaction confirmation.</p>
        """;
      default:
        return "<p>Automated instructions for $source are not available. Please contact support for assistance.</p>";
    }
  }
}
