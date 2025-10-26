import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import '../widgets/drivercard_trip.dart';
import '../widgets/tripdetails_card.dart';
import '../widgets/button.dart';
import '../pages/tripreceipt_commuter.dart';

class TripDetailsPage extends StatelessWidget {
  final String date;
  final String time;
  final String from;
  final String to;
  final String tripCode;
  final String status;

  const TripDetailsPage({
    super.key,
    required this.date,
    required this.time,
    required this.from,
    required this.to,
    required this.tripCode,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 30,
            right: 30,
            bottom: 30,
            top: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // Back button (aligned to the left)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    ),
                  ),

                  // Centered title
                  Text(
                    "Trips",
                    style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Title
              Text(
                "Trip Details",
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),

              // Date and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "$date, $time",
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: Colors.black.withValues(alpha: 0.7),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusBackground(status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status[0].toUpperCase() + status.substring(1),
                      style: GoogleFonts.nunito(
                        color: _statusColor(status),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Driver Card
              const DriverCard(
                name: "Gio Christian D. Macatual",
                role: "Driver",
                plate: "735TUK",
              ),

              const SizedBox(height: 16),

              // Trip Details Card
              TripDetailsCard(
                mapImage: "assets/images/map.png",
                distance: "4 kilometers",
                routeCode: tripCode,
                from: from,
                fromTime: "03:17PM",
                to: to,
                toTime: time,
              ),

              const SizedBox(height: 20),

              // 🟣 Conditional Buttons based on trip status
              if (status.toLowerCase() == "cancelled") ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: "Rate",
                        onPressed: () {},
                        icon: Symbols.star_rounded,
                        width: (screenWidth - 70) / 2,
                        height: 50,
                        textColor: Colors.white,
                        isFilled: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: "Report",
                        onPressed: () {},
                        icon: Symbols.brightness_alert_rounded,
                        width: (screenWidth - 70) / 2,
                        height: 50,
                        textColor: Colors.white,
                        isFilled: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: "View Receipt",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TripReceiptPage(),
                      ),
                    );
                  },
                  icon: Symbols.receipt_long_rounded,
                  iconColor: const Color(0xFF5B53C2),
                  width: screenWidth,
                  height: 50,
                  isFilled: false,
                  outlinedFillColor: Colors.white,
                  textColor: const Color(0xFF5B53C2),
                  hasShadow: false,
                ),
              ] else if (status.toLowerCase() == "completed") ...[
                CustomButton(
                  text: "Rate Your Trip",
                  onPressed: () {},
                  icon: Symbols.star_rounded,
                  width: screenWidth,
                  height: 50,
                  textColor: Colors.white,
                  isFilled: true,
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: "View Receipt",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TripReceiptPage(),
                      ),
                    );
                  },
                  icon: Symbols.receipt_long_rounded,
                  iconColor: const Color(0xFF5B53C2),
                  width: screenWidth,
                  height: 50,
                  isFilled: false,
                  outlinedFillColor: Colors.white,
                  textColor: const Color(0xFF5B53C2),
                  hasShadow: false,
                ),
              ] else ...[
                CustomButton(
                  text: "Report an Issue",
                  onPressed: () {},
                  icon: Symbols.brightness_alert_rounded,
                  width: screenWidth,
                  height: 50,
                  textColor: Colors.white,
                  isFilled: true,
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: "View Receipt",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TripReceiptPage(),
                      ),
                    );
                  },
                  icon: Symbols.receipt_long_rounded,
                  iconColor: const Color(0xFF5B53C2),
                  width: screenWidth,
                  height: 50,
                  isFilled: false,
                  outlinedFillColor: Colors.white,
                  textColor: const Color(0xFF5B53C2),
                  hasShadow: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _statusBackground(String status) {
    switch (status.toLowerCase()) {
      case "ongoing":
        return const Color(0xFFFFF5CC);
      case "completed":
        return const Color(0xFFE9F8E8);
      case "cancelled":
        return const Color(0xFFFFE5E5);
      default:
        return Colors.grey.shade200;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "ongoing":
        return const Color(0xFFFFC107);
      case "completed":
        return Colors.green;
      case "cancelled":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
