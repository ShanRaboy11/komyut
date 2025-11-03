import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../pages/report_p2.dart';

class ReportIssueCard extends StatefulWidget {
  const ReportIssueCard({super.key});

  @override
  State<ReportIssueCard> createState() => _ReportIssueCardState();
}

class _ReportIssueCardState extends State<ReportIssueCard> {
  final List<String> selectedCategories = [];
  String severity = 'High';

  final List<String> categories = [
    "Vehicle",
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
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 30),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFB945AA), Color(0xFF8E4CB6), Color(0xFF5B53C2)],
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Report an Issue",
              style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Thank you for using komyut. Please report any issues you experienced during your ride. Your report helps us improve safety and service.",
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 24),

            // --- Category of Concern Title ---
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Category of Concern",
                style: GoogleFonts.nunito(
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
                style: GoogleFonts.nunito(fontSize: 12, color: Colors.white70),
              ),
            ),
            const SizedBox(height: 12),

            // --- 2 Column Category Buttons ---
            LayoutBuilder(
              builder: (context, constraints) {
                final double itemWidth = (constraints.maxWidth - 12) / 2;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: categories.map((category) {
                    final bool selected = selectedCategories.contains(category);

                    return GestureDetector(
                      onTap: () => toggleCategory(category),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: itemWidth,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white70),
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
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Severity options
            RadioGroup<String>(
              groupValue: severity, // State is managed here for the whole group
              onChanged: (value) => setState(
                () => severity = value!,
              ), // State change is handled here
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ["Low", "Medium", "High"].map((level) {
                  // This loop now creates one Radio widget and one Text widget for each level
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Use simple Radio<String>
                      Radio<String>(
                        value: level, // This is the unique value for the group
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
              crossAxisAlignment:
                  CrossAxisAlignment.stretch, // makes children full width
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF5B53C2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReportIssueCard2(),
                      ),
                    );
                  },
                  child: Text(
                    "Continue",
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.nunito(
                      color: Colors.white,
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
    );
  }
}
