import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/big_card.dart';
import 'success_reportpage_commuter.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  bool showFirst = true;
  bool show = false;
  bool showSecondSheet = false;

  double _sheetHeight = 0;
  double _sheetOpacity = 0;
  double _logoOpacity = 0.0;
  final List<String> selectedCategories = [];
  String severity = 'High';

  final List<String> categories = [
    "Vehicle",
    "Driver",
    "Route",
    "Safety & Security",
    "Traffic",
    "Lost Item",
    "App",
    "Miscellaneous",
  ];

  void toggleCategory(String category) {
    setState(() {
      if (selectedCategories.contains(category)) {
        selectedCategories.remove(category);
      } else {
        selectedCategories.add(category);
      }
    });
  }

  @override
  void initState() {
    super.initState();

    // Fade in logo AFTER first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenSize = MediaQuery.of(context).size; // ✅ FIXED
      setState(() {
        _sheetHeight = screenSize.height * 0.78;
        _sheetOpacity = 1.0; // ✅ Now valid
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _logoOpacity = 1.0; // fade in logo
      });
    });

    // Swap image after delay
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => showFirst = false);
      }
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
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        leading: AnimatedOpacity(
          opacity: _logoOpacity,
          duration: const Duration(milliseconds: 2000),
          curve: Curves.easeOut,
          child: IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: Colors.black),
            onPressed: () {
              _collapseSheet();
              // wait for the animation to finish before popping
              Future.delayed(const Duration(milliseconds: 200), () {
                Navigator.pop(context);
              });
            },
          ),
        ),
        title: AnimatedOpacity(
          opacity: _logoOpacity,
          duration: const Duration(milliseconds: 2000),
          curve: Curves.easeOut,
          child: Text(
            'Reports',
            style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFF8F7FF),
        child: Stack(
          children: [
            Positioned(
              top: screenSize.height * 0.10,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _sheetOpacity,
                  duration: const Duration(milliseconds: 2000),
                  curve: Curves.easeOut,
                  child: Image.asset(
                    'assets/images/komyut small logo.png',
                    width: screenSize.width * 0.5,
                  ),
                ),
              ),
            ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              bottom: 0,
              left: 0,
              right: 0,
              height: showSecondSheet ? 0 : _sheetHeight,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 600),
                opacity: _sheetHeight == 0 ? 0 : 1,
                curve: Curves.easeOutCubic,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  decoration: const ShapeDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(0.50, 0.00),
                      end: Alignment(0.50, 1.00),
                      colors: [
                        Color(0xFFB945AA),
                        Color(0xFF8E4CB6),
                        Color(0xFF5B53C2),
                      ],
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(60),
                        topRight: Radius.circular(60),
                      ),
                    ),
                    shadows: [
                      BoxShadow(
                        color: Color(0xFFF8F7FF),
                        blurRadius: 4,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: BigCard(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 65.0,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Report an Issue",
                              style: GoogleFonts.manrope(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Thank you for using komyut. Please report any issues you experienced during your ride. Your report helps us improve safety and service.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // --- Category of Concern Title ---
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Category of Concern",
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Select all that apply.",
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // --- 2 Column Category Buttons ---
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final double itemWidth =
                                    (constraints.maxWidth - 12) / 2;

                                return Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: categories.map((category) {
                                    final bool selected = selectedCategories
                                        .contains(category);

                                    return GestureDetector(
                                      onTap: () => toggleCategory(category),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        width: itemWidth,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? Colors.white
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: Colors.white70,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          category,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.nunito(
                                            fontSize: 14,
                                            fontWeight: selected
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            color: selected
                                                ? const Color(0xFF5B53C2)
                                                : Colors.white,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),

                            const SizedBox(height: 24),

                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Severity",
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Severity options
                            RadioGroup<String>(
                              groupValue:
                                  severity, // State is managed here for the whole group
                              onChanged: (value) => setState(
                                () => severity = value!,
                              ), // State change is handled here
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: ["Low", "Medium", "High"].map((
                                  level,
                                ) {
                                  // This loop now creates one Radio widget and one Text widget for each level
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // 1. Use simple Radio<String>
                                      Radio<String>(
                                        value:
                                            level, // This is the unique value for the group
                                        activeColor: Colors.white,
                                        // groupValue and onChanged are managed by the parent RadioGroup
                                      ),
                                      // 2. The Text label
                                      Text(
                                        level,
                                        // Assuming GoogleFonts.nunito is defined
                                        style: GoogleFonts.nunito(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),

                            const SizedBox(height: 40),

                            // Buttons
                            Column(
                              crossAxisAlignment: CrossAxisAlignment
                                  .stretch, // makes children full width
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF5B53C2),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      showSecondSheet = true;
                                    });
                                  },
                                  child: Text(
                                    "Continue",
                                    style: GoogleFonts.nunito(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              bottom: 0,
              left: 0,
              right: 0,
              height: showSecondSheet ? _sheetHeight : 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 600),
                opacity: _sheetHeight == 0 ? 0 : 1,
                curve: Curves.easeOutCubic,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  decoration: const ShapeDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(0.50, 0.00),
                      end: Alignment(0.50, 1.00),
                      colors: [
                        Color(0xFFB945AA),
                        Color(0xFF8E4CB6),
                        Color(0xFF5B53C2),
                      ],
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(60),
                        topRight: Radius.circular(60),
                      ),
                    ),
                    shadows: [
                      BoxShadow(
                        color: Color(0xFFF8F7FF),
                        blurRadius: 4,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: BigCard(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 65.0,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Report an Issue",
                              style: GoogleFonts.manrope(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Thank you for using komyut. Please report any issues you experienced during your ride. Your report helps us improve safety and service.",
                              style: GoogleFonts.nunito(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),

                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Report Details",
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white38),
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white12,
                              ),
                              child: TextField(
                                maxLines: 4,
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.all(12),
                                  hintText: "Tell us what happened.",
                                  hintStyle: GoogleFonts.nunito(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                  border: InputBorder.none,
                                ),
                                style: TextStyle(color: Colors.white),
                              ),
                            ),

                            const SizedBox(height: 20),

                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Attachment",
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            Container(
                              width: double.infinity,
                              height: 120,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white38),
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white12,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    color: Colors.white70,
                                    size: 36,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Add photo (optional)",
                                    style: GoogleFonts.nunito(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 40),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment
                                  .stretch, // makes children full width
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF5B53C2),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const SuccessPage(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    "Submit Report",
                                    style: GoogleFonts.nunito(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
