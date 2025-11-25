import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FeedbackSuccessPage extends StatelessWidget {
  const FeedbackSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFDFDFF), Color(0xFFF1F0FA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Circular Check Icon with Glow
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xffb945aa), Color(0xff8e4cb6), Color(0xff5b53c2)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff8e4cb6),
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 60,
                  weight: 5, // make it thicker
                ),
              ),
            ),
            
            const SizedBox(height: 50),

            // Title
            Text(
              "Feedback Submitted!",
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 16),

            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                "Thank you for sharing your thoughts. By making your voice heard, you help us improve komyut and the experience for everyone.",
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
