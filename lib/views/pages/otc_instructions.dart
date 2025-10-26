import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OtcInstructionsPage extends StatelessWidget {
  const OtcInstructionsPage({super.key});

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
              'Over-the-Counter',
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Divider(color: brandColor.withValues(alpha: 0.5), thickness: 1),
            const SizedBox(height: 40),

            // Steps
            _buildStep(
              iconPath: 'assets/images/step2.png',
              title: 'Step 2',
              description:
                  'Go to the nearest official partner outlet and inform the cashier that you would like to cash in to your komyut wallet.',
            ),
            const SizedBox(height: 32),
            _buildStep(
              iconPath: 'assets/images/step3.png',
              title: 'Step 3',
              description:
                  'Give the cashier your username, along with the cash-in amount you entered in the komyut app.',
            ),
            const SizedBox(height: 32),
            _buildStep(
              iconPath: 'assets/images/step4.png',
              title: 'Step 4',
              description:
                  'Hand over the total payment to the cashier. This includes your cash-in amount plus the transaction fee.',
            ),
            const SizedBox(height: 32),
            _buildStep(
              iconPath: 'assets/images/step5.png',
              title: 'Step 5',
              description:
                  'The cashier will process the transaction and load the funds to your wallet. Wait for confirmation before leaving the store.',
            ),
            const SizedBox(height: 50),

            // Done Button
            Center(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/payment_success');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: brandColor,
                  backgroundColor: brandColor.withValues(alpha: 0.1),
                  side: BorderSide(color: brandColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 60,
                    vertical: 14,
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
