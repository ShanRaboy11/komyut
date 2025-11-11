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
              const DriverCard(
                name: "Gio Christian D. Macatual",
                puvType: "Driver",
                plate: "735TUK",
              ),
              const SizedBox(height: 16),
              const DriverCard(
                name: "Gio Christian D. Macatual",
                puvType: "Driver",
                plate: "735TUK",
              ),
              const SizedBox(height: 16),
              const DriverCard(
                name: "Gio Christian D. Macatual",
                puvType: "Driver",
                plate: "735TUK",
              ),
              const SizedBox(height: 16),
              const DriverCard(
                name: "Gio Christian D. Macatual",
                puvType: "Driver",
                plate: "735TUK",
              ),
              const SizedBox(height: 16),
              const DriverCard(
                name: "Gio Christian D. Macatual",
                puvType: "Driver",
                plate: "735TUK",
              ),
              const SizedBox(height: 16),
              const DriverCard(
                name: "Gio Christian D. Macatual",
                puvType: "Driver",
                plate: "735TUK",
              ),

              const SizedBox(height: 20),
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
