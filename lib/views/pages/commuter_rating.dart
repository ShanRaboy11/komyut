import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RatingPage extends StatefulWidget {
  const RatingPage({super.key});

  @override
  State<RatingPage> createState() => _RateReviewPageState();
}

class _RateReviewPageState extends State<RatingPage> {
  double _logoOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    // Simple fade-in animation for the logo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _logoOpacity = 1.0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- Header: Back Button & Title ---
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Rate and Review',
          style: GoogleFonts.manrope(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      extendBodyBehindAppBar: true,

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
        child: Stack(
          children: [
            // --- Background Decorations ---
            Positioned(
              top: 39,
              left: 172,
              child: Image.asset("assets/images/Ellipse 1.png", 
                errorBuilder: (c,e,s) => const SizedBox()),
            ),
            Positioned(
              top: -134,
              left: 22,
              child: Image.asset("assets/images/Ellipse 3.png", 
                errorBuilder: (c,e,s) => const SizedBox()),
            ),
            Positioned(
              top: 672,
              left: -94,
              child: Image.asset("assets/images/Ellipse 2.png", 
                errorBuilder: (c,e,s) => const SizedBox()),
            ),
             Positioned(
              top: 454,
              left: -293,
              child: Image.asset("assets/images/Ellipse 4.png",
               errorBuilder: (c,e,s) => const SizedBox()),
            ),

            // --- Center Content (Logo) ---
            Center(
              child: AnimatedOpacity(
                opacity: _logoOpacity,
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOut,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/Vector.png', 
                      width: 150,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback if image is missing
                        return Column(
                          children: [
                            const Icon(Icons.settings, size: 80, color: Color(0xFF8E4CB6)),
                            Text("komyut", 
                              style: GoogleFonts.manrope(
                                fontSize: 30, 
                                fontWeight: FontWeight.bold, 
                                color: const Color(0xFF8E4CB6)
                              )
                            )
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}