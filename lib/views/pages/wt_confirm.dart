import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:barcode_widget/barcode_widget.dart';

class TokenConfirmationPage extends StatelessWidget {
  final String tokenAmount;

  const TokenConfirmationPage({super.key, required this.tokenAmount});

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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final date = DateFormat('MM/dd/yyyy').format(now);
    final time = DateFormat('hh:mm a').format(now);
    final double tokenValue = double.tryParse(tokenAmount) ?? 0.0;
    final transactionCode = _generateTransactionCode();
    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: 'P');
    final String equivalentValue = currencyFormat.format(tokenValue);

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
          'Cash In',
          style: GoogleFonts.manrope(
            fontSize: 22,
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
            // Header
            Text(
              'Wheel Tokens',
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Divider(color: brandColor.withOpacity(0.5), thickness: 1),
            const SizedBox(height: 40),

            // Transaction Card
            _buildTransactionCard(
              context: context,
              date: date,
              time: time,
              tokenAmount: tokenAmount,
              equivalentValue: equivalentValue,
              transactionCode: transactionCode,
              brandColor: brandColor,
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Ensure the details are correct before confirming.',
                style: GoogleFonts.nunito(fontSize: 14, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 16),

            // Confirm Button
            Center(
              child: OutlinedButton(
                onPressed: () {
                  //Navigator.of(context).pushNamed('/payment_success');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: brandColor,
                  backgroundColor: brandColor.withOpacity(0.1),
                  side: BorderSide(color: brandColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 14,
                  ),
                ),
                child: Text(
                  'Confirm',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard({
    required BuildContext context,
    required String date,
    required String time,
    required String tokenAmount,
    required String equivalentValue,
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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Token Redemption',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Divider(color: brandColor.withOpacity(0.5), height: 24),
              _buildDetailRow('Date:', date),
              _buildDetailRow('Time:', time),
              _buildDetailRow(
                'Amount:',
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/images/wheel token.png', height: 16),
                    const SizedBox(width: 6),
                    Text(
                      double.parse(
                        tokenAmount,
                      ).toStringAsFixed(1), // Format to one decimal place
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: brandColor.withOpacity(0.5), height: 24),
              _buildDetailRow('Equivalent:', equivalentValue, isTotal: true),
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
              onTap: () {
                Navigator.of(
                  context,
                ).popUntil((route) => route.settings.name == '/wallet');
              },
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
    );
  }

  Widget _buildDetailRow(String label, dynamic value, {bool isTotal = false}) {
    final isValueWidget = value is Widget;
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
}
