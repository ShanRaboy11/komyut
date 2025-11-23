import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/feedback_card.dart';
import '../pages/feedbackdetails_driver.dart';
import 'report_driver.dart';

class DriverFeedbackPage extends StatefulWidget {
  const DriverFeedbackPage({super.key});

  @override
  State<DriverFeedbackPage> createState() => _DriverFeedbackPageState();
}

class _DriverFeedbackPageState extends State<DriverFeedbackPage> {
  void _sortByDate() {
    reports.sort((a, b) {
      final da = DateTime.parse(
        "20${a.date.substring(6)}-${a.date.substring(0, 2)}-${a.date.substring(3, 5)}",
      );
      final db = DateTime.parse(
        "20${b.date.substring(6)}-${b.date.substring(0, 2)}-${b.date.substring(3, 5)}",
      );
      return db.compareTo(da); // latest first
    });
    setState(() {});
  }

  void _sortByPriority() {
    const priorityOrder = {"High": 3, "Medium": 2, "Low": 1};

    reports.sort((a, b) {
      return priorityOrder[b.priority]!.compareTo(priorityOrder[a.priority]!);
    });
    setState(() {});
  }

  final List<ReportCard> reports = [
    ReportCard(
      name: "Aileen Grace B. Santos",
      priority: "Low",
      date: "09/14/25",
      description:
          "Passenger reported a minor delay at the jeepney stop due to traffic.",
      tags: ["Delay", "Traffic"],
    ),
    ReportCard(
      name: "John Erik D. Bautista",
      priority: "Medium",
      date: "09/10/25",
      description:
          "A wallet was found and turned over to the terminal personnel.",
      tags: ["Lost Item"],
    ),
    ReportCard(
      name: "Maricel P. Torres",
      priority: "High",
      date: "09/09/25",
      description:
          "Driver was seen using the phone while driving. Needs investigation.",
      tags: ["Driver Conduct", "Safety"],
    ),
  ];
  String selectedFilter = "Date";

  @override
  Widget build(BuildContext context) {
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
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(10),
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportPage()),
              );
            },
            icon: const Icon(Icons.add_rounded, size: 25, color: Colors.white),
          ),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
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
                      fontSize: 24,
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
                        value: selectedFilter,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                        ),
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        items: const [
                          DropdownMenuItem(value: "Date", child: Text("Date")),
                          DropdownMenuItem(
                            value: "Priority",
                            child: Text("Priority"),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          setState(() => selectedFilter = value);

                          if (value == "Date") {
                            _sortByDate();
                          } else {
                            _sortByPriority();
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // --- Reports List ---
              Expanded(
                child: ListView.builder(
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final r = reports[index];

                    return ReportCard(
                      name: r.name,
                      priority: r.priority,
                      date: r.date,
                      description: r.description,
                      tags: r.tags,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReportDetailsPage(
                              name: r.name,
                              role: "Commuter", // or dynamic later
                              id: "123456789", // or dynamic later
                              priority: r.priority,
                              date: r.date,
                              description: r.description,
                              tags: r.tags,
                              imagePath: "assets/images/sample bottle.png",
                            ),
                          ),
                        );
                      },
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
