// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/drivercard_operator.dart';
import 'driverdetails_operator.dart';

class DriverListPage extends StatefulWidget {
  final int initialStatus;
  final bool showPendingOnly; // 👈 add this

  const DriverListPage({
    super.key,
    this.initialStatus = 1,
    this.showPendingOnly = false,
  });

  @override
  State<DriverListPage> createState() => DriverListPageState();
}

class DriverListPageState extends State<DriverListPage>
    with SingleTickerProviderStateMixin {
  final List<Map<String, String>> driverList = [
    {
      "name": "James Rodriguez",
      "puvType": "Modern",
      "plate": "NBG 4521",
      "status": "active",
      "registeredDate": "January 5, 2024",
    },
    {
      "name": "Noel Fernandez",
      "puvType": "Modern",
      "plate": "TAX 9132",
      "status": "active",
      "registeredDate": "February 12, 2024",
    },
    {
      "name": "Brent Castillo",
      "puvType": "Traditional",
      "plate": "AB 24567",
      "status": "active",
      "registeredDate": "March 8, 2024",
    },
    {
      "name": "Dean Alvarez",
      "puvType": "Modern",
      "plate": "TRI 889",
      "status": "inactive",
      "inactiveDate": "September 10, 2025",
      "registeredDate": "May 20, 2024",
    },
    {
      "name": "Mark Adrian Cruz",
      "puvType": "Traditional",
      "plate": "XFR 6375",
      "status": "active",
      "registeredDate": "April 3, 2024",
    },
    {
      "name": "Raymund S. Villanueva",
      "puvType": "Traditional",
      "plate": "JKL 4412",
      "status": "active",
      "registeredDate": "June 15, 2024",
    },
    {
      "name": "Alexis Ramos",
      "puvType": "Modern",
      "plate": "TXI 3728",
      "status": "suspended",
      "suspensionDate": "October 18, 2025",
      "returnDate": "November 5, 2025",
      "registeredDate": "July 21, 2024",
    },
    {
      "name": "John Carlo Mendoza",
      "puvType": "Modern",
      "plate": "UVE 0291",
      "status": "inactive",
      "inactiveDate": "August 14, 2025",
      "registeredDate": "August 2, 2024",
    },
    {
      "name": "John Doe",
      "puvType": "Modern",
      "plate": "UVE 0291",
      "status": "pending",
      "registeredDate": "October 13, 2025",
    },
    {
      "name": "Carlo Mendoza",
      "puvType": "Modern",
      "plate": "UVE 0491",
      "status": "pending",
      "registeredDate": "November 5, 2025",
    },
  ];
  final List<Map<String, dynamic>> statusTabs = [
    {"label": "Active", "value": 1},
    {"label": "Inactive", "value": 2},
    {"label": "Suspended", "value": 3},
  ];

  int _statusValue(String? status) {
    switch (status?.toLowerCase()) {
      case "active":
        return 1;
      case "inactive":
        return 2;
      case "suspended":
        return 3;
      default:
        return 0; // no priority
    }
  }

  final Color primary1 = const Color(0xFF9C6BFF);

  late int activeStatus;
  @override
  void initState() {
    super.initState();
    activeStatus = widget.initialStatus; // 👈 initialize from constructor
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 420;
    final pendingDrivers = driverList
        .where((driver) => driver["status"] == "pending")
        .toList();
    final filteredDrivers = driverList
        .where((driver) => _statusValue(driver["status"]) == activeStatus)
        .toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // Back button (aligned to the left)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  // Centered title
                  Text(
                    "Drivers",
                    style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Header
              if (widget.showPendingOnly) ...[
                Text(
                  'Pending Drivers',
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                pendingDrivers.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Text(
                            "No Pending Drivers",
                            style: GoogleFonts.nunito(
                              fontSize: 20,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: pendingDrivers.length,
                        itemBuilder: (context, index) {
                          final driver = pendingDrivers[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: DriverCard(
                              name: driver["name"]!,
                              puvType: driver["puvType"]!,
                              plate: driver["plate"]!,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DriverDetailsPage(
                                      name: driver["name"]!,
                                      puvType: driver["puvType"]!,
                                      plate: driver["plate"]!,
                                      status: driver["status"]!,
                                      registeredDate: driver["registeredDate"]!,
                                      inactiveDate: driver["inactiveDate"],
                                      suspensionDate: driver["suspensionDate"],
                                      returnDate: driver["returnDate"],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ] else ...[
                // ✅ Otherwise show the tabbed layout for Active/Inactive/Suspended
                Text(
                  'All Drivers',
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primary1.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: statusTabs
                        .map(
                          (tab) => _buildPillTab(
                            tab["label"],
                            tab["value"],
                            activeStatus == tab["value"],
                            isSmall,
                          ),
                        )
                        .toList(),
                  ),
                ),

                const SizedBox(height: 15),

                filteredDrivers.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Text(
                            "No ${statusTabs.firstWhere((tab) => tab['value'] == activeStatus)['label']} Drivers",
                            style: GoogleFonts.nunito(
                              fontSize: 20,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredDrivers.length,
                        itemBuilder: (context, index) {
                          final driver = filteredDrivers[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: DriverCard(
                              name: driver["name"]!,
                              puvType: driver["puvType"]!,
                              plate: driver["plate"]!,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DriverDetailsPage(
                                      name: driver["name"]!,
                                      puvType: driver["puvType"]!,
                                      plate: driver["plate"]!,
                                      status: driver["status"]!,
                                      registeredDate: driver["registeredDate"]!,
                                      inactiveDate: driver["inactiveDate"],
                                      suspensionDate: driver["suspensionDate"],
                                      returnDate: driver["returnDate"],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillTab(String label, int value, bool isActive, bool isSmall) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => activeStatus = value),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: isSmall ? 10 : 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: GoogleFonts.nunito(
              fontSize: 15,
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
