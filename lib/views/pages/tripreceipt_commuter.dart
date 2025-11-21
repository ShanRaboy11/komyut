import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import '../widgets/receipttrip_card.dart';
import '../widgets/button.dart';
import '../pages/home_commuter.dart';

class TripReceiptPage extends StatelessWidget {
  const TripReceiptPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Color(0xFFF7F4FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            children: [
              // --- Back Arrow + Title ---
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
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  // Centered title
                  Text(
                    "Payment Receipt",
                    style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(Symbols.download, color: Colors.black87),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // --- Logo ---
              Center(
                child: SvgPicture.asset("assets/images/logo.svg", height: 80),
              ),
              const SizedBox(height: 24),

              // --- Description Text ---
              ReceiptCard(
                from: "SM Cebu",
                to: "Colon",
                fromTime: "03:17PM",
                toTime: "04:26PM",
                passenger: "Shan Michael Raboy",
                date: "September 11, 2025",
                time: "04:26PM",
                passengers: 3,
                baseFare: 12.00,
                discount: 7.00,
                totalFare: 29.00,
                barcodeText: "MYUI7821A-G2-90A",
              ),
              const SizedBox(height: 30),

              CustomButton(
                text: "Back to Home",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CommuterDashboardNav(),
                    ),
                  );
                },
                width: screenWidth,
                height: 50,
                textColor: Colors.white,
                isFilled: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper for styled RichText blocks ---
}
