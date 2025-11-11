// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/drivercard_operator.dart';
import 'driverdetails_operator.dart';

class DriverListPage extends StatefulWidget {
  const DriverListPage({super.key});

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

              const SizedBox(height: 15),

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
                              inactiveDate:
                                  driver["inactiveDate"], // optional, can be null
                              suspensionDate:
                                  driver["suspensionDate"], // optional, can be null
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
