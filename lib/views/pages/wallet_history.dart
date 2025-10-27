import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'package:barcode_widget/barcode_widget.dart';

// An enum to make our code cleaner and safer.
enum HistoryType { transactions, tokens }

class TransactionHistoryPage extends StatelessWidget {
  final HistoryType type;

  const TransactionHistoryPage({super.key, required this.type});

  // Dummy data for a long list
  List<Map<String, dynamic>> get _dummyTransactions => List.generate(14, (i) {
    bool isCashIn = i == 0 || i == 13;
    return {
      'title': isCashIn ? 'Cash In' : 'Trip Fare',
      'subtitle': '10/${i % 2 + 2}/25 ${i % 5 + 1}:${i * 4} PM',
      'amount': isCashIn ? '+₱100.00' : '−₱13.00',
      'isCredit': isCashIn,
    };
  });

  List<Map<String, dynamic>> get _dummyTokens => List.generate(14, (i) {
    bool isReward = i % 2 != 0;
    return {
      'title': isReward ? 'Trip Reward' : 'Token Redemption',
      'subtitle': '10/${i % 3 + 1}/25 ${i % 6 + 1}:${i * 3} PM',
      'amount': isReward ? '+0.5' : '-${(i % 5 + 1)}.0',
      'isCredit': isReward,
    };
  });

  void _showCashInDetailModal(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (dialogContext) {
        return _buildDetailModal(
          context: dialogContext,
          title: 'Cash In Transaction',
          details: [
            _buildDetailRow('Date:', '10/04/2025'),
            _buildDetailRow('Time:', '10:45 AM'),
            _buildDetailRow('Amount:', 'P100.00'),
            _buildDetailRow('Channel:', 'GCash'),
          ],
          totalRow: _buildDetailRow('Total:', 'P105.00'),
          transactionCode: 'AHR231-DS31213',
        );
      },
    );
  }

  void _showTokenRedemptionModal(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (dialogContext) {
        return _buildDetailModal(
          context: dialogContext,
          title: 'Token Redemption',
          details: [
            _buildDetailRow('Date:', '10/04/2025'),
            _buildDetailRow('Time:', '10:45 AM'),
            _buildDetailRow(
              'Amount:',
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/wheel token.png', height: 16),
                  const SizedBox(width: 6),
                  Text(
                    '10.0',
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
          totalRow: _buildDetailRow('Equivalent:', 'P10.00'),
          transactionCode: 'AHR231-DS31213',
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
          border: Border.all(color: brandColor.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: brandColor.withOpacity(0.1),
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
                Divider(color: brandColor.withOpacity(0.5), height: 24),
                ...details,
                Divider(color: brandColor.withOpacity(0.5), height: 24),
                totalRow,
                Divider(color: brandColor.withOpacity(0.5), height: 24),
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
    final bool isTransactions = type == HistoryType.transactions;
    final data = isTransactions ? _dummyTransactions : _dummyTokens;

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
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 100.0),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                final isLast = index == data.length - 1;
                return isTransactions
                    ? _buildTransactionItem(
                        context, // Pass context
                        item['title'],
                        item['subtitle'],
                        item['amount'],
                        item['isCredit'],
                        isLast: isLast,
                      )
                    : _buildTokenItem(
                        context, // Pass context
                        item['title'],
                        item['subtitle'],
                        item['amount'],
                        item['isCredit'],
                        isLast: isLast,
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
    String title,
    String subtitle,
    String amount,
    bool isCredit, {
    bool isLast = false,
  }) {
    return InkWell(
      onTap: () => _showCashInDetailModal(context),
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
                  subtitle,
                  style: GoogleFonts.nunito(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
            Text(
              amount,
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
    String title,
    String subtitle,
    String amount,
    bool isCredit, {
    bool isLast = false,
  }) {
    return InkWell(
      onTap: () => _showTokenRedemptionModal(context),
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
                  subtitle,
                  style: GoogleFonts.nunito(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  amount,
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
