import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/button.dart';
import '../widgets/navbar.dart';
import 'admin_verification.dart';

class AdminDashboardNav extends StatefulWidget {
  const AdminDashboardNav({super.key});

  @override
  State<AdminDashboardNav> createState() => _AdminDashboardNavState();
}

class _AdminDashboardNavState extends State<AdminDashboardNav> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBottomNavBar(
      pages: const [
        AdminDashboard(),
        Center(child: Text("📋 Verified")),
        Center(child: Text("✍️ Activity")),
        Center(child: Text("🔔 Reports")),
      ],
      items: const [
        NavItem(icon: Icons.home_rounded, label: 'Home'),
        NavItem(icon: Symbols.verified, label: 'Verified'),
        NavItem(icon: Symbols.rate_review_rounded, label: 'Activity'),
        NavItem(icon: Symbols.chat_info_rounded, label: 'Reports'),
        NavItem(icon: Icons.route_rounded, label: 'Routes'),
      ],
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final List<Color> gradientColors = const [
    Color(0xFF5B53C2),
    Color(0xFFB945AA),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              Center(
                child: SvgPicture.asset('assets/images/logo.svg', height: 60),
              ),
              const SizedBox(height: 16),

              // --- Analytics Section ---
              Text(
                'Analytics',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.purple.shade100),
                ),
                child: SizedBox(
                  height: isSmall ? 180 : 220,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true, drawVerticalLine: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: 10,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, _) {
                              const days = [
                                'Mon',
                                'Tue',
                                'Wed',
                                'Thu',
                                'Fri',
                                'Sat',
                                'Sun',
                              ];
                              return Text(
                                days[value.toInt() % days.length],
                                style: GoogleFonts.nunito(fontSize: 12),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: true),
                      minX: 0,
                      maxX: 6,
                      minY: 0,
                      maxY: 60,
                      lineBarsData: [
                        LineChartBarData(
                          spots: const [
                            FlSpot(0, 10),
                            FlSpot(1, 40),
                            FlSpot(2, 25),
                            FlSpot(3, 50),
                            FlSpot(4, 20),
                            FlSpot(5, 10),
                            FlSpot(6, 15),
                          ],
                          isCurved: true,
                          gradient: LinearGradient(colors: gradientColors),
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: gradientColors
                                  .map((c) => c.withValues(alpha: 0.2))
                                  .toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- User Type Breakdown ---
              Text(
                'User Type Breakdown',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.purple.shade100),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    // Donut Chart
                    SizedBox(
                      height: 160,
                      width: 160,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 50,
                              sections: [
                                PieChartSectionData(
                                  color: gradientColors[0],
                                  value: 50,
                                  radius: 25,
                                ),
                                PieChartSectionData(
                                  color: gradientColors[1],
                                  value: 30,
                                  radius: 25,
                                ),
                                PieChartSectionData(
                                  color: Colors.blueAccent,
                                  value: 20,
                                  radius: 25,
                                ),
                              ],
                            ),
                          ),
                          const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '120',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 28,
                                ),
                              ),
                              Text('Total', style: TextStyle(fontSize: 14)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Legend
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: const [
                        _LegendDot(
                          color: Color(0xFFB945AA),
                          label: 'Commuters',
                        ),
                        _LegendDot(color: Color(0xFF5B53C2), label: 'Drivers'),
                        _LegendDot(
                          color: Colors.blueAccent,
                          label: 'Operators',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- Recent Verifications ---
              _buildSectionHeader(context, "Pending verifications", "See all"),
              const SizedBox(height: 10),
              _buildVerificationCard(
                name: "Driver name",
                role: "Driver",
                status: "Pending",
                color: Colors.orange,
                date: "Jan. 10, 2025",
              ),
              const SizedBox(height: 10),
              _buildVerificationCard(
                name: "Commuter name",
                role: "Commuter",
                status: "Approved",
                color: Colors.green,
                date: "Jan. 9, 2025",
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets ---
  Widget _buildSectionHeader(BuildContext context, String title, String actionText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
          TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminVerifiedPage(onlyVerified: false),
              ),
            );
          },
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.all(Colors.black),
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            textStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
              if (states.contains(WidgetState.pressed) || states.contains(WidgetState.hovered)) {
                return const TextStyle(
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w500,
                );
              }
              return const TextStyle(
                decoration: TextDecoration.none,
                fontWeight: FontWeight.w500,
              );
            }),
          ),
          child: Text(actionText),
        ),
      ],
    );
  }

  Widget _buildVerificationCard({
    required String name,
    required String role,
    required String status,
    required Color color,
    required String date,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.purple.shade100),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                '$status  •  $date',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          CustomButton(
            text: role,
            onPressed: () {},
            isFilled: true,
            fillColor: color,
            textColor: Colors.white,
            width: 95,
            height: 35,
            borderRadius: 20,
            fontSize: 13,
            hasShadow: false,
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(radius: 6, backgroundColor: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
