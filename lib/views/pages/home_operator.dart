import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/button.dart';
import '../widgets/navbar.dart';

class OperatorDashboardNav extends StatefulWidget {
  const OperatorDashboardNav({super.key});

  @override
  State<OperatorDashboardNav> createState() => _OperatorDashboardNavState();
}

class _OperatorDashboardNavState extends State<OperatorDashboardNav> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBottomNavBar(
      pages: const [
        OperatorDashboard(),
        Center(child: Text("📋 Drivers")),
        Center(child: Text("✍️ Transactions")),
        Center(child: Text("🔔 Reports")),
        Center(child: Text("👤 Profile")),
      ],
      items: const [
        NavItem(icon: Icons.home_rounded, label: 'Home'),
        NavItem(icon: Symbols.group, label: 'Drivers'),
        NavItem(icon: Symbols.overview_rounded, label: 'Transactions'),
        NavItem(icon: Symbols.chat_info_rounded, label: 'Reports'),
        NavItem(icon: Icons.person_rounded, label: 'Profile'),
      ],
    );
  }
}

class OperatorDashboard extends StatefulWidget {
  const OperatorDashboard({super.key});

  @override
  State<OperatorDashboard> createState() => _OperatorDashboardState();
}

class _OperatorDashboardState extends State<OperatorDashboard> {
  final List<Color> gradientColors = const [
    Color(0xFF5B53C2),
    Color(0xFFB945AA),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      body: SafeArea(
        child: SingleChildScrollView(
          //padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header Card ---
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(0),
                    bottomLeft: Radius.circular(25),
                    topRight: Radius.circular(0),
                    bottomRight: Radius.circular(25),
                  ),
                ),
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    Center(
                      child: SvgPicture.asset(
                        'assets/images/logo_white.svg',
                        height: 80,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Today's Revenue row
                    const Text(
                      "Today's Revenue",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '₱500.00',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(
                          Symbols.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),

              // --- Stats Row ---
              Padding(
                padding: const EdgeInsets.only(
                  left: 20.0,
                  right: 20.0,
                  top: 5.0,
                ),
                child: Column(
                  children: [
                    // --- Stats Row ---
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            icon: Symbols.group_rounded,
                            value: "120",
                            label: "Total Drivers",
                            color: gradientColors[0],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            icon: Symbols.directions_bus_rounded,
                            value: "90",
                            label: "Active Trips",
                            color: gradientColors[1],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // --- Driver Performance Section ---
                    _buildSectionHeader(
                      "Driver performance",
                      actionText: "View all",
                    ),
                    const SizedBox(height: 10),
                    _buildDriverCard("Riguel Alleje", "₱420", "4.8"),
                    const SizedBox(height: 8),
                    _buildDriverCard("Noah Elizalde", "₱400", "3.8"),
                    const SizedBox(height: 20),

                    // --- Reports Section ---
                    _buildSectionHeader("Reports", actionText: "See all"),
                    const SizedBox(height: 10),
                    _buildReportCard(
                      title: "Overcrowded bus",
                      plate: "GLE703",
                      status: "In progress",
                      statusColor: Colors.orange,
                      buttonText: "Track",
                    ),
                    const SizedBox(height: 8),
                    _buildReportCard(
                      title: "Route skipped stop",
                      plate: "GLE704",
                      status: "Resolved",
                      statusColor: Colors.green,
                      buttonText: "Details",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets ---

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.bold,
              fontSize: 35,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: color,
              textStyle: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: Text(
              "View details",
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.normal,
                fontSize: 14,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {String? actionText}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        if (actionText != null)
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
              textStyle: GoogleFonts.manrope(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            child: Text(actionText),
          ),
      ],
    );
  }

  Widget _buildDriverCard(String name, String revenue, String rating) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 18, backgroundColor: Colors.grey),
              const SizedBox(width: 10),
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
                    'Revenue $revenue  •  Rating $rating',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: Color.fromARGB(255, 123, 123, 123),
                    ),
                  ),
                ],
              ),
            ],
          ),
          CustomButton(
            text: 'View',
            onPressed: () {},
            isFilled: true,
            fillColor: const Color(0xFF5B53C2),
            textColor: Colors.white,
            width: 85,
            height: 30,
            borderRadius: 20,
            fontSize: 13,
            hasShadow: false,
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String plate,
    required String status,
    required Color statusColor,
    required String buttonText,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.purple.shade100),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Plate No. $plate • Status: $status',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: Color.fromARGB(255, 123, 123, 123),
                ),
              ),
              CustomButton(
                text: buttonText,
                onPressed: () {},
                isFilled: true,
                fillColor: statusColor,
                textColor: Colors.white,
                width: 85,
                height: 30,
                borderRadius: 20,
                fontSize: 13,
                hasShadow: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
