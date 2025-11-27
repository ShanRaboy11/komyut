// lib/providers/transaction_provider.dart

import 'package:flutter/foundation.dart';
import '../models/transactions.dart';
import '../services/transactions.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionService _transactionService = TransactionService();

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, int> _transactionCounts = {};

  // Getters
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, int> get transactionCounts => _transactionCounts;

  /// Load all transactions or filter by type
  Future<void> loadTransactions({String? type, int limit = 200}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _transactions = await _transactionService.fetchTransactions(
        type: type,
        limit: limit,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _transactions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load transaction counts for all types
  Future<void> loadTransactionCounts() async {
    try {
      _transactionCounts = await _transactionService.getTransactionCounts();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load transaction counts: $e');
    }
  }

  /// Get filtered transactions by type
  List<TransactionModel> getTransactionsByType(String type) {
    return _transactions.where((tx) => tx.type == type).toList();
  }

  /// Get transaction count for a specific type
  int getCountForType(String type) {
    return _transactions.where((tx) => tx.type == type).length;
  }

  /// Refresh transactions
  Future<void> refresh({String? type}) async {
    await loadTransactions(type: type);
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Update a transaction's status and refresh local state
  Future<void> updateTransactionStatus(String id, String status) async {
    try {
      await _transactionService.updateTransactionStatus(id, status);
      // Optimistically update local list
      _transactions = _transactions.map((tx) {
        if (tx.id == id) {
          return TransactionModel(
            id: tx.id,
            transactionNumber: tx.transactionNumber,
            walletId: tx.walletId,
            initiatedByProfileId: tx.initiatedByProfileId,
            type: tx.type,
            amount: tx.amount,
            fee: tx.fee,
            status: status,
            relatedTripId: tx.relatedTripId,
            externalReference: tx.externalReference,
            metadata: tx.metadata,
            createdAt: tx.createdAt,
            processedAt: tx.processedAt,
            initiatorName: tx.initiatorName,
            driverName: tx.driverName,
            passengerName: tx.passengerName,
            routeCode: tx.routeCode,
            plateNumber: tx.plateNumber,
            operatorName: tx.operatorName,
            numPassengers: tx.numPassengers,
          );
        }
        return tx;
      }).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Get pending digital cash-in transactions (metadata contains payment_method)
  List<TransactionModel> getPendingDigitalCashIns() {
    return _transactions.where((tx) {
      final status = tx.status.toLowerCase();
      final isDigital = (tx.metadata ?? const {})['payment_method'] != null;
      return tx.type == 'cash_in' && status == 'pending' && isDigital;
    }).toList();
  }

  /// Search transactions by transaction number or initiator name
  List<TransactionModel> searchTransactions(String query) {
    if (query.isEmpty) return _transactions;

    final lowerQuery = query.toLowerCase();
    return _transactions.where((tx) {
      final transactionNumber = tx.transactionNumber?.toLowerCase() ?? '';
      final initiatorName = tx.initiatorName?.toLowerCase() ?? '';
      final passengerName = tx.passengerName?.toLowerCase() ?? '';
      final driverName = tx.driverName?.toLowerCase() ?? '';

      return transactionNumber.contains(lowerQuery) ||
          initiatorName.contains(lowerQuery) ||
          passengerName.contains(lowerQuery) ||
          driverName.contains(lowerQuery);
    }).toList();
  }

  /// Filter transactions by date range
  List<TransactionModel> filterByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return _transactions.where((tx) {
      return tx.createdAt.isAfter(startDate) && tx.createdAt.isBefore(endDate);
    }).toList();
  }

  /// Get total amount for a specific transaction type
  double getTotalAmountForType(String type) {
    return _transactions
        .where((tx) => tx.type == type)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  /// Get transactions by status
  List<TransactionModel> getTransactionsByStatus(String status) {
    return _transactions.where((tx) => tx.status == status).toList();
  }
}
