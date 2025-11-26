import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import '../widgets/button.dart';
import '../widgets/navbar.dart';
import 'report_operator.dart';
import 'reportdetails_operator.dart';

import '../providers/operator_dashboard.dart';
import '../providers/wallet_provider.dart';
import '../providers/operator_report.dart';
import '../widgets/role_navbar_wrapper.dart';
import 'driver_operator.dart';
import 'activity_operator.dart';
import 'profile.dart';
import 'wallet_operator.dart';

class OperatorDashboardNav extends StatefulWidget {
  const OperatorDashboardNav({super.key});

  @override
  State<OperatorDashboardNav> createState() => _OperatorDashboardNavState();
}

class _OperatorDashboardNavState extends State<OperatorDashboardNav> {
  bool _isWalletOpen = false;

  void _openWallet() {
    setState(() {
      _isWalletOpen = true;
    });
  }

  void _closeWallet() {
    setState(() {
      _isWalletOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OperatorDashboardProvider()),
        ChangeNotifierProvider(
          create: (_) => OperatorWalletProvider()..loadWalletDashboard(),
        ),
        ChangeNotifierProvider(create: (_) => OperatorReportProvider()),
      ],
      child: AnimatedBottomNavBar(
        pages: [
          _isWalletOpen
              ? OperatorWalletPage(onBack: _closeWallet)
              : OperatorDashboard(onViewWallet: _openWallet),
          const Center(child: Text("📋 Drivers")),
          const OperatorReportsPage(),
          const Center(child: Text("👤 Profile")),
        ],
        items: const [
          NavItem(icon: Icons.home_rounded, label: 'Home'),
          NavItem(icon: Symbols.group, label: 'Drivers'),
          NavItem(icon: Symbols.assessment, label: 'Reports'),
          NavItem(icon: Icons.person_rounded, label: 'Profile'),
        ],
      ),
    );
  }
}

class OperatorDashboard extends StatefulWidget {
  final VoidCallback? onViewWallet;

  const OperatorDashboard({super.key, this.onViewWallet});

  @override
  State<OperatorDashboard> createState() => _OperatorDashboardState();
}

