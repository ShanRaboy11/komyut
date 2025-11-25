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
  final double feeAmount;
  final String status;

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
    this.feeAmount = 0.0,
    this.status = 'completed',
  });

  @override
  Widget build(BuildContext context) {
    // Calculate total
    final double total = amount + feeAmount;

    return Container(
      width: double.infinity,
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

          // Main Amount Display
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
          _buildStatusPill(status),

          const SizedBox(height: 20),
          const Divider(height: 1, thickness: 1), // Consistent Divider
          const SizedBox(height: 12),

          _detailRow('Date', date),
          _detailRow('Time', time),
          _detailRow(isRedemption ? 'Source' : 'Payment Method', paymentMethod),

          if (!isRedemption) ...[
            _detailRow('Transaction Fee', '₱${feeAmount.toStringAsFixed(2)}'),

            // --- TOTAL ROW ---
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1), // Consistent Divider
            const SizedBox(height: 12),

            _detailRow('Total', '₱${total.toStringAsFixed(2)}', isTotal: true),

            const SizedBox(height: 16),
            Text(
              feeNote ??
                  "A convenience fee has been applied to this transaction.",
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          const SizedBox(height: 20),
          const Divider(height: 1, thickness: 1), // Consistent Divider
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

  Widget _buildStatusPill(String status) {
    Color bgColor;
    Color textColor;
    String text = status;
    if (status.isNotEmpty) {
      text = status[0].toUpperCase() + status.substring(1);
    }

    switch (status.toLowerCase()) {
      case 'completed':
      case 'paid':
      case 'success':
        bgColor = const Color(0xFFE9F8E8);
        textColor = Colors.green[700]!;
        break;
      case 'pending':
      case 'processing':
      case 'created':
        bgColor = const Color(0xFFFFF4E5);
        textColor = Colors.orange[800]!;
        break;
      case 'failed':
      case 'cancelled':
      case 'expired':
        bgColor = const Color(0xFFFFECEC);
        textColor = Colors.red[700]!;
        break;
      default:
        bgColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
                fontSize: isTotal ? 16 : 14,
                color: isTotal ? const Color(0xFF8E4CB6) : Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.manrope(
              fontSize: isTotal ? 16 : 13,
              fontWeight: FontWeight.w800,
              color: isTotal ? const Color(0xFF8E4CB6) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
