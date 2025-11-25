import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../widgets/button.dart';

class TransactionReceiptPage extends StatelessWidget {
  final String id;
  final String type;
  final Map<String, dynamic>? staticData;

  const TransactionReceiptPage({
    super.key,
    required this.id,
    required this.type,
    this.staticData,
  });

  @override
  Widget build(BuildContext context) {
    // Parse static data
    final data = staticData ?? {};
    final amount = (data['amount'] as num?)?.toDouble().abs() ?? 0.00;
    final dateStr = data['date'] as String? ?? DateTime.now().toString();
    final date = DateFormat('MMM dd, yyyy').format(DateTime.parse(dateStr));
    final time = DateFormat('hh:mm a').format(DateTime.parse(dateStr));
    final ref = data['reference'] ?? '---';
    final method = data['method'] ?? 'System';
    final title = data['title'] ?? 'Transaction';

    final isRedemption = (data['category'] == 'redemption');

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.black87,
                        size: 24,
                      ),
                    ),
                  ),
                  Text(
                    'Transaction Receipt',
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: SvgPicture.asset(
                        'assets/images/logo.svg',
                        height: 70,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Receipt Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isRedemption) ...[
                                Image.asset(
                                  'assets/images/wheel token.png',
                                  height: 24,
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                isRedemption
                                    ? amount.toString()
                                    : '₱${amount.toStringAsFixed(2)}',
                                style: GoogleFonts.manrope(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 16),
                          _row('Date', date),
                          _row('Time', time),
                          _row('Reference No.', ref, isSmall: true),
                          _row(
                            isRedemption ? 'Source' : 'Payment Method',
                            method,
                          ),
                          _row('Status', 'Completed', color: Colors.green),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                    CustomButton(
                      text: 'Back',
                      onPressed: () => Navigator.pop(context),
                      width: double.infinity,
                      height: 50,
                      textColor: Colors.white,
                      isFilled: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    String label,
    String value, {
    bool isSmall = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(color: Colors.grey[600], fontSize: 14),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.manrope(
                fontSize: isSmall ? 12 : 14,
                fontWeight: FontWeight.bold,
                color: color ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
