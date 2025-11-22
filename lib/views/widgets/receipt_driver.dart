import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:barcode_widget/barcode_widget.dart';

class ReceiptCard extends StatelessWidget {
  final String from;
  final String to;
  final String fromTime;
  final String toTime;
  final String passenger;
  final String date;
  final String time;
  final int passengers;
  final double baseFare;
  final double discount;
  final double totalFare;
  final String barcodeText;

  const ReceiptCard({
    super.key,
    required this.from,
    required this.to,
    required this.fromTime,
    required this.toTime,
    required this.passenger,
    required this.date,
    required this.time,
    required this.passengers,
    required this.baseFare,
    required this.discount,
    required this.totalFare,
    this.barcodeText = '',
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🗺️ Route - FIXED ALIGNMENT
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon column with fixed width
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFCCF8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.map_outlined,
                      color: Color(0xFFB945AA),
                      size: 30,
                    ),
                  ),
                  Container(
                    height: 35,
                    width: 2,
                    color: const Color(0xFFB945AA).withOpacity(0.4),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9C5FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Color(0xFF8E4CB6),
                      size: 30,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Text column - expands to fill space
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Boarding location
                    _buildLocationRow(
                      from,
                      fromTime,
                      const Color(0xFFB945AA),
                    ),
                    const SizedBox(height: 43), // Match icon separator height
                    // Departure location
                    _buildLocationRow(
                      to,
                      toTime,
                      const Color(0xFF5B53C2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 28, thickness: 1),

          // 🧾 Fare details
          _buildFareRow("Passenger", passenger, isBoldRight: true),
          _buildFareRow("Date", "$date   $time", isBoldRight: true),
          _buildFareRow("No. of Passenger/s", passengers.toString()),
          const SizedBox(height: 8),
          const Divider(thickness: 1),
          const SizedBox(height: 8),
          _buildFareRow("Base Fare", "₱${baseFare.toStringAsFixed(2)}"),
          _buildFareRow(
            "Discount (if applicable)",
            "₱${discount.toStringAsFixed(2)}",
          ),
          const SizedBox(height: 12),
          const Divider(thickness: 1),
          const SizedBox(height: 8),
          _buildFareRow(
            "Total Fare",
            "₱${totalFare.toStringAsFixed(2)}",
            isBoldRight: true,
            isBoldLeft: true,
          ),

          const SizedBox(height: 20),
          
          // 🧍 Barcode Section - Always show with placeholder if no transaction
          Center(
            child: Column(
              children: [
                if (barcodeText.isNotEmpty)
                  // Show actual barcode when transaction number exists
                  Column(
                    children: [
                      BarcodeWidget(
                        barcode: Barcode.code128(),
                        data: barcodeText,
                        height: 60,
                        width: 200,
                        drawText: false,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        barcodeText,
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Colors.black.withOpacity(0.7),
                        ),
                      ),
                    ],
                  )
                else
                  // Show placeholder when no transaction number
                  Column(
                    children: [
                      Container(
                        height: 60,
                        width: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                            style: BorderStyle.solid,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.qr_code_2,
                            size: 40,
                            color: Colors.grey.withOpacity(0.4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No Transaction Number',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          color: Colors.grey.withOpacity(0.6),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(String title, String time, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Align to start (left)
      children: [
        Text(
          title,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Colors.black,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: GoogleFonts.nunito(
            fontSize: 14,
            color: Colors.black.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildFareRow(
    String label,
    String value, {
    bool isBoldRight = false,
    bool isBoldLeft = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontWeight: isBoldLeft ? FontWeight.w800 : FontWeight.w600,
                fontSize: isBoldLeft ? 20 : 16,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontWeight: isBoldRight ? FontWeight.w800 : FontWeight.w600,
              fontSize: 16,
              color: Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}