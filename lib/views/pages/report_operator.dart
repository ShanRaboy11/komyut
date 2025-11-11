import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/feedback_card.dart';
import '../pages/reportdetails_operator.dart';

class OperatorReportsPage extends StatefulWidget {
  const OperatorReportsPage({super.key});

  @override
  State<OperatorReportsPage> createState() => _OperatorReportsPageState();
}

class _OperatorReportsPageState extends State<OperatorReportsPage> {
  final List<ReportCard> reports = [
    ReportCard(
      name: "Aileen Grace B. Santos",
      role: "Commuter",
      priority: "Low",
      date: "09/14/25",
      description:
          "Passenger reported a minor delay at the jeepney stop due to traffic.",
      tags: ["Delay", "Traffic"],
      showPriority: false,
    ),

    ReportCard(
      name: "John Erik D. Bautista",
      role: "Commuter",
      priority: "Medium",
      date: "09/10/25",
      description:
          "A wallet was found and turned over to the terminal personnel.",
      tags: ["Lost Item"],
      showPriority: false,
    ),

    ReportCard(
      name: "Maricel P. Torres",
      role: "Driver",
      priority: "High",
      date: "09/09/25",
      description:
          "Driver was seen using the phone while driving. Needs investigation.",
      tags: ["Driver Conduct", "Safety"],
      showPriority: false,
    ),

    ReportCard(
      name: "Rafael D. Mendoza",
      role: "Commuter",
      priority: "Low",
      date: "09/05/25",
      description:
          "Passenger reported an overly loud radio that caused discomfort.",
      tags: ["Noise", "Comfort"],
      showPriority: false,
    ),

    ReportCard(
      name: "Christine Mae S. Villanueva",
      role: "Driver",
      priority: "Medium",
      date: "09/03/25",
      description:
          "Driver assisted a commuter with a disability boarding the jeep.",
      tags: ["Good Conduct", "Service"],
      showPriority: false,
    ),
  ];

  String selectedFilter = "Date";

  final List<Map<String, dynamic>> priorityTabs = [
    {"label": "Low", "value": 1},
    {"label": "Medium", "value": 2},
    {"label": "High", "value": 3},
  ];

  int activePriority = 1;
  int _priorityValue(String? priority) {
    switch (priority?.toLowerCase()) {
      case "low":
        return 1;
      case "medium":
        return 2;
      case "high":
        return 3;
      default:
        return 0; // no priority
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 420;
    final filteredReports = reports
        .where((r) => _priorityValue(r.priority) == activePriority)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),

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
                    "Reports",
                    style: GoogleFonts.manrope(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Color(0xFF9C6BFF).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: priorityTabs
                      .map(
                        (tab) => _buildPillTab(
                          tab["label"],
                          tab["value"],
                          activePriority == tab["value"],
                          isSmall,
                        ),
                      )
                      .toList(),
                ),
              ),

              const SizedBox(height: 16),

              // --- Reports List ---
              Expanded(
                child: ListView.builder(
                  itemCount: filteredReports.length,
                  itemBuilder: (context, index) {
                    final r = filteredReports[index];

                    return ReportCard(
                      name: r.name,
                      priority: r.priority,
                      role: r.role,
                      date: r.date,
                      description: r.description,
                      tags: r.tags,
                      showPriority: false,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReportDetailsPage(
                              name: r.name,
                              role: r.role, // or dynamic later
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

  Widget _buildPillTab(String label, int value, bool isActive, bool isSmall) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => activePriority = value),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: isSmall ? 10 : 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: GoogleFonts.manrope(
              fontSize: 16,
              color: isActive ? Color(0xFF8E4CB6) : Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
