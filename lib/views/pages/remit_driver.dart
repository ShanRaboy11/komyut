// In lib/pages/remit_page_driver.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'remit_confirm.dart';

class RemitPageDriver extends StatefulWidget {
  const RemitPageDriver({super.key});

  @override
  State<RemitPageDriver> createState() => _RemitPageDriverState();
}

class _RemitPageDriverState extends State<RemitPageDriver> {
  final TextEditingController _amountController = TextEditingController();
  final double _currentBalance = 12540.50; // Dummy data
  final String _operatorName = 'Juan Dela Cruz'; // Dummy data
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_validateInput);
  }

  void _validateInput() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    setState(() {
      _isButtonEnabled = amount > 0 && amount <= _currentBalance;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _onReviewPressed() {
    // Navigate to the new confirmation page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RemitConfirmationPage(
          amount: _amountController.text,
          currentBalance: _currentBalance,
          operatorName: _operatorName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard(
              'Current Balance',
              currencyFormat.format(_currentBalance),
              Symbols.account_balance_wallet_rounded,
            ),
            const SizedBox(height: 16),
            _buildInfoCard('Recipient', _operatorName, Symbols.person),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Enter Amount to Remit',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: GoogleFonts.manrope(
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                prefixText: '₱',
                prefixStyle: GoogleFonts.manrope(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[400],
                ),
                hintText: '0.00',
                hintStyle: TextStyle(color: Colors.grey[300]),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isButtonEnabled ? _onReviewPressed : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Review Remittance',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8E4CB6), size: 28),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.nunito(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
