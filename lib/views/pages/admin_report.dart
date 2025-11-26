import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/feedback_card.dart';
import 'reportdetails_admin.dart'; 

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPage();
}

class _AdminReportsPage extends State<AdminReportsPage> {
  // --- Data ---
  final List<ReportCard> reports = [
    ReportCard(
      name: "Aileen Grace B. Santos",
      role: "Commuter",
      priority: "Low",
      date: "09/14/25",
      description: "Passenger reported a minor delay at the jeepney stop due to traffic.",
      tags: ["Delay", "Traffic"],
      showPriority: false,
    ),
    ReportCard(
      name: "John Erik D. Bautista",
      role: "Commuter",
      priority: "Medium",
      date: "09/10/25",
      description: "A wallet was found and turned over to the terminal personnel.",
      tags: ["Lost Item"],
      showPriority: false,
    ),
    ReportCard(
      name: "Maricel P. Torres",
      role: "Driver",
      priority: "High",
      date: "09/09/25",
      description: "Driver was seen using the phone while driving. Needs investigation.",
      tags: ["Driver Conduct", "Safety"],
      showPriority: false,
    ),
    ReportCard(
      name: "Rafael D. Mendoza",
      role: "Commuter",
      priority: "Low",
      date: "09/05/25",
      description: "Passenger reported an overly loud radio that caused discomfort.",
      tags: ["Noise", "Comfort"],
      showPriority: false,
    ),
    ReportCard(
      name: "Christine Mae S. Villanueva",
      role: "Driver",
      priority: "Medium",
      date: "09/03/25",
      description: "Driver assisted a commuter with a disability boarding the jeep.",
      tags: ["Good Conduct", "Service"],
      showPriority: false,
    ),
  ];

  // --- State & Logic ---
  final List<Map<String, dynamic>> priorityTabs = [
    {"label": "Low", "value": 1},
    {"label": "Medium", "value": 2},
    {"label": "High", "value": 3},
  ];

  int activePriority = 1;

  int _priorityValue(String? priority) {
    switch (priority?.toLowerCase()) {
      case "low": return 1;
      case "medium": return 2;
      case "high": return 3;
      default: return 0;
    }
  }

  // Gradient for active state
  static const LinearGradient _kGradient = LinearGradient(
    colors: [Color(0xFFB945AA), Color(0xFF5B53C2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 420;
    
    // Filter logic
    final filteredReports = reports
        .where((r) => _priorityValue(r.priority) == activePriority)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      body: SafeArea(
        child: Column(
          children: [
            // --- Header Section ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Title and Count
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reports',
                              style: GoogleFonts.manrope(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'Manage feedback',
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Count Badge
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
                          '${filteredReports.length} Items',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Tabs
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F0FA),
                      borderRadius: BorderRadius.circular(12),
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

            // --- Reports List ---
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                            role: r.role ?? "Commuter",
                            id: "123456789", // Fixed duplicate/static ID
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
    );
  }

  // --- Tab Builder ---
  Widget _buildPillTab(String label, int value, bool isActive, bool isSmall) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => activePriority = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: EdgeInsets.symmetric(vertical: isSmall ? 10 : 12),
          decoration: BoxDecoration(
            gradient: isActive ? _kGradient : null,
            color: isActive ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: isActive ? Colors.white : Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}