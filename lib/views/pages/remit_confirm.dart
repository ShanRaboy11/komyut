// In lib/pages/remit_confirmation_driver.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'remit_success.dart'; // Import for the next page

class RemitConfirmationPage extends StatefulWidget {
  final String amount;
  final double currentBalance;
  final String operatorName;

  const RemitConfirmationPage({
    super.key,
    required this.amount,
    required this.currentBalance,
    required this.operatorName,
  });

  @override
  State<RemitConfirmationPage> createState() => _RemitConfirmationPageState();
}

class _RemitConfirmationPageState extends State<RemitConfirmationPage> {
  late final String _transactionCode;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _transactionCode = _generateTransactionCode();
  }

  String _generateTransactionCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return 'K0MYUT-DRV-${String.fromCharCodes(Iterable.generate(10, (_) => chars.codeUnitAt(random.nextInt(chars.length))))}';
  }

  void _onConfirmPressed() {
    setState(() => _isLoading = true);
    // Simulate a network call
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => RemittanceSuccessPage(
            amount: double.tryParse(widget.amount) ?? 0.0,
            operatorName: widget.operatorName,
            transactionCode: _transactionCode,
          ),
        ),
        (route) => route.isFirst, // Go back to the wallet page
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final double amountValue = double.tryParse(widget.amount) ?? 0.0;
    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    final now = DateTime.now();
    final Color brandColor = const Color(0xFF8E4CB6);

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
          'Confirm Remittance',
          style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(30.0, 16.0, 30.0, 40.0),
        child: Column(
          children: [
            _buildTransactionCard(
              date: DateFormat('MM/dd/yyyy').format(now),
              time: DateFormat('hh:mm a').format(now),
              amount: currencyFormat.format(amountValue),
              total: currencyFormat.format(
                amountValue,
              ), // Remittance has no extra fees
              transactionCode: _transactionCode,
              brandColor: brandColor,
            ),
            const SizedBox(height: 24),
            Text(
              'Ensure details are correct before confirming.',
              style: GoogleFonts.nunito(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            _buildConfirmButton(brandColor),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton(Color brandColor) {
    return Center(
      child: OutlinedButton(
        onPressed: _isLoading ? null : _onConfirmPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: brandColor,
          backgroundColor: brandColor.withOpacity(0.1),
          side: BorderSide(color: brandColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
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
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  Widget _buildTransactionCard({
    required String date,
    required String time,
    required String amount,
    required String total,
    required String transactionCode,
    required Color brandColor,
  }) {
    return Container(
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
      child: Column(
        children: [
          Text(
            'Remittance Transaction',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Divider(color: brandColor.withOpacity(0.5), height: 24),
          _buildDetailRow('Date:', date),
          _buildDetailRow('Time:', time),
          _buildDetailRow('Recipient:', widget.operatorName),
          Divider(color: brandColor.withOpacity(0.5), height: 24),
          _buildDetailRow('Amount:', total, isTotal: true),
          Divider(color: brandColor.withOpacity(0.5), height: 24),
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
              fontSize: 14,
              color: Colors.black54,
              letterSpacing: 1.5,
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
