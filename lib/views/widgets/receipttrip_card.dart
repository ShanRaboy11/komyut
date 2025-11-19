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
    required this.barcodeText,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 🔹 Border layer
        ClipPath(
          clipper: ZigzagClipper(),
          child: Container(
            width: double.infinity,
            color: const Color(0xFF8E4CB6),
            margin: const EdgeInsets.all(0),
          ),
        ),

        // 🔹 Main content (your existing card)
        Padding(
          padding: const EdgeInsets.all(2), // border thickness
          child: ClipPath(
            clipper: ZigzagClipper(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                border: Border.all(color: const Color(0xFF8E4CB6)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🗺️ Route
                  Row(
                    children: [
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
                            color: const Color(
                              0xFFB945AA,
                            ).withValues(alpha: 0.4),
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLocationRow(
                              from,
                              fromTime,
                              const Color(0xFFB945AA),
                            ),
                            const SizedBox(height: 8),
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
                  // small gap then dashed tear/outline before barcode
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: _buildDashedDivider(color: const Color(0xFF8E4CB6)),
                  ),
                  const SizedBox(height: 12),

                  // 🧍 Barcode
                  const SizedBox(height: 8),
                  Center(
                    child: Column(
                      children: [
                        BarcodeWidget(
                          barcode: Barcode.code128(),
                          data: barcodeText,
                          height: 60,
                          width: 200,
                          drawText: false,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          barcodeText,
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Colors.black.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashedDivider({required Color color}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashWidth = 8.0;
        final gap = 6.0;
        final count = (constraints.maxWidth / (dashWidth + gap)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(count, (index) {
            return Container(
              width: dashWidth,
              height: 1,
              margin: EdgeInsets.only(right: index == count - 1 ? 0 : gap),
              color: color.withOpacity(0.6),
            );
          }),
        );
      },
    );
  }

  Widget _buildLocationRow(String title, String time, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
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
          Text(
            label,
            style: GoogleFonts.manrope(
              fontWeight: isBoldLeft ? FontWeight.w800 : FontWeight.w600,
              fontSize: isBoldLeft ? 20 : 16,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontWeight: isBoldRight ? FontWeight.w800 : FontWeight.w600,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// 🟣 Zigzag Clipper (WORKING)
class ZigzagClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const double zigzagHeight = 8;
    const double zigzagWidth = 12;

    final path = Path()..moveTo(0, 0);

    // top edge
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height - zigzagHeight);

    // bottom zigzag
    bool reverse = false;
    for (double x = size.width; x > 0; x -= zigzagWidth) {
      path.lineTo(
        x - zigzagWidth / 2,
        reverse ? size.height - zigzagHeight : size.height,
      );
      reverse = !reverse;
    }

    // close left edge
    path.lineTo(0, size.height - zigzagHeight);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
