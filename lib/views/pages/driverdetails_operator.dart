import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/drivercard_operator.dart';
import '../widgets/button.dart';
import 'success_acceptacc_operator copy.dart';
import 'success_rejectacc_operator.dart';
import 'success_removeacc_operator.dart';

class DriverDetailsPage extends StatefulWidget {
  final String name;
  final String puvType;
  final String plate;
  final String registeredDate;
  final String status;
  final String? inactiveDate;
  final String? suspensionDate;
  final String? returnDate;

  const DriverDetailsPage({
    super.key,
    required this.name,
    required this.puvType,
    required this.plate,
    required this.registeredDate,
    required this.status,
    this.inactiveDate,
    this.suspensionDate,
    this.returnDate,
  });

  @override
  State<DriverDetailsPage> createState() => _DriverDetailsPageState();
}

class _DriverDetailsPageState extends State<DriverDetailsPage> {
  int currentWeek = 0;
  bool _showRejectionReason = false; // 👈 controls visibility
  final TextEditingController _reasonController = TextEditingController();

  // Dummy weekly data
  final List<Map<String, dynamic>> weeklyData = [
    {
      "dateRange": "Sep 22 - Sep 28",
      "earnings": 52.25,
      "rating": 4.9,
      "trips": 48,
      "reports": 0,
      "graph": [40.0, 45.0, 42.0, 47.0, 50.0, 52.0, 51.0],
    },
    {
      "dateRange": "Sep 29 - Oct 5",
      "earnings": 47.75,
      "rating": 4.8,
      "trips": 50,
      "reports": 1,
      "graph": [42.0, 43.5, 44.0, 46.0, 47.0, 47.75, 47.5],
    },
  ];

  void changeWeek(int change) {
    setState(() {
      currentWeek = (currentWeek + change).clamp(0, weeklyData.length - 1);
    });
  }

