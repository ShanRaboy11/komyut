// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/trip_card.dart';
import '../widgets/drivercard_operator.dart';

class DriverListPage extends StatefulWidget {
  const DriverListPage({super.key});

  @override
  State<DriverListPage> createState() => DriverListPageState();
}

class DriverListPageState extends State<DriverListPage>
    with SingleTickerProviderStateMixin {
  final List<Map<String, String>> driverList = [
    {"name": "James Rodriguez", "puvType": "Modern", "plate": "NBG 4521"},
    {"name": "Noel Fernandez", "puvType": "Modern", "plate": "TAX 9132"},
    {"name": "Brent Castillo", "puvType": "Traditional", "plate": "AB 24567"},
    {"name": "Dean Alvarez", "puvType": "Modern", "plate": "TRI 889"},
    {"name": "Mark Adrian Cruz", "puvType": "Traditional", "plate": "XFR 6375"},
    {
      "name": "Raymund S. Villanueva",
      "puvType": "Traditional",
      "plate": "JKL 4412",
    },
    {"name": "Alexis Ramos", "puvType": "Modern", "plate": "TXI 3728"},
    {"name": "John Carlo Mendoza", "puvType": "Modern", "plate": "UVE 0291"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
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
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
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
              Text(
                'All Drivers',
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),

              // Tabs with animated selection
              Row(
                children: [
                  Text(
                    "Status",
                    style: GoogleFonts.nunito(
                      color: const Color.fromARGB(255, 0, 0, 0),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 20),
                  _buildStatusDot(Colors.yellow, "Ongoing"),
                  const SizedBox(width: 20),
                  _buildStatusDot(Colors.green, "Completed"),
                  const SizedBox(width: 20),
                  _buildStatusDot(Colors.red, "Cancelled"),
                ],
              ),
              const SizedBox(height: 16),

              // Recent Trips List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: driverList.length,
                itemBuilder: (context, index) {
                  final driver = driverList[index];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DriverCard(
                      name: driver["name"]!,
                      puvType: driver["puvType"]!,
                      plate: driver["plate"]!,
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

  Widget _buildStatusDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.nunito(fontSize: 14)),
      ],
    );
  }
}
