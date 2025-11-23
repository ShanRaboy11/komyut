import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:intl/intl.dart';
import '../providers/wallet_provider.dart';

enum HistoryType { transactions, tokens }

class TransactionHistoryPage extends StatefulWidget {
  final HistoryType type;
  const TransactionHistoryPage({super.key, required this.type});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WalletProvider>(
        context,
        listen: false,
      ).fetchFullHistory(widget.type);
    });
  }

  String _generateTransactionCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final part1 = String.fromCharCodes(
      Iterable.generate(
        15,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
    return 'K0MYUT-XHS$part1'.substring(0, 25);
  }

  void _showTransactionDetailModal(
    BuildContext context,
    Map<String, dynamic> transaction,
  ) {
    final String type = transaction['type'] as String? ?? 'transaction';
    final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: 'P');

    String modalTitle = type
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');

    if (type != 'token_redemption') {
      modalTitle += ' Transaction';
    }

    List<Widget> details = [];
    Widget totalRow;

    details.add(
      _buildDetailRow(
        'Date:',
        DateFormat(
          'MM/dd/yyyy',
        ).format(DateTime.parse(transaction['created_at'])),
      ),
    );
    details.add(
      _buildDetailRow(
        'Time:',
        DateFormat('hh:mm a').format(DateTime.parse(transaction['created_at'])),
      ),
    );

    if (type == 'token_redemption') {
      totalRow = _buildDetailRow(
        'Amount:',
        currencyFormat.format(amount),
        isTotal: true,
      );
    } else if (type == 'cash_in') {
      details.add(_buildDetailRow('Amount:', currencyFormat.format(amount)));

      final paymentMethod = transaction['payment_methods'];
      final channelDisplay =
          (paymentMethod != null && paymentMethod['name'] != null)
          ? paymentMethod['name']
          : 'N/A';
      details.add(_buildDetailRow('Channel:', channelDisplay));

      final status = (transaction['status'] as String?) ?? 'N/A';
      details.add(
        _buildDetailRow(
          'Status:',
          status[0].toUpperCase() + status.substring(1),
        ),
      );

      double total = amount;
      if (channelDisplay == 'Over-the-Counter') {
        total += 5.0;
      } else {
        total += 10.0;
      }
      totalRow = _buildDetailRow(
        'Total:',
        currencyFormat.format(total),
        isTotal: true,
      );
    } else {
      totalRow = _buildDetailRow(
        'Amount:',
        currencyFormat.format(amount),
        isTotal: true,
      );
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (dialogContext) {
        return _buildDetailModal(
          context: dialogContext,
          title: modalTitle,
          details: details,
          totalRow: totalRow,
          transactionCode:
              transaction['transaction_number'] ?? _generateTransactionCode(),
        );
      },
    );
  }

  void _showTokenDetailModal(
    BuildContext context,
    Map<String, dynamic> tokenData,
  ) {
    final amount = (tokenData['amount'] as num?)?.toDouble() ?? 0.0;
    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: 'P');

    final String type = (tokenData['type'] as String?) ?? 'reward';
    final String modalTitle = type == 'redemption'
        ? 'Token Redemption'
        : 'Token Reward';

    final String transactionCode =
        tokenData['transaction_number'] as String? ??
        _generateTransactionCode();

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (dialogContext) {
        return _buildDetailModal(
          context: dialogContext,
          title: modalTitle,
          details: [
            _buildDetailRow(
              'Date:',
              DateFormat(
                'MM/dd/yyyy',
              ).format(DateTime.parse(tokenData['created_at'])),
            ),
            _buildDetailRow(
              'Time:',
              DateFormat(
                'hh:mm a',
              ).format(DateTime.parse(tokenData['created_at'])),
            ),
            _buildDetailRow(
              'Amount:',
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/wheel token.png', height: 16),
                  const SizedBox(width: 6),
                  Text(
                    amount.abs().toStringAsFixed(1),
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          totalRow: _buildDetailRow(
            'Equivalent:',
            currencyFormat.format(amount.abs()),
          ),
          transactionCode: transactionCode,
        );
      },
    );
  }

  Widget _buildDetailModal({
    required BuildContext context,
    required String title,
    required List<Widget> details,
    required Widget totalRow,
    required String transactionCode,
  }) {
    final Color brandColor = const Color(0xFF8E4CB6);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 30),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: brandColor.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: brandColor.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Divider(color: brandColor.withValues(alpha: 0.5), height: 24),
                ...details,
                Divider(color: brandColor.withValues(alpha: 0.5), height: 24),
                totalRow,
                Divider(color: brandColor.withValues(alpha: 0.5), height: 24),
                BarcodeWidget(
                  barcode: Barcode.code128(),
                  data: transactionCode,
                  height: 40,
                  drawText: false,
                ),
                const SizedBox(height: 8),
                Text(
                  transactionCode,
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 12,
                    color: Colors.black54,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            Positioned(
              top: -12,
              right: -12,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, color: brandColor, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value, {bool isTotal = false}) {
    final isValueWidget = value is Widget;

    final bool shouldBeBold =
        isTotal || (label == 'Total:' || label == 'Equivalent:');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 15,
              color: shouldBeBold ? Colors.black87 : Colors.grey[600],
              fontWeight: shouldBeBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isValueWidget)
            value
          else
            Text(
              value.toString(),
              style: GoogleFonts.manrope(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: shouldBeBold ? FontWeight.bold : FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isTransactions = widget.type == HistoryType.transactions;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FF),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isTransactions ? 'Transactions' : 'Tokens',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 16.0),
            child: Text(
              isTransactions ? 'All Transactions' : 'Token History',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Consumer<WalletProvider>(
              builder: (context, provider, child) {
                if (provider.isHistoryLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.historyErrorMessage != null) {
                  return Center(child: Text(provider.historyErrorMessage!));
                }
                if (provider.fullHistory.isEmpty) {
                  return Center(
                    child: Text(
                      'No history found.',
                      style: GoogleFonts.nunito(),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 100.0),
                  itemCount: provider.fullHistory.length,
                  itemBuilder: (context, index) {
                    final item = provider.fullHistory[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: isTransactions
                          ? _buildTransactionItem(context, item)
                          : _buildTokenItem(context, item),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    Map<String, dynamic> transaction,
  ) {
    final String type = transaction['type'] as String;
    final double rawAmount = (transaction['amount'] as num).toDouble();

    final bool isExpense = type == 'fare_payment' || rawAmount < 0;

    final String title = type
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');

    final String amountText = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
    ).format(rawAmount.abs());

    final String date = DateFormat(
      'MMM d, hh:mm a',
    ).format(DateTime.parse(transaction['created_at']));

    return InkWell(
      onTap: () => _showTransactionDetailModal(context, transaction),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: GoogleFonts.nunito(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Text(
              '${isExpense ? '-' : '+'}$amountText',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isExpense
                    ? const Color(0xFFC62828)
                    : const Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenItem(BuildContext context, Map<String, dynamic> tokenData) {
    final bool isCredit = (tokenData['amount'] as num) > 0;
    final String title = (tokenData['type'] as String) == 'redemption'
        ? 'Token Redemption'
        : 'Token Reward';
    final double amount = (tokenData['amount'] as num).toDouble();
    final String date = DateFormat(
      'MMM d, hh:mm a',
    ).format(DateTime.parse(tokenData['created_at']));

    return InkWell(
      onTap: () => _showTokenDetailModal(context, tokenData),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: GoogleFonts.nunito(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  '${isCredit ? '+' : ''}${amount.toStringAsFixed(1)}',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isCredit
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFC62828),
                  ),
                ),
                const SizedBox(width: 6),
                Image.asset('assets/images/wheel token.png', height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
