import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';

class OtcConfirmationPage extends StatefulWidget {
  final String amount;

  const OtcConfirmationPage({super.key, required this.amount});

  @override
  State<OtcConfirmationPage> createState() => _OtcConfirmationPageState();
}

class _OtcConfirmationPageState extends State<OtcConfirmationPage> {
  late String _transactionCode;

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
    return 'K0MYUT-XHS$part1'.substring(0, 25);
  }

  Future<void> _onConfirmPressed() async {
    final provider = Provider.of<WalletProvider>(context, listen: false);
    final amountValue = double.tryParse(widget.amount);

    if (amountValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid amount format.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await provider.createOtcTransaction(
      amount: amountValue,
      transactionCode: _transactionCode,
    );

    if (success && mounted) {
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamed('/otc_instructions', arguments: provider.pendingTransaction);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.cashInErrorMessage ?? 'Failed to create transaction.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double amountValue = double.tryParse(widget.amount) ?? 0.0;
    final double totalValue = amountValue + 5.00;
    final now = DateTime.now();
    final date = DateFormat('MM/dd/yyyy').format(now);
    final time = DateFormat('hh:mm a').format(now);

    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: 'P');
    final String formattedAmount = currencyFormat.format(amountValue);
    final String formattedTotal = currencyFormat.format(totalValue);

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
            _buildTransactionCard(
              context: context,
              date: date,
              time: time,
              amount: formattedAmount,
              total: formattedTotal,
              transactionCode: _transactionCode,
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
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    final Color brandColor = const Color(0xFF8E4CB6);
    return Consumer<WalletProvider>(
      builder: (context, provider, child) {
        return Center(
          child: OutlinedButton(
            onPressed: provider.isCashInLoading ? null : _onConfirmPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: brandColor,
              backgroundColor: brandColor.withValues(alpha: 0.1),
              side: BorderSide(color: brandColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
            ),
            child: provider.isCashInLoading
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
      },
    );
  }

  Widget _buildTransactionCard({
    required BuildContext context,
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
                'Cash In Transaction',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Divider(color: brandColor.withValues(alpha: 0.5), height: 24),
              _buildDetailRow('Date:', date),
              _buildDetailRow('Time:', time),
              _buildDetailRow('Amount:', amount),
              _buildDetailRow('Channel:', 'Over-the-Counter'),
              Divider(color: brandColor.withValues(alpha: 0.5), height: 24),
              _buildDetailRow('Total:', total, isTotal: true),
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
                Navigator.of(
                  context,
                  rootNavigator: true,
                ).popUntil((route) => route.settings.name == '/home_commuter');
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
