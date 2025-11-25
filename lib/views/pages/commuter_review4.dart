import 'dart:async'; // Required for Timer
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TokenClaimPage extends StatefulWidget {
  const TokenClaimPage({super.key});

  @override
  State<TokenClaimPage> createState() => _TokenClaimPageState();
}

class _TokenClaimPageState extends State<TokenClaimPage> {
  int _countdown = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        _timer?.cancel();
        _navigateToNextPage();
      }
    });
  }

  void _navigateToNextPage() {
    if (mounted) {
      // Navigate to Home or Wallet page
      // Replace '/home_commuter' with your actual route
      Navigator.of(context).pushReplacementNamed('/home_commuter'); 
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
          children: [
            const Spacer(flex: 2), // Pushes content down

            // Title Text
            Column(
              children: [
                Text(
                  "You earned a",
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                Text(
                  "wheel token",
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xff8e4cb6), // Purple color
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Coin Image and Value
            Column(
              children: [
                // Coin Image
                Image.asset(
                  "assets/wheel token 1.png", // Ensure this matches your asset name exactly
                  width: 160,
                  height: 160,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback placeholder if image is missing
                    return Container(
                      width: 160,
                      height: 160,
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.monetization_on, size: 80, color: Colors.white),
                    );
                  },
                ),
                
                const SizedBox(height: 10),
                
                // Value Text
                Text(
                  "0.5",
                  style: GoogleFonts.manrope(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xff8e4cb6), // Purple color
                  ),
                ),
              ],
            ),

            const Spacer(flex: 3), // Pushes button to bottom

            // Claim Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 40.0),
              child: GestureDetector(
                onTap: _navigateToNextPage,
                child: Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      colors: [Color(0xffb945aa), Color(0xff8e4cb6), Color(0xff5b53c2)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xff8e4cb6),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _countdown > 0 ? "Claim (${_countdown}s)" : "Claiming...",
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}