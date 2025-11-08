import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:barcode_widget/barcode_widget.dart';

import '../providers/wallet_provider.dart';

class WalletHistoryDriverPage extends StatefulWidget {
  const WalletHistoryDriverPage({super.key});

  @override
  State<WalletHistoryDriverPage> createState() =>
      _WalletHistoryDriverPageState();
}

class _WalletHistoryDriverPageState extends State<WalletHistoryDriverPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DriverWalletProvider>(
        context,
        listen: false,
      ).fetchFullDriverHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
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
          'Transactions',
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
              'All Transactions',
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Consumer<DriverWalletProvider>(
              builder: (context, provider, child) {
                if (provider.isHistoryLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.errorMessage != null) {
                  return Center(child: Text(provider.errorMessage!));
                }
                if (provider.allTransactions.isEmpty) {
                  return const Center(child: Text('No history found.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 100.0),
                  itemCount: provider.allTransactions.length,
                  itemBuilder: (context, index) {
                    final item = provider.allTransactions[index];
                    final isLast = index == provider.allTransactions.length - 1;
                    return _TransactionItem(transaction: item, isLast: isLast);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final bool isLast;

  const _TransactionItem({required this.transaction, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    final String type = transaction['type'] ?? 'fare_payment';
    final double amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;

    final bool isEarning = type == 'fare_payment';
    final String title = isEarning ? 'Trip Earning' : 'Remittance';
    final Color amountColor = isEarning
        ? const Color(0xFF2E7D32)
        : const Color(0xFFC62828);
    final String date = DateFormat(
      'MM/d/yy hh:mm a',
    ).format(DateTime.parse(transaction['created_at']));

    return InkWell(
      onTap: () => _showTransactionDetailModal(context, transaction),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
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
              '${amount >= 0 ? '+' : ''}${currencyFormat.format(amount)}',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetailModal(
    BuildContext context,
    Map<String, dynamic> transaction,
  ) {
    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    final String type = transaction['type'] ?? 'fare_payment';
    final double amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
    final bool isEarning = type == 'fare_payment';
    final String modalTitle = isEarning ? 'Trip Earning' : 'Remittance';

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (dialogContext) => _buildDetailModal(
        context: dialogContext,
        title: modalTitle,
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
        ],
        totalRow: _buildDetailRow(
          'Amount:',
          currencyFormat.format(amount.abs()),
          isTotal: true,
        ),
        transactionCode: transaction['transaction_number'] ?? 'N/A',
      ),
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
}
