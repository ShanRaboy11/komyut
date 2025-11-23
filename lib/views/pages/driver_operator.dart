import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'driverlist_operator.dart';
import '../widgets/drivercard_operator.dart';
import 'driverdetails_operator.dart';

class OperatorDriversPage extends StatefulWidget {
  const OperatorDriversPage({super.key});

  @override
  State<OperatorDriversPage> createState() => _OperatorDriversPageState();
}

class _OperatorDriversPageState extends State<OperatorDriversPage> {
  String rangeFilter = "Weekly";
  String metricFilter = "Top Earners";
  DateTime currentDate = DateTime.now();

  // Dummy data variations
  final Map<String, List<Map<String, dynamic>>> dummyData = {
    "Top Earners": [
      {"name": "Gio", "value": 1500},
      {"name": "James", "value": 1000},
      {"name": "Noel", "value": 900},
      {"name": "Brent", "value": 400},
      {"name": "Dean", "value": 100},
    ],
    "Top Ratings": [
      {"name": "Noel", "value": 4.9},
      {"name": "James", "value": 4.7},
      {"name": "Gio", "value": 4.6},
      {"name": "Dean", "value": 4.2},
      {"name": "Brent", "value": 3.9},
    ],
    "Top Trips": [
      {"name": "James", "value": 320},
      {"name": "Gio", "value": 250},
      {"name": "Brent", "value": 150},
      {"name": "Noel", "value": 120},
      {"name": "Dean", "value": 60},
    ],
  };

  // --------- DATE LABEL LOGIC ----------
  String getFormattedDate() {
    switch (rangeFilter) {
      case "Daily":
        return "${currentDate.month}/${currentDate.day}/${currentDate.year}";
      case "Weekly":
        final start = currentDate.subtract(
          Duration(days: currentDate.weekday - 1),
        );
        final end = start.add(const Duration(days: 6));
        return "${start.month}/${start.day} - ${end.month}/${end.day}";
      case "Monthly":
        return "${_monthName(currentDate.month)} ${currentDate.year}";
      case "Yearly":
        return "${currentDate.year}";
    }
    return "";
  }

  String _monthName(int m) {
    const names = [
      "",
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return names[m];
  }

  // --------- NAVIGATION ---------
  void goPrevious() {
    setState(() {
      switch (rangeFilter) {
        case "Daily":
          currentDate = currentDate.subtract(const Duration(days: 1));
          break;
        case "Weekly":
          currentDate = currentDate.subtract(const Duration(days: 7));
          break;
        case "Monthly":
          currentDate = DateTime(currentDate.year, currentDate.month - 1, 1);
          break;
        case "Yearly":
          currentDate = DateTime(currentDate.year - 1, 1, 1);
          break;
      }
    });
  }

  void goNext() {
    setState(() {
      switch (rangeFilter) {
        case "Daily":
          currentDate = currentDate.add(const Duration(days: 1));
          break;
        case "Weekly":
          currentDate = currentDate.add(const Duration(days: 7));
          break;
        case "Monthly":
          currentDate = DateTime(currentDate.year, currentDate.month + 1, 1);
          break;
        case "Yearly":
          currentDate = DateTime(currentDate.year + 1, 1, 1);
          break;
      }
    });
  }

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
  final gradientColors = const [
    Color(0xFFB945AA),
    Color(0xFF8E4CB6),
    Color(0xFF5B53C2),
  ];
  int pendingApplications = 2;

  @override
  Widget build(BuildContext context) {
    final data = dummyData[metricFilter]!;
    final maxValue = data.first["value"].toDouble();
    final activeDrivers = driverList
        .where((d) => d["status"] == "active")
        .take(4)
        .toList();

    final pendingDrivers = driverList
        .where((d) => d["status"] == "pending")
        .take(2)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Row + Range Filter
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Analytics",
                    style: GoogleFonts.manrope(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFB945AA),
                          Color(0xFF8E4CB6),
                          Color(0xFF5B53C2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: DropdownButton<String>(
                      value: rangeFilter,
                      dropdownColor: const Color(0xFF8A56F0),
                      underline: const SizedBox(),
                      iconEnabledColor: Colors.white,
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      onChanged: (v) => setState(() => rangeFilter = v!),
                      items: ["Daily", "Weekly", "Monthly", "Yearly"]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // MAIN CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  top: 18,
                  bottom: 18,
                  left: 20,
                  right: 20,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFB945AA),
                      Color(0xFF8E4CB6),
                      Color(0xFF5B53C2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Metric Filter + Date Navigation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DropdownButton<String>(
                          value: metricFilter,
                          dropdownColor: const Color(0xFF8E4CB6),
                          underline: const SizedBox(),
                          iconEnabledColor: Colors.white,
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          onChanged: (v) => setState(() => metricFilter = v!),
                          items: ["Top Earners", "Top Ratings", "Top Trips"]
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: goPrevious,
                              icon: const Icon(
                                Icons.chevron_left,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              getFormattedDate(),
                              style: GoogleFonts.nunito(color: Colors.white70),
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: goNext,
                              icon: const Icon(
                                Icons.chevron_right,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Column(
                      children: data.asMap().entries.map((entry) {
                        final i = entry.key;
                        final item = entry.value;
                        final name = item["name"];
                        final value = item["value"];
                        final barFactor = (value.toDouble() / maxValue).clamp(
                          0.05,
                          1.0,
                        );

                        // Dynamic label formats
                        String displayValue() {
                          if (metricFilter == "Top Ratings") {
                            return "$value ★";
                          }

                          if (metricFilter == "Top Trips") {
                            return "$value trips";
                          }

                          return "PHP $value";
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Text(
                                "${i + 1}.  ",
                                style: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Stack(
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    Container(
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: Colors.white24,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: barFactor,
                                      child: Container(
                                        height: 26,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.4,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        "$name • ${displayValue()}",
                                        style: GoogleFonts.nunito(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Recent Trips Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Active Drivers",
                    style: GoogleFonts.manrope(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 30),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const DriverListPage(showPendingOnly: false),
                        ),
                      );
                    },
                    child: Text(
                      "View All",
                      style: GoogleFonts.nunito(
                        color: const Color.fromARGB(255, 42, 42, 42),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              if (activeDrivers.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      "No Active Drivers",
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activeDrivers.length,
                  itemBuilder: (context, index) {
                    final driver = activeDrivers[index];
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
                                registeredDate: driver["registeredDate"]!,
                                status: driver["status"]!,
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

              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Pending Drivers",
                    style: GoogleFonts.manrope(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 30),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const DriverListPage(showPendingOnly: true),
                        ),
                      );
                    },
                    child: Text(
                      "View All",
                      style: GoogleFonts.nunito(
                        color: const Color.fromARGB(255, 42, 42, 42),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              if (pendingDrivers.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
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
              else
                ListView.builder(
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
                                registeredDate: driver["registeredDate"]!,
                                status: driver["status"]!,
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
          ),
        ),
      ),
    );
  }
}
