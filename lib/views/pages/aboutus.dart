import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 400;

    return Scaffold(
      backgroundColor: Color(0xFFF7F4FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.07,
            vertical: width * 0.06,
          ),
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfilePage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    ),
                  ),

                  // Centered title
                  Text(
                    "About Us",
                    style: GoogleFonts.manrope(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // --- Logo ---
              Center(
                child: SvgPicture.asset(
                  "assets/images/aboutus_logo.svg",
                  height: isSmall ? 150 : 150,
                ),
              ),
              const SizedBox(height: 24),

              // --- Description Text ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRichText(
                      "",
                      "komyut",
                      " is a mobile app that makes commuting in Cebu City safer, smarter, and more convenient. With cashless payments, automated fare computation, and trip tracking, we modernize public utility vehicle (PUV) services while addressing everyday commuting challenges.",
                    ),
                    const SizedBox(height: 20),
                    _buildRichText(
                      "Our main goal is to ",
                      "ensure fair fares, improve passenger security, and provide hassle-free cashless transactions",
                      " . Through features like incident reporting, QR-based trip logging, and secure digital wallets, we aim to protect commuters while empowering drivers and operators.",
                    ),
                    const SizedBox(height: 20),
                    _buildRichText(
                      "By giving access to ",
                      "trip history, payment records, and driver ratings, Komyut promotes trust, accountability, and better service quality",
                      " for everyone.",
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper for styled RichText blocks ---
  Widget _buildRichText(String start, [String? highlight, String? end]) {
    return RichText(
      textAlign: TextAlign.justify,
      text: TextSpan(
        children: [
          TextSpan(
            text: start,
            style: GoogleFonts.nunito(
              color: Colors.black87,
              fontSize: 17,
              height: 1.6,
            ),
          ),
          if (highlight != null)
            TextSpan(
              text: highlight,
              style: GoogleFonts.nunito(
                color: const Color(0xFF5B53C2), // Komyut purple
                fontWeight: FontWeight.w600,
                fontSize: 17,
              ),
            ),
          if (end != null)
            TextSpan(
              text: end,
              style: GoogleFonts.nunito(
                color: Colors.black87,
                fontSize: 17,
                height: 1.6,
              ),
            ),
        ],
      ),
    );
  }
}
