import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RateReviewPage extends StatefulWidget {
  const RateReviewPage({super.key});

  @override
  State<RateReviewPage> createState() => _RateReviewPageState();
}

class _RateReviewPageState extends State<RateReviewPage> {
  // Animation State
  double _sheetHeight = 0;
  double _sheetOpacity = 0;
  double _logoOpacity = 0.0;

  // Rating State
  final TextEditingController _reviewController = TextEditingController();
  
  // Store ratings for each category
  final Map<String, int> _ratings = {
    "Driver Courtesy": 0,
    "Driving Safety": 0,
    "Vehicle Condition": 0,
    "Overall Experience": 0,
    "App Experience": 0,
  };

  @override
  void initState() {
    super.initState();
    
    // Trigger Animations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenSize = MediaQuery.of(context).size;
      setState(() {
        // Adjusted height to prevent covering the logo (0.75 instead of 0.80)
        _sheetHeight = screenSize.height * 0.75; 
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
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      // 1. Top Bar (Header)
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // No default back button
        leading: AnimatedOpacity(
          opacity: _logoOpacity,
          duration: const Duration(milliseconds: 1000),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
            onPressed: () async {
              _collapseSheet();
              await Future.delayed(const Duration(milliseconds: 200));
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
          ),
        ),
        title: AnimatedOpacity(
          opacity: _logoOpacity,
          duration: const Duration(milliseconds: 1000),
          child: Text(
            'Rate and Review',
            style: GoogleFonts.manrope(
              color: Colors.black, 
              fontSize: 18, 
              fontWeight: FontWeight.bold
            ),
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
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
              // 2. Background Decorations
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
              // Moved UP to 0.10 (10% from top) so it clears the sheet
              Positioned(
                top: screenSize.height * 0.10, 
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _logoOpacity,
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOut,
                    child: Image.asset(
                      'assets/images/komyut small logo.png', 
                      width: 150,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback UI
                        return Column(
                          children: [
                            const Icon(Icons.settings, size: 60, color: Color(0xFF8E4CB6)),
                            Text("komyut", style: GoogleFonts.manrope(fontSize: 30, fontWeight: FontWeight.bold, color: const Color(0xFF8E4CB6)))
                          ],
                        );
                      },
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
                        physics: const ClampingScrollPhysics(), // Reduced bounce for "no scrolling" feel
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

                            // Functional Star Rows
                            _buildInteractiveStarRow("Driver Courtesy"),
                            _buildInteractiveStarRow("Driving Safety"),
                            _buildInteractiveStarRow("Vehicle Condition"),
                            _buildInteractiveStarRow("Overall Experience"),
                            _buildInteractiveStarRow("App Experience"),

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
                                controller: _reviewController,
                                // FIXED: Text color set to black
                                style: GoogleFonts.nunito(color: Colors.black),
                                maxLines: 5,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Tell us your experience.",
                                  // FIXED: Hint color set to grey
                                  hintStyle: GoogleFonts.nunito(
                                    color: Colors.grey,
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
                                  // Handle Submit Logic Here
                                  debugPrint("Ratings: $_ratings");
                                  debugPrint("Review: ${_reviewController.text}");
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
      ),
    );
  }

  // Helper widget to build rows of interactive stars
  Widget _buildInteractiveStarRow(String label) {
    int currentRating = _ratings[label] ?? 0;

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
              return GestureDetector(
                onTap: () {
                  setState(() {
                    int tapRating = index + 1;
                    // FIXED: If tapping the same star count, reset to 0
                    if (_ratings[label] == tapRating) {
                      _ratings[label] = 0; 
                    } else {
                      _ratings[label] = tapRating;
                    }
                  });
                },
                child: Icon(
                  index < currentRating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: const Color(0xFFFFD700), // Gold color
                  size: 26,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}