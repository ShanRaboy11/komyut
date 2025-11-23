import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/admin_verification.dart';
import '../providers/admin_dashboard.dart';
import '../providers/auth_provider.dart';
import '../services/admin_dashboard.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/navbar.dart';
import 'admin_app.dart';
import 'dart:math' as math;

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

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  final List<Color> gradientColors = const [
    Color(0xFF5B53C2),
    Color(0xFFB945AA),
  ];

  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    // Load all dashboard data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dashProvider = context.read<AdminDashboardProvider>();
      dashProvider.loadDashboardData();
      // Ensure analytics default period is weekly on dashboard open
      dashProvider.changePeriod(AnalyticsPeriod.weekly);
      context.read<AdminVerificationProvider>().loadVerifications();
    });
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Logout',
              style: GoogleFonts.manrope(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF2D3436),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to logout?',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: const Color(0xFF636E72),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF636E72),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF5350),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;

    // Capture navigator and providers before async gaps
    final rootNav = Navigator.of(context, rootNavigator: true);
    final authProvider = context.read<AuthProvider>();
    final adminVerificationProvider = context.read<AdminVerificationProvider>();
    final messenger = ScaffoldMessenger.of(context);

    // Show blocking progress dialog on root navigator
    showDialog<void>(
      context: rootNav.context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const CircularProgressIndicator(),
        ),
      ),
    );

    var signOutSuccess = false;
    try {
      await authProvider.signOut();
      signOutSuccess = true;
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Logout failed: $e',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      try {
        rootNav.pop();
      } catch (_) {}
    }

    if (signOutSuccess && mounted) {
      try {
        adminVerificationProvider.clearCurrentDetail();
      } catch (_) {}

      rootNav.pushNamedAndRemoveUntil('/landing', (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      body: RefreshIndicator(
        onRefresh: () async {
          final dash = context.read<AdminDashboardProvider>();
          final verif = context.read<AdminVerificationProvider>();
          await dash.refresh();
          await verif.loadVerifications();
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Enhanced Header with Logo and Logout ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo
                    SvgPicture.asset('assets/images/logo.svg', height: 60),
                    // Logout Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _handleLogout,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Color(
                                0xFFEF5350,
                              ).withAlpha((0.2 * 255).round()),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(
                                  0xFFEF5350,
                                ).withAlpha((0.1 * 255).round()),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.logout,
                                size: 20,
                                color: Color(0xFFEF5350),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Logout',
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFEF5350),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- Stats Cards ---
                Consumer<AdminDashboardProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoadingStats) {
                      return _buildStatsLoadingSkeleton();
                    }

                    final stats = provider.overallStats;
                    if (stats == null) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Symbols.group,
                                title: 'Total Users',
                                value: stats.totalUsers.toString(),
                                color: const Color(0xFF5B53C2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Symbols.route,
                                title: 'Total Trips',
                                value: stats.totalTrips.toString(),
                                color: const Color(0xFFB945AA),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Symbols.payments,
                                title: 'Total Revenue',
                                value:
                                    '₱${stats.totalRevenue.toStringAsFixed(0)}',
                                color: const Color(0xFF4CAF50),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Symbols.pending_actions,
                                title: 'Pending Verifs',
                                value: stats.pendingVerifications.toString(),
                                color: const Color(0xFFFFA726),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // --- Analytics Section ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Fare Analytics',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    // Period Filter Buttons
                    Consumer<AdminDashboardProvider>(
                      builder: (context, provider, child) {
                        return Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.purple.shade100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _PeriodButton(
                                label: 'Week',
                                isSelected:
                                    provider.currentPeriod ==
                                    AnalyticsPeriod.weekly,
                                onTap: () => provider.changePeriod(
                                  AnalyticsPeriod.weekly,
                                ),
                              ),
                              _PeriodButton(
                                label: 'Month',
                                isSelected:
                                    provider.currentPeriod ==
                                    AnalyticsPeriod.monthly,
                                onTap: () => provider.changePeriod(
                                  AnalyticsPeriod.monthly,
                                ),
                              ),
                              _PeriodButton(
                                label: 'Year',
                                isSelected:
                                    provider.currentPeriod ==
                                    AnalyticsPeriod.yearly,
                                onTap: () => provider.changePeriod(
                                  AnalyticsPeriod.yearly,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Consumer<AdminDashboardProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoadingFareData) {
                      return _buildChartLoadingSkeleton();
                    }

                    if (provider.fareDataError != null) {
                      return _buildErrorCard(provider.fareDataError!);
                    }

                    final fareData = provider.fareData;
                    if (fareData.isEmpty) {
                      return _buildEmptyCard('No fare data available');
                    }

                    // Calculate max value for chart scaling
                    final maxAmount = fareData
                        .map((d) => d.amount)
                        .reduce(math.max);
                    final chartMaxY = (maxAmount > 0
                        ? (maxAmount * 1.2).ceilToDouble()
                        : 100.0);

                    // Get period label
                    String periodLabel;
                    switch (provider.currentPeriod) {
                      case AnalyticsPeriod.weekly:
                        periodLabel = 'Last 7 Days';
                        break;
                      case AnalyticsPeriod.monthly:
                        periodLabel = 'Last 4 Weeks';
                        break;
                      case AnalyticsPeriod.yearly:
                        periodLabel = 'Last 12 Months';
                        break;
                    }

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.purple.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withAlpha(
                              (0.05 * 255).round(),
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Period label
                          Text(
                            periodLabel,
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: isSmall ? 200 : 240,
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  getDrawingHorizontalLine: (value) {
                                    return FlLine(
                                      color: Colors.grey.shade200,
                                      strokeWidth: 1,
                                    );
                                  },
                                ),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                      interval: chartMaxY / 4,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          '₱${value.toInt()}',
                                          style: GoogleFonts.nunito(
                                            fontSize: 10,
                                            color: Colors.grey.shade600,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 1,
                                      getTitlesWidget: (value, _) {
                                        final index = value.toInt();
                                        if (index >= 0 &&
                                            index < fareData.length) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8,
                                            ),
                                            child: Text(
                                              fareData[index].dayName,
                                              style: GoogleFonts.nunito(
                                                fontSize:
                                                    provider.currentPeriod ==
                                                        AnalyticsPeriod.yearly
                                                    ? 9
                                                    : 11,
                                                color: Colors.grey.shade700,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                    left: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                                minX: 0,
                                maxX: (fareData.length - 1).toDouble(),
                                minY: 0,
                                maxY: chartMaxY,
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: fareData
                                        .asMap()
                                        .entries
                                        .map(
                                          (e) => FlSpot(
                                            e.key.toDouble(),
                                            e.value.amount,
                                          ),
                                        )
                                        .toList(),
                                    isCurved: true,
                                    gradient: LinearGradient(
                                      colors: gradientColors,
                                    ),
                                    barWidth: 3,
                                    isStrokeCapRound: true,
                                    dotData: FlDotData(
                                      show: true,
                                      getDotPainter:
                                          (spot, percent, barData, index) {
                                            return FlDotCirclePainter(
                                              radius: 4,
                                              color: Colors.white,
                                              strokeWidth: 2,
                                              strokeColor: gradientColors[0],
                                            );
                                          },
                                    ),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      gradient: LinearGradient(
                                        colors: gradientColors
                                            .map(
                                              (c) => c.withAlpha(
                                                (0.15 * 255).round(),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ),
                                  ),
                                ],
                                lineTouchData: LineTouchData(
                                  touchTooltipData: LineTouchTooltipData(
                                    getTooltipItems: (touchedSpots) {
                                      return touchedSpots.map((spot) {
                                        return LineTooltipItem(
                                          '₱${spot.y.toStringAsFixed(2)}',
                                          GoogleFonts.nunito(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        );
                                      }).toList();
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // --- User Type Breakdown ---
                Text(
                  'User Type Breakdown',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                Consumer<AdminDashboardProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoadingBreakdown) {
                      return _buildDonutLoadingSkeleton();
                    }

                    if (provider.breakdownError != null) {
                      return _buildErrorCard(provider.breakdownError!);
                    }

                    final breakdown = provider.userTypeBreakdown;
                    if (breakdown == null || breakdown.total == 0) {
                      return _buildEmptyCard('No user data available');
                    }

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.purple.shade100),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withAlpha(
                              (0.05 * 255).round(),
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Donut Chart
                          SizedBox(
                            height: 180,
                            width: 180,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                PieChart(
                                  PieChartData(
                                    sectionsSpace: 3,
                                    centerSpaceRadius: 60,
                                    startDegreeOffset: -90,
                                    sections: [
                                      PieChartSectionData(
                                        color: const Color(0xFFB945AA),
                                        value: breakdown.commuters.toDouble(),
                                        radius: 30,
                                        title: '',
                                        showTitle: false,
                                      ),
                                      PieChartSectionData(
                                        color: const Color(0xFF5B53C2),
                                        value: breakdown.drivers.toDouble(),
                                        radius: 30,
                                        title: '',
                                        showTitle: false,
                                      ),
                                      PieChartSectionData(
                                        color: const Color(0xFF4FC3F7),
                                        value: breakdown.operators.toDouble(),
                                        radius: 30,
                                        title: '',
                                        showTitle: false,
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      breakdown.total.toString(),
                                      style: GoogleFonts.manrope(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 36,
                                        color: const Color(0xFF5B53C2),
                                      ),
                                    ),
                                    Text(
                                      'Total Users',
                                      style: GoogleFonts.nunito(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Legend with counts
                          _LegendItem(
                            color: const Color(0xFFB945AA),
                            label: 'Commuters',
                            count: breakdown.commuters,
                            total: breakdown.total,
                          ),
                          const SizedBox(height: 10),
                          _LegendItem(
                            color: const Color(0xFF5B53C2),
                            label: 'Drivers',
                            count: breakdown.drivers,
                            total: breakdown.total,
                          ),
                          const SizedBox(height: 10),
                          _LegendItem(
                            color: const Color(0xFF4FC3F7),
                            label: 'Operators',
                            count: breakdown.operators,
                            total: breakdown.total,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // --- Recent Verifications ---
                _buildSectionHeader(context, "Recent Verifications", "See all"),
                const SizedBox(height: 12),
                Consumer<AdminVerificationProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return _buildVerificationsLoadingSkeleton();
                    }

                    final items = List<VerificationListItem>.from(
                      provider.verifications,
                    )..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                    if (items.isEmpty) {
                      return _buildEmptyCard('No verifications yet');
                    }

                    return Column(
                      children: items.take(3).map((it) {
                        return _VerificationCard(item: it);
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    String actionText,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminApp(initialIndex: 1),
              ),
            );
          },
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.all(const Color(0xFF5B53C2)),
            overlayColor: WidgetStateProperty.all(Colors.transparent),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                actionText,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios, size: 14),
            ],
          ),
        ),
      ],
    );
  }

  // Loading skeletons
  Widget _buildStatsLoadingSkeleton() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildSkeletonCard(height: 90)),
            const SizedBox(width: 12),
            Expanded(child: _buildSkeletonCard(height: 90)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildSkeletonCard(height: 90)),
            const SizedBox(width: 12),
            Expanded(child: _buildSkeletonCard(height: 90)),
          ],
        ),
      ],
    );
  }

  // Shimmer helper copied from other pages for consistent skeletons
  Widget _buildShimmer({required Widget child}) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, shimmerChild) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.grey[300]!, Colors.grey[100]!, Colors.grey[300]!],
              stops: [
                _shimmerController.value - 0.3,
                _shimmerController.value,
                _shimmerController.value + 0.3,
              ],
            ).createShader(bounds);
          },
          child: shimmerChild,
        );
      },
      child: child,
    );
  }

  Widget _buildChartLoadingSkeleton() {
    return _buildSkeletonCard(height: 240);
  }

  Widget _buildDonutLoadingSkeleton() {
    return _buildSkeletonCard(height: 320);
  }

  Widget _buildVerificationsLoadingSkeleton() {
    return Column(
      children: List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildSkeletonCard(height: 80),
        ),
      ),
    );
  }

  Widget _buildSkeletonCard({required double height}) {
    final card = Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.purple.shade50),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 16, width: 120, color: Colors.white),
            const SizedBox(height: 12),
            Expanded(
              child: Container(color: Colors.white, width: double.infinity),
            ),
          ],
        ),
      ),
    );

    return _buildShimmer(child: card);
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.nunito(
                color: Colors.red.shade900,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.purple.shade50),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.nunito(color: Colors.grey.shade600),
        ),
      ),
    );
  }
}

// Widgets
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha((0.2 * 255).round())),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha((0.1 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final int total;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0
        ? (count / total * 100).toStringAsFixed(1)
        : '0.0';

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          '$count',
          style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Text(
          '($percentage%)',
          style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _VerificationCard extends StatelessWidget {
  final VerificationListItem item;

  const _VerificationCard({required this.item});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF2ECC71);
      case 'pending':
        return const Color(0xFFFFC107);
      case 'rejected':
        return const Color(0xFFE74C3C);
      case 'lacking':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getInitials() {
    final parts = item.userName
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'U';
    } else if (parts.length == 1) {
      final name = parts[0];
      return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
    } else {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.purple.shade50),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.03 * 255).round()),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFF2EAFF),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _getInitials(),
              style: GoogleFonts.manrope(
                color: const Color(0xFF9C6BFF),
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.userName,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.roleCapitalized} • ${item.timeAgo}',
                  style: GoogleFonts.nunito(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(item.status),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              item.statusCapitalized,
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF5B53C2), Color(0xFFB945AA)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
