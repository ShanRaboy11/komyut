import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TransactionReceiptCard extends StatelessWidget {
  final String title;
  final double amount;
  final String date;
  final String time;
  final String paymentMethod;
  final String referenceNumber;
  final bool isRedemption;
  final String? feeNote;

  const TransactionReceiptCard({
    super.key,
    required this.title,
    required this.amount,
    required this.date,
    required this.time,
    required this.paymentMethod,
    required this.referenceNumber,
    this.isRedemption = false,
    this.feeNote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8E4CB6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isRedemption) ...[
                Image.asset('assets/images/wheel token.png', height: 28),
                const SizedBox(width: 8),
              ],
              Text(
                isRedemption
                    ? amount.toStringAsFixed(2)
                    : '₱${amount.toStringAsFixed(2)}',
                style: GoogleFonts.manrope(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Status Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F8E8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Completed',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.green[700],
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 12),

          // Details Rows
          _detailRow('Date', date),
          _detailRow('Time', time),
          _detailRow(isRedemption ? 'Source' : 'Payment Method', paymentMethod),
          _detailRow('Transaction Fee', '₱0.00'),

          const SizedBox(height: 16),

          // Fee Note
          Text(
            feeNote ??
                (isRedemption
                    ? "No fees applied for this redemption."
                    : "A convenience fee has been applied to this transaction."),
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),

          const SizedBox(height: 20),
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 20),

          // Barcode Section
          Center(
            child: Column(
              children: [
                BarcodeWidget(
                  barcode: Barcode.code128(),
                  data: referenceNumber.isNotEmpty ? referenceNumber : 'NONE',
                  height: 60,
                  width: 200,
                  drawText: false,
                ),
                const SizedBox(height: 8),
                Text(
                  referenceNumber,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
