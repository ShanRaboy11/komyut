import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'driver_app.dart';

class RemitConfirmationPage extends StatefulWidget {
  final String amount;
  final String operatorName;

  const RemitConfirmationPage({
    super.key,
    required this.amount,
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
    final part1 = String.fromCharCodes(
      Iterable.generate(
        15,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
    return 'K0MYUT-RMT$part1'.substring(0, 25);
  }

  void _onConfirmPressed() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      DriverApp.navigatorKey.currentState?.pushReplacementNamed(
        '/remit_success',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final double amountValue = double.tryParse(widget.amount) ?? 0.0;
    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
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
          'Remittance',
          style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(30.0, 16.0, 30.0, 40.0),
        child: Column(
          children: [
            _buildTransactionCard(
              amount: currencyFormat.format(amountValue),
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
          backgroundColor: brandColor.withValues(alpha: 0.1),
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
    required String amount,
    required String transactionCode,
    required Color brandColor,
  }) {
    return Container(
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
            children: [
              Text(
                'Remittance Transaction',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Divider(color: brandColor.withValues(alpha: 0.5), height: 24),
              _buildDetailRow(
                'Date:',
                DateFormat('MM/dd/yyyy').format(DateTime.now()),
              ),
              _buildDetailRow(
                'Time:',
                DateFormat('hh:mm a').format(DateTime.now()),
              ),
              _buildDetailRow('Recipient:', widget.operatorName),
              Divider(color: brandColor.withValues(alpha: 0.5), height: 24),
              _buildDetailRow('Amount:', amount, isTotal: true),
              Divider(color: brandColor.withValues(alpha: 0.5), height: 24),
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
          Positioned(
            top: -12,
            right: -12,
            child: GestureDetector(
              onTap: () {
                DriverApp.navigatorKey.currentState?.popUntil(
                  ModalRoute.withName('/'),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, color: brandColor),
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
