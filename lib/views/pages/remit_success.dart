// In lib/pages/remit_success_driver.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RemittanceSuccessPage extends StatelessWidget {
  final double amount;
  final String operatorName;
  final String transactionCode;

  const RemittanceSuccessPage({
    super.key,
    required this.amount,
    required this.operatorName,
    required this.transactionCode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            const Center(
              child: Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.green,
                size: 100,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Remittance Successful!',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You have successfully sent funds to your operator.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(fontSize: 16, color: Colors.grey[600]),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context), // Go back to the wallet page
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Done'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
