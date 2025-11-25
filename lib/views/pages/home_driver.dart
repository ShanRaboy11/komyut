import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/trips.dart';
import '../models/trips.dart';
import '../services/admin_dashboard.dart' show AnalyticsPeriod;

import '../widgets/button.dart';
import '../widgets/navbar.dart';
import '../services/qr_service.dart';
import '../providers/driver_dashboard.dart';

import 'qr_generate.dart';
import 'activity_driver.dart';

class DriverDashboardNav extends StatelessWidget {
  const DriverDashboardNav({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DriverDashboardProvider(),
      child: const _DriverDashboardNavContent(),
    );
  }
}

class _DriverDashboardNavContent extends StatefulWidget {
  const _DriverDashboardNavContent();

  @override
  State<_DriverDashboardNavContent> createState() =>
      _DriverDashboardNavContentState();
}

class _DriverDashboardNavContentState
    extends State<_DriverDashboardNavContent> {
  bool _isQROpen = false;

  void _openQR() {
    setState(() {
      _isQROpen = true;
    });
  }

  void _closeQR() {
    setState(() {
      _isQROpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBottomNavBar(
      pages: [
        _isQROpen
            ? DriverQRGeneratePage(onBack: _closeQR)
            : DriverDashboard(onViewQR: _openQR),

        const DriverActivityPage(),
        const Center(child: Text("📋 Activity")),
        const Center(child: Text("✍️ Feedback")),
        const Center(child: Text("🔔 Notifications")),
        const Center(child: Text("👤 Profile")),
      ],
      items: const [
        NavItem(icon: Icons.home_rounded, label: 'Home'),
        NavItem(icon: Symbols.overview_rounded, label: 'Activity'),
        NavItem(icon: Symbols.rate_review_rounded, label: 'Feedback'),
        NavItem(icon: Icons.notifications_rounded, label: 'Notification'),
        NavItem(icon: Icons.person_rounded, label: 'Profile'),
      ],
    );
  }
}

class DriverDashboard extends StatefulWidget {
  final VoidCallback? onViewQR;

  const DriverDashboard({super.key, this.onViewQR});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard>
  with SingleTickerProviderStateMixin {
  final QRService _qrService = QRService();

  bool _isBalanceVisible = true;
  bool _isEarningsVisible = true;
  bool showTooltip = false;
  bool qrGenerated = false;
  bool isGenerating = false;
  String? currentQRCode;
  Map<String, dynamic>? qrData;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  AnimationController? _shimmerController;

  Future<void> _loadData() async {
    final dashboardProvider = Provider.of<DriverDashboardProvider>(
      context,
      listen: false,
    );
    await dashboardProvider.loadDashboardData();
    await _loadCurrentQR();
    // Load analytics chart data
    await _loadAnalytics();
  }

  // Analytics state
  AnalyticsPeriod _currentPeriod = AnalyticsPeriod.weekly;
  List<ChartDataPoint> _chartData = [];
  bool _isAnalyticsLoading = false;
  String? _analyticsError;

  Future<void> _loadAnalytics() async {
    setState(() {
      _isAnalyticsLoading = true;
      _analyticsError = null;
    });

    try {
      final tripsService = TripsService();
      final timeRange = _currentPeriod == AnalyticsPeriod.weekly
          ? 'weekly'
          : (_currentPeriod == AnalyticsPeriod.monthly ? 'monthly' : 'yearly');

      final points = await tripsService.getChartData(
        timeRange: timeRange,
        rangeOffset: 0,
      );

      setState(() {
        _chartData = points;
      });
    } catch (e) {
      setState(() {
        _analyticsError = e.toString();
      });
    } finally {
      setState(() {
        _isAnalyticsLoading = false;
      });
    }
  }

  Future<void> _loadCurrentQR() async {
    final result = await _qrService.getCurrentQRCode();
    if (result['success'] && result['hasQR']) {
      setState(() {
        qrGenerated = true;
        currentQRCode = result['qrCode'];
        qrData = result['data'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Consumer<DriverDashboardProvider>(
      builder: (context, dashboardProvider, child) {
        if (dashboardProvider.isLoading) {
          // Show enhanced shimmer skeletons while provider is loading
          return Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header gradient skeleton with two stat cards
                    _buildShimmer(child: _buildHeaderSkeleton()),
                    const SizedBox(height: 16),

                    // QR Card skeleton
                    _buildShimmer(child: _buildQrSkeleton()),
                    const SizedBox(height: 16),

                    // Analytics skeleton (period buttons + chart)
                    _buildShimmer(child: _buildAnalyticsSkeleton()),
                    const SizedBox(height: 16),

                    // Feedback / Reports skeleton
                    _buildShimmer(child: _buildFeedbackSkeleton()),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        }

        if (dashboardProvider.errorMessage != null) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
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
                    Text(
                      dashboardProvider.errorMessage!,
                      style: GoogleFonts.nunito(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => dashboardProvider.loadDashboardData(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB945AA),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                await dashboardProvider.loadDashboardData();
                await _loadCurrentQR();
              },
              color: const Color(0xFFB945AA),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 500 : double.infinity,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(30),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFB945AA),
                                Color(0xFF8E4CB6),
                                Color(0xFF5B53C2),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(40),
                              bottomRight: Radius.circular(40),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  SvgPicture.asset(
                                    'assets/images/logo_white.svg',
                                    height: 60,
                                    width: 60,
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Welcome back,',
                                        style: GoogleFonts.nunito(
                                          fontSize: 16,
                                          color: Colors.white.withAlpha(230),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${dashboardProvider.firstName.isEmpty ? 'Driver' : dashboardProvider.firstName}!',
                                        style: GoogleFonts.manrope(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                          color: Colors.white,
                                          height: 1.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: _buildHeaderCard(
                                      title: "Today's Income",
                                      amount: dashboardProvider.todayEarnings
                                          .toStringAsFixed(2),
                                      isBalanceVisible: _isEarningsVisible,
                                      onToggleVisibility: () {
                                        setState(() {
                                          _isEarningsVisible =
                                              !_isEarningsVisible;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildHeaderCard(
                                      title: "Current Balance",
                                      amount: dashboardProvider.balance
                                          .toStringAsFixed(2),
                                      isBalanceVisible: _isBalanceVisible,
                                      onToggleVisibility: () {
                                        setState(() {
                                          _isBalanceVisible =
                                              !_isBalanceVisible;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 30.0,
                            right: 30.0,
                          ),
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(64),
                                      offset: const Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'QR Code',
                                          style: GoogleFonts.manrope(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              showTooltip = !showTooltip;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFFB945AA,
                                              ).withAlpha(26),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.info_outline,
                                              color: Color(0xFFB945AA),
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    if (showTooltip) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFFB945AA,
                                          ).withAlpha(26),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.info,
                                              color: Color(0xFFB945AA),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Generate your QR code for passengers to scan and pay fares.',
                                                style: GoogleFonts.nunito(
                                                  fontSize: 12,
                                                  color: const Color(
                                                    0xFF5B53C2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 20),

                                    if (!qrGenerated)
                                      DottedBorder(
                                        color: const Color(0xFFB945AA),
                                        strokeWidth: 2,
                                        dashPattern: const [8, 4],
                                        borderType: BorderType.RRect,
                                        radius: const Radius.circular(16),
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 50,
                                            horizontal: 20,
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.qr_code_2_rounded,
                                                size: 80,
                                                color: Colors.grey[400],
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'No QR Code Generated',
                                                style: GoogleFonts.manrope(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                            ],
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFB945AA),
                                            width: 2,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                Icons.qr_code_2_rounded,
                                                size: 150,
                                                color: Color(0xFF5B53C2),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFFB945AA,
                                                ).withAlpha(26),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                'Active QR Code',
                                                style: GoogleFonts.manrope(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(
                                                    0xFFB945AA,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    const SizedBox(height: 20),

                                    CustomButton(
                                      text: qrGenerated
                                          ? 'View QR Code'
                                          : 'Generate QR Code',
                                      onPressed: () {
                                        if (widget.onViewQR != null) {
                                          widget.onViewQR!();
                                        }
                                      },
                                      isFilled: true,
                                      textColor: Colors.white,
                                      width: double.infinity,
                                      height: 45,
                                      borderRadius: 30,
                                      fontSize: 14,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // ANALYTICS CARD (backend-driven)
                              _buildAnalyticsCard(dashboardProvider.rating),
                              const SizedBox(height: 20),
                              _buildFeedbackCard(
                                dashboardProvider.reportsCount,
                              ),

                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard({
    required String title,
    required String amount,
    required bool isBalanceVisible,
    required VoidCallback onToggleVisibility,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Text(
                        '₱',
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isBalanceVisible ? amount : '•••••',
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onToggleVisibility,
                borderRadius: BorderRadius.circular(12),
                child: Icon(
                  isBalanceVisible
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: Colors.white.withAlpha(200),
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(double rating) {
    // Build analytics card that includes a line chart driven by backend data
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF8E4CB6), width: 0.7),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analytics',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),

          // Period selector
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _periodButton(
                label: 'Week',
                isSelected: _currentPeriod == AnalyticsPeriod.weekly,
                onTap: () async {
                  setState(() => _currentPeriod = AnalyticsPeriod.weekly);
                  await _loadAnalytics();
                },
              ),
              const SizedBox(width: 8),
              _periodButton(
                label: 'Month',
                isSelected: _currentPeriod == AnalyticsPeriod.monthly,
                onTap: () async {
                  setState(() => _currentPeriod = AnalyticsPeriod.monthly);
                  await _loadAnalytics();
                },
              ),
              const SizedBox(width: 8),
              _periodButton(
                label: 'Year',
                isSelected: _currentPeriod == AnalyticsPeriod.yearly,
                onTap: () async {
                  setState(() => _currentPeriod = AnalyticsPeriod.yearly);
                  await _loadAnalytics();
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (_isAnalyticsLoading)
            Container(height: 200, alignment: Alignment.center, child: const CircularProgressIndicator())
          else if (_analyticsError != null)
            Container(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Error loading analytics: $_analyticsError',
                style: GoogleFonts.nunito(color: Colors.red),
              ),
            )
          else if (_chartData.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              child: Text(
                'No analytics data available',
                style: GoogleFonts.nunito(color: Colors.grey.shade700),
              ),
            )
          else
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: (_chartData.map((e) => e.count).reduce((a, b) => a > b ? a : b).toDouble() / 4).clamp(1, double.infinity),
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: GoogleFonts.nunito(fontSize: 10, color: Colors.grey.shade600),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, _) {
                          final index = value.toInt();
                          if (index >= 0 && index < _chartData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _chartData[index].label,
                                style: GoogleFonts.nunito(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
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
                      bottom: BorderSide(color: Colors.grey.shade300),
                      left: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  minX: 0,
                  maxX: (_chartData.length - 1).toDouble(),
                  minY: 0,
                  maxY: (_chartData.map((e) => e.count).reduce((a, b) => a > b ? a : b).toDouble() * 1.2).clamp(5.0, double.infinity),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _chartData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.count.toDouble())).toList(),
                      isCurved: true,
                      gradient: LinearGradient(colors: [const Color(0xFFB945AA), const Color(0xFF5B53C2)]),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(colors: [const Color(0xFFB945AA).withAlpha(40), const Color(0xFF5B53C2).withAlpha(40)]),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            spot.y.toStringAsFixed(0),
                            GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
  }

  // Small reusable period button used by analytics
  Widget _periodButton({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5B53C2) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.purple.shade100),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            color: isSelected ? Colors.white : Colors.grey.shade800,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _shimmerController?.dispose();
    _shimmerController = null;
    super.dispose();
  }

  // Shimmer helper (copied from admin pages for consistent skeletons)
  Widget _buildShimmer({required Widget child}) {
    // Lazily create controller if missing (handles hot-reload or unexpected states)
    final controller = _shimmerController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    return AnimatedBuilder(
      animation: controller,
      builder: (context, shimmerChild) {
        final v = controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.grey[300]!, Colors.grey[100]!, Colors.grey[300]!],
              stops: [v - 0.3, v, v + 0.3],
            ).createShader(bounds);
          },
          child: shimmerChild,
        );
      },
      child: child,
    );
  }

  // Skeleton helper is provided by admin pages; driver uses detailed skeleton builders below.

  // Detailed header skeleton (gradient header with two stat placeholders)
  Widget _buildHeaderSkeleton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB945AA), Color(0xFF8E4CB6), Color(0xFF5B53C2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 18, width: 180, color: Colors.white),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Container(height: 72, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
              const SizedBox(width: 12),
              Expanded(child: Container(height: 72, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
            ],
          ),
        ],
      ),
    );
  }

  // QR card skeleton (box with placeholder icon area and button)
  Widget _buildQrSkeleton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 18, width: 120, color: Colors.grey.shade200),
          const SizedBox(height: 12),
          Container(height: 120, width: double.infinity, color: Colors.grey.shade200),
          const SizedBox(height: 12),
          Align(alignment: Alignment.center, child: Container(height: 40, width: 200, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(24)))),
        ],
      ),
    );
  }

  // Analytics skeleton (period buttons + chart area)
  Widget _buildAnalyticsSkeleton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade50),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(height: 28, width: 60, color: Colors.grey.shade200),
              const SizedBox(width: 8),
              Container(height: 28, width: 60, color: Colors.grey.shade200),
              const SizedBox(width: 8),
              Container(height: 28, width: 60, color: Colors.grey.shade200),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 160, width: double.infinity, color: Colors.grey.shade200),
        ],
      ),
    );
  }

  // Feedback / reports skeleton
  Widget _buildFeedbackSkeleton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade50),
      ),
      child: Row(
        children: [
          Container(height: 60, width: 60, color: Colors.grey.shade200),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(height: 16, width: 120, color: Colors.grey.shade200), const SizedBox(height: 8), Container(height: 14, width: 80, color: Colors.grey.shade200)])),
          const SizedBox(width: 12),
          Container(height: 36, width: 110, color: Colors.grey.shade200),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(int reportsCount) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF8E4CB6), width: 0.7),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Feedback',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 3),
                ),
              ],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reports',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 10),
                Container(
                  alignment: Alignment.center,
                  child: Text(
                    '$reportsCount',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          CustomButton(
            text: 'View Reports',
            onPressed: () {},
            isFilled: true,
            textColor: Colors.white,
            width: double.infinity,
            height: 45,
            borderRadius: 30,
            fontSize: 12,
          ),
        ],
      ),
    );
  }
}
