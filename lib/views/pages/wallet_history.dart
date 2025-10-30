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

  void _showCashInDetailModal(
    BuildContext context,
    Map<String, dynamic> transaction,
  ) {
    final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
    final total = amount + 5.0;
    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: 'P');

    // --- FIX: Read the payment method name from the joined table data ---
    final paymentMethod = transaction['payment_methods'];
    final channelDisplay =
        (paymentMethod != null && paymentMethod['name'] != null)
        ? paymentMethod['name'] as String
        // Fallback for older transactions or different types
        : (transaction['type'] as String)
              .split('_')
              .map((e) => e[0].toUpperCase() + e.substring(1))
              .join(' ');

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (dialogContext) {
        return _buildDetailModal(
          context: dialogContext,
          title: 'Cash In Transaction',
          details: [
            _buildDetailRow(
              'Date:',
              DateFormat(
                'MM/dd/yyyy',
              ).format(DateTime.parse(transaction['created_at'])),
            ),
            _buildDetailRow(
              'Time:',
              DateFormat(
                'hh:mm a',
              ).format(DateTime.parse(transaction['created_at'])),
            ),
            _buildDetailRow('Amount:', currencyFormat.format(amount)),
            _buildDetailRow(
              'Channel:',
              channelDisplay,
            ), // Now uses the corrected value
          ],
          totalRow: _buildDetailRow('Total:', currencyFormat.format(total)),
          transactionCode:
              transaction['transaction_number'] ?? _generateTransactionCode(),
        );
      },
    );
  }

  void _showTokenRedemptionModal(
    BuildContext context,
    Map<String, dynamic> tokenData,
  ) {
    final amount = (tokenData['amount'] as num?)?.toDouble() ?? 0.0;
    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: 'P');

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (dialogContext) {
        return _buildDetailModal(
          context: dialogContext,
          title: 'Token Redemption',
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
                    amount.toStringAsFixed(1),
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
          transactionCode: _generateTransactionCode(),
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

  Widget _buildDetailRow(String label, dynamic value) {
    final isValueWidget = value is Widget;
    final isTotal = (label == 'Total:' || label == 'Equivalent:');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 15,
              color: isTotal ? Colors.black87 : Colors.grey[600],
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
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
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
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
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isTransactions ? 'Transactions' : 'Tokens',
          style: GoogleFonts.manrope(
            fontSize: 22,
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
                fontSize: 20,
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
                    final isLast = index == provider.fullHistory.length - 1;
                    return isTransactions
                        ? _buildTransactionItem(context, item, isLast: isLast)
                        : _buildTokenItem(context, item, isLast: isLast);
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
    Map<String, dynamic> transaction, {
    bool isLast = false,
  }) {
    final bool isCredit = (transaction['amount'] as num) >= 0;

    // --- FIX: Get title from the new data structure ---
    final paymentMethod = transaction['payment_methods'];
    final String title =
        (paymentMethod != null && paymentMethod['name'] != null)
        ? paymentMethod['name']
        : (transaction['type'] as String)
              .split('_')
              .map((word) => word[0].toUpperCase() + word.substring(1))
              .join(' ');

    final String amount = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
    ).format(transaction['amount']);
    final String date = DateFormat(
      'MM/d/yy hh:mm a',
    ).format(DateTime.parse(transaction['created_at']));

    return InkWell(
      onTap: () => _showCashInDetailModal(context, transaction),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isLast ? Colors.transparent : Colors.grey[200]!,
            ),
          ),
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
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: GoogleFonts.nunito(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
            Text(
              (isCredit ? '+' : '') + amount,
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isCredit
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFC62828),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenItem(
    BuildContext context,
    Map<String, dynamic> tokenData, {
    bool isLast = false,
  }) {
    final bool isCredit = (tokenData['amount'] as num) >= 0;
    final String title = (tokenData['type'] as String) == 'redemption'
        ? 'Token Redemption'
        : 'Trip Reward';
    final double amount = (tokenData['amount'] as num).toDouble();
    final String date = DateFormat(
      'MM/d/yy hh:mm a',
    ).format(DateTime.parse(tokenData['created_at']));

    return InkWell(
      onTap: () => _showTokenRedemptionModal(context, tokenData),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isLast ? Colors.transparent : Colors.grey[200]!,
            ),
          ),
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
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: GoogleFonts.nunito(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  '${isCredit ? '+' : ''}${amount.toStringAsFixed(1)}',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