  void _handleRemoveAccount() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Account'),
          content: const Text('Are you sure you want to remove this account?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Perform account removal here
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RemoveSuccessPage(),
                  ),
                ); // Close the dialog after action
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 400;
    // Get current weekday (1=Mon, 7=Sun)
    final int today = DateTime.now().weekday;
    final week = weeklyData[currentWeek];

    // Days of the week labels
    final List<String> days = ["M", "T", "W", "T", "F", "S", "S"];
    final gradientColors = const [
      Color(0xFFB945AA),
      Color(0xFF8E4CB6),
      Color(0xFF5B53C2),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 30,
            right: 30,
            bottom: 30,
            top: 20,
          ),
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

              // Title
              Text(
                "Driver Details",
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),

              // Date and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Registered: ${widget.registeredDate}",
                    style: GoogleFonts.nunito(
                      fontSize: 17,
                      color: Colors.black.withValues(alpha: 0.7),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusBackground(widget.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.status[0].toUpperCase() +
                          widget.status.substring(1),
                      style: GoogleFonts.nunito(
                        color: _statusColor(widget.status),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ✅ Add this section
              if (widget.status.toLowerCase() == "inactive")
                Text(
                  "Inactive since: ${widget.inactiveDate ?? "N/A"}",
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    color: Colors.redAccent.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                )
              else if (widget.status.toLowerCase() == "suspended")
                Text(
                  "Suspended: ${widget.suspensionDate ?? "N/A"} • Returning: ${widget.returnDate ?? "N/A"}",
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    color: Colors.orangeAccent.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),

              const SizedBox(height: 16),

              // Driver Card
              DriverCard(
                name: widget.name,
                puvType: widget.puvType,
                plate: widget.plate,
              ),

              const SizedBox(height: 16),

              // Trip Details Card
              if (widget.status.toLowerCase() == "pending") ...[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        "Driver’s License",
                        style: GoogleFonts.nunito(
                          fontSize: isSmall ? 15 : 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Card with Image inside
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey.shade400,
                            width: 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: AspectRatio(
                          aspectRatio:
                              1.6, // keeps proper proportion for the ID
                          child: Image.asset(
                            'assets/images/ID.png', // 👈 replace with your image path
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // License Number
                      Text(
                        "Driver License’s ID No: 1234567890",
                        style: GoogleFonts.nunito(
                          fontSize: isSmall ? 14 : 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                if (_showRejectionReason) ...[
                  const SizedBox(height: 16),
                  Text(
                    "Reason of Rejection:",
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reasonController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Enter reason...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                _showRejectionReason
                    ? Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: "Cancel",
                              isFilled: false,
                              strokeColor: const Color(0xFF5B53C2),
                              outlinedFillColor: Colors.white,
                              textColor: const Color(0xFF5B53C2),
                              onPressed: () {
                                setState(() {
                                  _showRejectionReason = false;
                                  _reasonController.clear();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomButton(
                              text: "Confirm",
                              isFilled: true,
                              fillColor: Colors.redAccent,
                              textColor: Colors.white,
                              onPressed: () {
                                // Confirm rejection logic here
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const RejectSuccessPage(),
                                  ),
                                );
                                print(
                                  "Rejected with reason: ${_reasonController.text}",
                                );
                              },
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: "Reject",
                              isFilled: false,
                              strokeColor: const Color(0xFF5B53C2),
                              outlinedFillColor: Colors.white,
                              textColor: const Color(0xFF5B53C2),
                              onPressed: () {
                                setState(() {
                                  _showRejectionReason = true;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomButton(
                              text: "Accept",
                              isFilled: true,
                              textColor: Colors.white,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AcceptSuccessPage(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, // start at the top
                      end: Alignment.bottomCenter, // end at the bottom
                      colors: gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + Range + Navigation
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Analytics",
                            style: GoogleFonts.nunito(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => changeWeek(-1),
                                icon: const Icon(
                                  Icons.chevron_left,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                week["dateRange"],
                                style: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              IconButton(
                                onPressed: () => changeWeek(1),
                                icon: const Icon(
                                  Icons.chevron_right,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Line Chart
                      SizedBox(
                        height: 150,
                        width: double.infinity,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                isCurved: true,
                                color: Colors.white,
                                barWidth: 3,
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                                spots: List.generate(
                                  week["graph"].length,
                                  (i) => FlSpot(i.toDouble(), week["graph"][i]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(days.length, (index) {
                          bool isToday = index + 1 == today;
                          return CircleAvatar(
                            radius: 13,
                            backgroundColor: isToday
                                ? Colors.white
                                : Colors.transparent,
                            child: Text(
                              days[index],
                              style: TextStyle(
                                color: isToday ? Colors.black : Colors.white,
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 25),

                      // Summary cards (responsive)
                      GridView.count(
                        crossAxisCount: 2, // 2x2 layout
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio:
                            1.8, // adjust for better card proportion
                        children: [
                          _buildStatCard(
                            "Total Earnings",
                            "₱ ${week["earnings"]}",
                            Colors.white,
                          ),

                          _buildStatCard(
                            "Rating",
                            week["rating"].toString(),
                            Colors.white,
                          ),

                          _buildStatCard(
                            "Trips Completed",
                            "${week["trips"]} trips",
                            Colors.white,
                          ),
                          _buildStatCard(
                            "Incident Reports",
                            week["reports"].toString(),
                            Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),
                if (widget.status.toLowerCase() == "inactive")
                  Positioned(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleRemoveAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 3,
                          shadowColor: Colors.redAccent.withValues(alpha: 0.2),
                        ),
                        child: Text(
                          "Remove Account",
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _statusBackground(String status) {
    switch (status.toLowerCase()) {
      case "suspended":
        return const Color(0xFFFFF5CC);
      case "active":
        return const Color(0xFFE9F8E8);
      case "inactive":
        return const Color(0xFFFFE5E5);
      default:
        return const Color(0xFFD8E3FE);
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "suspended":
        return const Color(0xFFFFC107);
      case "active":
        return Colors.green;
      case "inactive":
        return Colors.red;
      default:
        return const Color(0xFF1877F2);
    }
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      width: 160,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.nunito(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
          ),
        ],
      ),
    );
  }
}
