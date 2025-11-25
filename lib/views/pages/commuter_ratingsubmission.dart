import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'commuter_review4.dart';

// 1. Converted to StatefulWidget to handle the timer
class FeedbackSuccessPage extends StatefulWidget {
  const FeedbackSuccessPage({super.key});

  @override
  State<FeedbackSuccessPage> createState() => _FeedbackSuccessPageState();
}

class _FeedbackSuccessPageState extends State<FeedbackSuccessPage> {

  @override
  void initState() {
    super.initState();
    
    // 2. Wait 1 second, then navigate
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        // REPLACE 'HomePage()' with the actual page you want to go to next
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const TokenClaimPage()), 
        );
      }
    });
  }

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
                    color: const Color(0xff8e4cb6), // Fixed opacity for cleaner glow
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
                  weight: 5, 
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