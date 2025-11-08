// In lib/pages/remit_page_driver.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

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

  void _showConfirmationDialog() {
    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    final amount = double.parse(_amountController.text);
    final remainingBalance = _currentBalance - amount;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Confirm Remittance',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You are about to send:'),
            const SizedBox(height: 8),
            Text(
              currencyFormat.format(amount),
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text('To: $_operatorName'),
            const Divider(height: 24),
            Text(
              'Remaining Balance: ${currencyFormat.format(remainingBalance)}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Close the dialog
              _navigateToSuccessPage(amount); // Navigate to success page
            },
            child: const Text('Confirm & Send'),
          ),
        ],
      ),
    );
  }

  void _navigateToSuccessPage(double amount) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RemittanceSuccessPage(amount: amount, operatorName: _operatorName),
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
          'Remit to Operator',
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
            Text(
              'Enter Amount',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: GoogleFonts.manrope(
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                prefixText: '₱ ',
                prefixStyle: GoogleFonts.manrope(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
                hintText: '0.00',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isButtonEnabled ? _showConfirmationDialog : null,
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

// --- SUCCESS PAGE ---

class RemittanceSuccessPage extends StatelessWidget {
  final double amount;
  final String operatorName;

  const RemittanceSuccessPage({
    super.key,
    required this.amount,
    required this.operatorName,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(Symbols.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 24),
              Text(
                'Remittance Successful!',
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You have successfully sent funds to your operator.',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      'Amount Sent',
                      currencyFormat.format(amount),
                    ),
                    const Divider(height: 24),
                    _buildDetailRow('Recipient', operatorName),
                    const Divider(height: 24),
                    _buildDetailRow(
                      'Transaction Date',
                      DateFormat('MMMM d, yyyy').format(DateTime.now()),
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      'Transaction Time',
                      DateFormat('hh:mm a').format(DateTime.now()),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Done',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.nunito(color: Colors.grey[600])),
        Text(value, style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
