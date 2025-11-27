import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'commuter_ratingdetails.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 1. Fade in the logo immediately
      setState(() {
        _logoOpacity = 1.0;
      });

      // 2. Wait 1 second, then animate to CommuterRatingDetails
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;

        Navigator.of(context).pushReplacement(_createSlideUpRoute());
      });
    });
  }

  // Helper to create a slide-up animation route
  Route _createSlideUpRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          const RateReviewPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0); // Start from bottom
        const end = Offset.zero; // End at center
        const curve = Curves.easeInOutCubic;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 800),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- Header: Title Only (Back Button Removed) ---
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading:
            false, // Ensures no default back button appears
        // Added 20 space above the text
        title: Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: Text(
            'Rate and Review',
            style: GoogleFonts.manrope(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
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
              child: Image.asset(
                "assets/images/Ellipse 1.png",
                errorBuilder: (c, e, s) => const SizedBox(),
              ),
            ),
            Positioned(
              top: -134,
              left: 22,
              child: Image.asset(
                "assets/images/Ellipse 3.png",
                errorBuilder: (c, e, s) => const SizedBox(),
              ),
            ),
            Positioned(
              top: 672,
              left: -94,
              child: Image.asset(
                "assets/images/Ellipse 2.png",
                errorBuilder: (c, e, s) => const SizedBox(),
              ),
            ),
            Positioned(
              top: 454,
              left: -293,
              child: Image.asset(
                "assets/images/Ellipse 4.png",
                errorBuilder: (c, e, s) => const SizedBox(),
              ),
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
                            const Icon(
                              Icons.settings,
                              size: 80,
                              color: Color(0xFF8E4CB6),
                            ),
                            Text(
                              "komyut",
                              style: GoogleFonts.manrope(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF8E4CB6),
                              ),
                            ),
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
