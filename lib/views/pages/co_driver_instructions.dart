import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/wallet_provider.dart';
import 'driver_app.dart';

class DriverCashOutInstructionsPage extends StatefulWidget {
  final Map<String, dynamic> transaction;

  const DriverCashOutInstructionsPage({super.key, required this.transaction});

  @override
  State<DriverCashOutInstructionsPage> createState() =>
      _DriverCashOutInstructionsPageState();
}

class _DriverCashOutInstructionsPageState
    extends State<DriverCashOutInstructionsPage> {
  Future<void> _onDonePressed() async {
    final provider = Provider.of<DriverWalletProvider>(context, listen: false);
    final code = widget.transaction['transaction_number'];

    if (code != null) {
      await provider.completeCashOut(code);

      if (mounted) {
        DriverApp.navigatorKey.currentState?.pushReplacementNamed(
          '/cash_out_success',
        );
      }
    }
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
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Cash Out',
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
            Text(
              'Withdraw Cash',
              style: GoogleFonts.manrope(
                fontSize: 24,
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
                  'Present the transaction code generated and your Driver ID to the cashier for verification.',
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
            Consumer<DriverWalletProvider>(
              builder: (context, provider, child) {
                return Center(
                  child: OutlinedButton(
                    onPressed: provider.isPageLoading ? null : _onDonePressed,
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
                    child: provider.isPageLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Done',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                );
              },
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
