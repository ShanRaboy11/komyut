import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart'; // Not needed for static
// import '../providers/operator_wallet_provider.dart'; // Not needed for static

class OperatorCashOutInstructionsPage extends StatefulWidget {
  final Map<String, dynamic> transaction;

  const OperatorCashOutInstructionsPage({super.key, required this.transaction});

  @override
  State<OperatorCashOutInstructionsPage> createState() =>
      _OperatorCashOutInstructionsPageState();
}

class _OperatorCashOutInstructionsPageState
    extends State<OperatorCashOutInstructionsPage> {
  void _onDonePressed() {
    // Static behavior: Go back to the main Wallet/Dashboard
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final Color brandColor = const Color(0xFF8E4CB6);

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
            fontSize: 18,
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
            Divider(color: brandColor.withValues(alpha: 0.5), thickness: 1),
            const SizedBox(height: 40),
            _buildStep(
              iconPath: 'assets/images/step2.png',
              title: 'Step 2',
              description:
                  'Go to the nearest official partner outlet and inform the cashier that you would like to cash out from your komyut wallet.',
            ),
            const SizedBox(height: 32),
            _buildStep(
              iconPath: 'assets/images/step3.png',
              title: 'Step 3',
              description:
                  'Present the transaction code generated and your Operator ID to the cashier for verification.',
            ),
            const SizedBox(height: 32),
            _buildStep(
              iconPath: 'assets/images/step4.png',
              title: 'Step 4',
              description:
                  'The cashier will verify the transaction details. Please wait while they process your request.',
            ),
            const SizedBox(height: 32),
            _buildStep(
              iconPath: 'assets/images/step5.png',
              title: 'Step 5',
              description:
                  'Receive your cash. Note that the service fee has already been deducted from your wallet balance.',
            ),
            const SizedBox(height: 50),

            // Static Button (No Consumer/Provider needed for layout)
            Center(
              child: OutlinedButton(
                onPressed: _onDonePressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: brandColor,
                  backgroundColor: brandColor.withValues(alpha: 0.1),
                  side: BorderSide(color: brandColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 60,
                    vertical: 10,
                  ),
                ),
                child: Text(
                  'Done',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({
    required String iconPath,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Assumes assets exist as per driver app
        Image.asset(iconPath, width: 40, height: 40),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.nunito(fontSize: 15, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
