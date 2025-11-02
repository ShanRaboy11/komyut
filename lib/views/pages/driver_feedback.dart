import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/report_card.dart'; // make sure to import your ReportCard file

class DriverFeedbackPage extends StatelessWidget {
  const DriverFeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 400;

    final gradientColors = const [
      Color(0xFFB945AA),
      Color(0xFF8E4CB6),
      Color(0xFF5B53C2),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100, right: 10),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () {
              // TODO: Navigate to your Add Report page
              // Navigator.push(context, MaterialPageRoute(builder: (_) => AddReportPage()));
            },
            icon: const Icon(Icons.add_rounded, size: 30, color: Colors.white),
          ),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header Row: Title + Sort Dropdown ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Feedback",
                    style: GoogleFonts.manrope(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: gradientColors,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: const Color(0xFF8A56F0),
                        value: "Date",
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                        ),
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        items: const [
                          DropdownMenuItem(value: "Date", child: Text("Date")),
                          DropdownMenuItem(
                            value: "Priority",
                            child: Text("Priority"),
                          ),
                        ],
                        onChanged: (value) {},
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // --- Reports List ---
              Expanded(
                child: ListView.builder(
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return const ReportCard(
                      name: "Shan Michael V. Raboy",
                      priority: "High",
                      date: "09/11/25",
                      description:
                          "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna...",
                      tags: ["Vehicle", "Lost Item"],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
