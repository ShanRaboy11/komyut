import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'operator_app.dart';

class OperatorCashOutConfirmPage extends StatefulWidget {
  final String amount;

  const OperatorCashOutConfirmPage({super.key, required this.amount});

  @override
  State<OperatorCashOutConfirmPage> createState() =>
      _OperatorCashOutConfirmPageState();
}

class _OperatorCashOutConfirmPageState
    extends State<OperatorCashOutConfirmPage> {
  late String _transactionCode;
  final double _fee = 15.00;
  bool _isLoading = false;

  final Color _brandColor = const Color(0xFF8E4CB6);

  @override
  void initState() {
    super.initState();
    _transactionCode = _generateTransactionCode();
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
    return 'K0MYUT-OCO$part1'.substring(0, 25);
  }

  Future<void> _onConfirmPressed() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);

      final transactionData = {
        'transaction_number': _transactionCode,
        'amount': widget.amount,
        'created_at': DateTime.now().toIso8601String(),
      };

      OperatorApp.navigatorKey.currentState?.pushNamed(
        '/cash_out_instructions',
        arguments: transactionData,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double amountValue = double.tryParse(widget.amount) ?? 0.0;
    final double totalValue = amountValue + _fee;
    final now = DateTime.now();
    final date = DateFormat('MM/dd/yyyy').format(now);
    final time = DateFormat('hh:mm a').format(now);

    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: 'P');
    final String formattedAmount = currencyFormat.format(amountValue);
    final String formattedTotal = currencyFormat.format(totalValue);

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
          'Cash Out',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(30.0, 16.0, 30.0, 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Withdraw Cash',
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Divider(color: _brandColor.withValues(alpha: 0.3), thickness: 1),
            const SizedBox(height: 40),

            _buildTransactionCard(
              context: context,
              date: date,
              time: time,
              amount: formattedAmount,
              total: formattedTotal,
              transactionCode: _transactionCode,
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Ensure the details are correct before confirming.',
                style: GoogleFonts.nunito(fontSize: 13, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 16),
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Center(
      child: OutlinedButton(
        onPressed: _isLoading ? null : _onConfirmPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: _brandColor,
          backgroundColor: _brandColor.withValues(alpha: 0.1),
          side: BorderSide(color: _brandColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                'Confirm',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }

  Widget _buildTransactionCard({
    required BuildContext context,
    required String date,
    required String time,
    required String amount,
    required String total,
    required String transactionCode,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _brandColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: _brandColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              Text(
                'Cash Out Transaction',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Divider(color: _brandColor.withValues(alpha: 0.3), height: 24),
              _buildDetailRow('Date:', date),
              _buildDetailRow('Time:', time),
              _buildDetailRow('Amount:', amount),
              Divider(color: _brandColor.withValues(alpha: 0.3), height: 24),
              _buildDetailRow('Total:', total, isTotal: true),
              Divider(color: _brandColor.withValues(alpha: 0.3), height: 24),
              BarcodeWidget(
                barcode: Barcode.code128(),
                data: transactionCode,
                height: 50,
                drawText: false,
              ),
              const SizedBox(height: 8),
              Text(
                transactionCode,
                style: GoogleFonts.sourceCodePro(
                  fontSize: 11,
                  color: Colors.black54,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          Positioned(
            top: -12,
            right: -12,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, color: _brandColor, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
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
            value,
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
