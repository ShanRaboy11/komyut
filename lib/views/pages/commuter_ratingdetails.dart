import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Assuming you have these assets in your project based on your previous code
// If not, the code handles errors gracefully or uses placeholders.

class RateReviewPage extends StatefulWidget {
  const RateReviewPage({super.key});

  @override
  State<RateReviewPage> createState() => _RateReviewPageState();
}

class _RateReviewPageState extends State<RateReviewPage> {
  double _sheetHeight = 0;
  double _sheetOpacity = 0;
  double _logoOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    
    // Animation trigger
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenSize = MediaQuery.of(context).size;
      setState(() {
        // Height set to match the screenshot (covering most of the screen)
        _sheetHeight = screenSize.height * 0.80; 
        _sheetOpacity = 1.0;
        _logoOpacity = 1.0;
      });
    });
  }

  void _collapseSheet() {
    setState(() {
      _sheetHeight = 0;
      _sheetOpacity = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      // 1. Top Bar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () async {
            _collapseSheet();
            await Future.delayed(const Duration(milliseconds: 200));
            if (!context.mounted) return;
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Rate and Review',
          style: GoogleFonts.manrope(
            color: Colors.black, 
            fontSize: 18, 
            fontWeight: FontWeight.bold
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
            // 2. Background Decorations (Kept from your original code)
            Positioned(
              top: 39,
              left: 172,
              child: Image.asset("assets/images/Ellipse 1.png", errorBuilder: (c,e,s) => const SizedBox()),
            ),
            Positioned(
              top: -134,
              left: 22,
              child: Image.asset("assets/images/Ellipse 3.png", errorBuilder: (c,e,s) => const SizedBox()),
            ),

            // 3. Center Logo
            Positioned(
              top: screenSize.height * 0.15, // Positioned above the sheet
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _logoOpacity,
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOut,
                  // Using a column to simulate the logo structure if image is missing, 
                  // or use your asset: Image.asset('assets/images/komyut small logo.png')
                  child: Column(
                    children: [
                       Image.asset(
                        'assets/images/komyut small logo.png', // Your asset
                        width: 150,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback UI if asset is missing
                          return Column(
                            children: [
                              const Icon(Icons.settings, size: 60, color: Color(0xFF8E4CB6)),
                              Text("komyut", style: GoogleFonts.manrope(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF8E4CB6)))
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 4. Draggable/Animated Bottom Sheet
            AnimatedPositioned(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              bottom: 0,
              left: 0,
              right: 0,
              height: _sheetHeight,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 600),
                opacity: _sheetOpacity,
                curve: Curves.easeOutCubic,
                child: Container(
                  decoration: const ShapeDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFB945AA),
                        Color(0xFF8E4CB6),
                        Color(0xFF5B53C2),
                      ],
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    shadows: [
                      BoxShadow(
                        color: Color(0x3F000000),
                        blurRadius: 4,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(26.0, 30.0, 26.0, 0),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Title
                          Text(
                            "How was your trip?",
                            style: GoogleFonts.manrope(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Subtitle
                          Text(
                            "Thank you for using komyut. Your feedback is very important to us. Rate your experience and write a review to earn wheel tokens.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                          
                          const SizedBox(height: 25),

                          // Rating Section Header
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Rating",
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Star Rows
                          _buildStarRow("Driver Courtesy", 5),
                          _buildStarRow("Driving Safety", 4),
                          _buildStarRow("Vehicle Condition", 0),
                          _buildStarRow("Overall Experience", 0),
                          _buildStarRow("App Experience", 0),

                          const SizedBox(height: 20),

                          // Detail Review Section
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Detail Review",
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Text Input Box
                          Container(
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.white),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: TextField(
                              style: GoogleFonts.nunito(color: Colors.white),
                              maxLines: 5,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "Tell us your experience.",
                                hintStyle: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                // Handle Submit
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF8E4CB6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                "Submit Feedback",
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 15),

                          // Cancel Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton(
                              onPressed: () {
                                _collapseSheet();
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(
                                "Cancel",
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 30), // Bottom padding
                        ],
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

  // Helper widget to build rows of stars
  Widget _buildStarRow(String label, int filledCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < filledCount ? Icons.star_rounded : Icons.star_outline_rounded,
                color: const Color(0xFFFFD700), // Gold color
                size: 22,
              );
            }),
          ),
        ],
      ),
    );
  }
}