class _OperatorDashboardState extends State<OperatorDashboard>
    with AutomaticKeepAliveClientMixin {
  final List<Color> gradientColors = const [
    Color(0xFF5B53C2),
    Color(0xFFB945AA),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<OperatorDashboardProvider>();

      if (!provider.isLoading &&
          provider.driverPerformance.isEmpty &&
          provider.todaysRevenue == 0) {
        provider.loadDashboardData();
      }
      
      // Fetch reports after dashboard loads
      final reportProvider = context.read<OperatorReportProvider>();
      if (reportProvider.reports.isEmpty && !reportProvider.isLoading) {
        reportProvider.fetchReports();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      body: SafeArea(
        child: Consumer<OperatorDashboardProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradientColors),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(0),
                            bottomLeft: Radius.circular(25),
                            topRight: Radius.circular(0),
                            bottomRight: Radius.circular(25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(width: 70, height: 70, decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(10))),
                            const SizedBox(height: 24),
                            Container(width: 120, height: 14, color: Colors.white.withAlpha(30)),
                            const SizedBox(height: 8),
                            Container(width: 220, height: 30, color: Colors.white),
                            const SizedBox(height: 24),
                            Container(width: 140, height: 44, decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(30))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: Container(height: 110, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)))) ,
                                const SizedBox(width: 12),
                                Expanded(child: Container(height: 110, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)))) ,
                              ],
                            ),
                            const SizedBox(height: 20),

                            Container(width: 160, height: 18, color: Colors.white),
                            const SizedBox(height: 10),

                            Column(children: List.generate(3, (_) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Container(
                                height: 64,
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Row(
                                  children: [
                                    Container(width: 32, height: 32, decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(width: 120, height: 12, color: Colors.white),
                                          const SizedBox(height: 6),
                                          Container(width: 180, height: 10, color: Colors.white),
                                        ],
                                      ),
                                    ),
                                    Container(width: 60, height: 28, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
                                  ],
                                ),
                              ),
                            ))),

                            const SizedBox(height: 20),
                            Container(width: 120, height: 18, color: Colors.white),
                            const SizedBox(height: 10),

                            Column(children: List.generate(3, (_) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Container(
                                height: 80,
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(width: 180, height: 12, color: Colors.white),
                                    const SizedBox(height: 8),
                                    Row(children: [Container(width: 160, height: 10, color: Colors.white), const Spacer(), Container(width: 70, height: 28, color: Colors.white)]),
                                  ],
                                ),
                              ),
                            ))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            }

            if (provider.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading dashboard',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        provider.errorMessage!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => provider.loadDashboardData(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                // Capture the other provider before awaiting to avoid using
                // BuildContext across async gaps (use_build_context_synchronously).
                final reportsProvider = context.read<OperatorReportProvider>();
                await provider.loadDashboardData();
                await reportsProvider.fetchReports();
              },
              color: gradientColors[0],
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/images/logo_white.svg',
                            height: 70,
                          ),
                          const SizedBox(height: 24),

                          Text(
                            "Today's Revenue",
                            style: GoogleFonts.nunito(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),

                          Text(
                            provider.todaysRevenueFormatted,
                            style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                            ),
                          ),

                          const SizedBox(height: 24),

                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: InkWell(
                              onTap: () {
                                if (widget.onViewWallet != null) {
                                  widget.onViewWallet!();
                                }
                              },
                              borderRadius: BorderRadius.circular(30),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Symbols.account_balance_wallet_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "My Wallet",
                                      style: GoogleFonts.manrope(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),

                    Padding(
                      padding: const EdgeInsets.only(
                        left: 20.0,
                        right: 20.0,
                        top: 20.0,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  icon: Symbols.group_rounded,
                                  value: provider.totalDriversDisplay,
                                  label: "Total Drivers",
                                  color: gradientColors[0],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  icon: Symbols.directions_bus_rounded,
                                  value: provider.activeTripsDisplay,
                                  label: "Active Trips",
                                  color: gradientColors[1],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          _buildSectionHeader(
                            "Driver performance",
                            actionText: "View all",
                          ),
                          const SizedBox(height: 10),
                          ...provider.driverPerformance.map((driver) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _buildDriverCard(
                                driver['name'] ?? 'Unknown Driver',
                                provider.getDriverRevenueFormatted(driver),
                                provider.getDriverRatingFormatted(driver),
                              ),
                            );
                          }),
                          if (provider.driverPerformance.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  'No driver performance data available',
                                  style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 20),

                          _buildSectionHeader(
                            "Reports",
                            actionText: "See all",
                            onAction: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OperatorNavBarWrapper(
                                    homePage: OperatorDashboardNav(),
                                    driversPage: OperatorDriversPage(),
                                    transactionsPage: const OperatorRemittancesPage(),
                                    reportsPage: ChangeNotifierProvider(
                                      create: (_) => OperatorReportProvider()..fetchReports(),
                                      child: const OperatorReportsPage(),
                                    ),
                                    profilePage: ProfilePage(),
                                    initialIndex: 2,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          Consumer<OperatorReportProvider>(
                            builder: (context, reportProvider, child) {
                              // Take only the first 3 reports
                              final limitedReports = reportProvider.reports.take(3).toList();

                              if (reportProvider.isLoading && limitedReports.isEmpty) {
                                // Show shimmer for reports section
                                return Column(
                                  children: List.generate(3, (_) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Shimmer.fromColors(
                                      baseColor: Colors.grey.shade300,
                                      highlightColor: Colors.grey.shade100,
                                      child: Container(
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.grey.shade300),
                                        ),
                                      ),
                                    ),
                                  )),
                                );
                              }

                              if (reportProvider.errorMessage != null) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      children: [
                                        Icon(Icons.error_outline, color: Colors.red, size: 32),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Error loading reports',
                                          style: GoogleFonts.manrope(
                                            fontSize: 13,
                                            color: Colors.red,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          reportProvider.errorMessage!,
                                          style: GoogleFonts.nunito(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        TextButton(
                                          onPressed: () => reportProvider.fetchReports(),
                                          child: const Text('Retry'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              if (limitedReports.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Text(
                                      'No reports available',
                                      style: GoogleFonts.nunito(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return Column(
                                children: limitedReports.map((operatorReport) {
                                  final report = operatorReport.report;
                                  final reporter = operatorReport.reporter;
                                  final driver = operatorReport.assignedDriver;

                                  // Format date
                                  String formattedDate = 'Unknown';
                                  if (report.createdAt != null) {
                                    final date = report.createdAt!;
                                    formattedDate = '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year.toString().substring(2)}';
                                  }

                                  // Build tags
                                  List<String> tags = [report.category.displayName];
                                  if (driver?.driverDetails?.vehiclePlate != null) {
                                    tags.add('Plate: ${driver!.driverDetails!.vehiclePlate}');
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _buildReportCard(
                                      title: report.category.displayName,
                                      plate: driver?.driverDetails?.vehiclePlate ?? 'N/A',
                                      status: report.status.displayName,
                                      statusColor: report.status.color,
                                      buttonText: _getReportButtonText(report.status.value),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ReportDetailsPage(
                                              name: reporter?.fullName ?? 'Unknown Reporter',
                                              role: reporter?.role.toUpperCase() ?? 'COMMUTER',
                                              id: report.id ?? '123456789',
                                              priority: report.severity.displayName,
                                              date: formattedDate,
                                              description: report.description,
                                              tags: tags,
                                              attachmentId: operatorReport.attachment?.id,
                                              initialAttachmentUrl: operatorReport.attachment?.url,
                                              driverName: driver?.fullName,
                                              vehiclePlate: driver?.driverDetails?.vehiclePlate,
                                              routeCode: driver?.driverDetails?.routeCode,
                                              status: report.status.displayName,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _getReportButtonText(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
      case 'closed':
      case 'dismissed':
        return 'Details';
      case 'in_review':
      case 'in progress':
        return 'Track';
      case 'open':
        return 'Review';
      default:
        return 'View';
    }
  }

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
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.bold,
              fontSize: 28,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(foregroundColor: color),
            child: Text(
              "View details",
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.normal,
                fontSize: 12,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {String? actionText, VoidCallback? onAction}) {
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
            onPressed: onAction ?? () {},
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
              textStyle: GoogleFonts.manrope(
                fontWeight: FontWeight.w600,
                fontSize: 12,
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
              const CircleAvatar(radius: 16, backgroundColor: Colors.grey),
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
                      fontSize: 11,
                      color: const Color.fromARGB(255, 123, 123, 123),
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
            width: 60,
            height: 28,
            borderRadius: 20,
            fontSize: 10,
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
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
                Expanded(
                  child: Text(
                    'Plate No. $plate • Status: $status',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: const Color.fromARGB(255, 123, 123, 123),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // Removed inline action button so the entire card is tappable.
              ],
            ),
          ],
        ),
      ),
    );
  }
}