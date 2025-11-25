import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/feedback_card.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPage();
}

class _AdminReportsPage extends State<AdminReportsPage> {
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

  static const LinearGradient _kGradient = LinearGradient(
    colors: [Color(0xFF5B53C2), Color(0xFFB945AA)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

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
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reports',
                              style: GoogleFonts.manrope(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Manage reports',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: _kGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${reports.length} Reports',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Color(0xFF9C6BFF).withValues(alpha: 0.05),
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
                ],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
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
                              role: r.role,
                              id: "123456789",
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillTab(String label, int value, bool isActive, bool isSmall) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => activePriority = value),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: EdgeInsets.symmetric(vertical: isSmall ? 10 : 12),
          decoration: BoxDecoration(
            gradient: isActive ? _kGradient : null,
            color: isActive ? null : Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: isActive ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

// Added this class to fix the undefined method error
class ReportDetailsPage extends StatelessWidget {
  final String? name;
  final String? role;
  final String? id;
  final String? priority;
  final String? date;
  final String? description;
  final List<String>? tags;
  final String? imagePath;

  const ReportDetailsPage({
    super.key,
    this.name,
    this.role,
    this.id,
    this.priority,
    this.date,
    this.description,
    this.tags,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    // You can replace this with the actual UI for ReportDetailsPage later
    return Scaffold(
      appBar: AppBar(title: const Text("Report Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Name: $name",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text("Role: $role"),
            Text("Priority: $priority"),
            Text("Date: $date"),
            const SizedBox(height: 16),
            const Text(
              "Description:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(description ?? "No description"),
          ],
        ),
      ),
    );
  }
}
