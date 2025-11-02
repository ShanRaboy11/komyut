// lib/pages/driver_dashboard.dart - WITH PROVIDER WRAPPER FIX
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';
import '../widgets/button.dart';
import '../widgets/navbar.dart';
import '../services/qr_service.dart';
import '../providers/driver_dashboard.dart';
import 'qr_generate.dart';

// ✅ WRAP THE NAV WITH PROVIDER
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
  State<_DriverDashboardNavContent> createState() => _DriverDashboardNavContentState();
}

class _DriverDashboardNavContentState extends State<_DriverDashboardNavContent> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBottomNavBar(
      pages: const [
        DriverDashboard(),
        Center(child: Text("📋 Activity")),
        Center(child: Text("✍️ Feedback")),
        Center(child: Text("🔔 Notifications")),
        Center(child: Text("👤 Profile")),
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
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
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
    // ✅ Use addPostFrameCallback to load data AFTER build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    // Load dashboard data from database
    final dashboardProvider = Provider.of<DriverDashboardProvider>(
      context,
      listen: false,
    );
    await dashboardProvider.loadDashboardData();

    // Load QR code
    await _loadCurrentQR();
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

  void _navigateToQRGeneration() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DriverQRGenerateNav(),
      ),
    ).then((_) {
      _loadCurrentQR();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Consumer<DriverDashboardProvider>(
      builder: (context, dashboardProvider, child) {
        if (dashboardProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFB945AA),
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
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
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
                        // HEADER SECTION
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
                              // LOGO & GREETING
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  SvgPicture.asset(
                                    'assets/images/logo_white.svg',
                                    height: 80,
                                    width: 80,
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Hi, ${dashboardProvider.firstName.isEmpty ? 'Driver' : dashboardProvider.firstName}',
                                        style: GoogleFonts.manrope(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 24,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const Text(
                                        'Welcome back!',
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // EARNINGS + BALANCE (FROM DATABASE)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: _buildHeaderCard(
                                      title: "Today's Earnings",
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
                          padding: const EdgeInsets.only(left: 30.0, right: 30.0),
                          child: Column(
                            children: [
                              // MAIN QR DISPLAY AREA
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
                                    // Header with Info Icon
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
                                              color:
                                                  const Color(0xFFB945AA)
                                                      .withAlpha(26),
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

                                    // Info Tooltip
                                    if (showTooltip) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFB945AA)
                                              .withAlpha(26),
                                          borderRadius: BorderRadius.circular(12),
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
                                                  color:
                                                      const Color(0xFF5B53C2),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 20),

                                    // QR Code Display or Prompt
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
                                                  fontSize: 16,
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
                                          borderRadius: BorderRadius.circular(16),
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
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFB945AA)
                                                    .withAlpha(26),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                'Active QR Code',
                                                style: GoogleFonts.manrope(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(0xFFB945AA),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    const SizedBox(height: 20),

                                    // Generate/View QR Button
                                    CustomButton(
                                      text: qrGenerated
                                          ? 'View QR Code'
                                          : 'Generate QR Code',
                                      onPressed: _navigateToQRGeneration,
                                      isFilled: true,
                                      textColor: Colors.white,
                                      width: double.infinity,
                                      height: 50,
                                      borderRadius: 30,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // ANALYTICS CARD (FROM DATABASE)
                              _buildAnalyticsCard(dashboardProvider.rating),

                              const SizedBox(height: 20),

                              // FEEDBACK CARD (FROM DATABASE)
                              _buildFeedbackCard(dashboardProvider.reportsCount),

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: onToggleVisibility,
                icon: Icon(
                  isBalanceVisible
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                '₱ ',
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.normal,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  isBalanceVisible ? amount : '••••••',
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(double rating) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF8E4CB6), width: 0.7),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 3),
          ),
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
          Container(height: 60, color: Colors.grey[200]),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
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
                  'Ratings',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 10),
                Container(
                  alignment: Alignment.center,
                  child: Text(
                    rating > 0 ? rating.toStringAsFixed(1) : 'No ratings yet',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold,
                      fontSize: rating > 0 ? 30 : 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
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
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 3),
          ),
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
                    fontSize: 16,
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
            fontSize: 14,
          ),
        ],
      ),
    );
  }
}