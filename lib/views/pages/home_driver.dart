// lib/pages/driver_dashboard.dart - FINAL FIXED VERSION
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import '../widgets/button.dart';
import '../widgets/navbar.dart';
import '../services/qr_service.dart';
import 'qr_generate.dart'; 

class DriverDashboardNav extends StatefulWidget {
  const DriverDashboardNav({super.key});

  @override
  State<DriverDashboardNav> createState() => _DriverDashboardNavState();
}

class _DriverDashboardNavState extends State<DriverDashboardNav> {
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
  final GlobalKey _qrKey = GlobalKey();
  
  bool _isBalanceVisible = true;
  bool _isEarningsVisible = true;
  bool showTooltip = false;
  bool qrGenerated = false;
  bool isGenerating = false;
  bool _isDownloading = false;
  String? currentQRCode;
  Map<String, dynamic>? qrData;

  @override
  void initState() {
    super.initState();
    _loadCurrentQR();
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
    // Navigate to the wrapper that includes the navbar
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DriverQRGenerateNav(),
      ),
    ).then((_) {
      // Refresh QR code status after returning
      _loadCurrentQR();
    });
  }

  Future<void> _downloadQRFromDashboard() async {
    if (currentQRCode == null) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      // Navigate to QR page for download (it has the full QR display)
      _navigateToQRGeneration();
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
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
                        // LOGO
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  'Hi, Juan',
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                    color: const Color.fromARGB(255, 255, 255, 255),
                                  ),
                                ),
                                const Text(
                                  'Welcome back!',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Color.fromARGB(255, 255, 255, 255),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // EARNINGS + BALANCE
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: _buildHeaderCard(
                                title: "Today's Earnings",
                                amount: '500.00',
                                isBalanceVisible: _isEarningsVisible,
                                onToggleVisibility: () {
                                  setState(() {
                                    _isEarningsVisible = !_isEarningsVisible;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildHeaderCard(
                                title: "Current Balance",
                                amount: '500.00',
                                isBalanceVisible: _isBalanceVisible,
                                onToggleVisibility: () {
                                  setState(() {
                                    _isBalanceVisible = !_isBalanceVisible;
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
                            color: const Color.fromARGB(255, 255, 253, 253),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(24),
                            ),
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
                                      Future.delayed(
                                          const Duration(seconds: 3), () {
                                        if (mounted) {
                                          setState(() {
                                            showTooltip = false;
                                          });
                                        }
                                      });
                                    },
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        const Icon(
                                          Icons.info_outline_rounded,
                                          color: Color(0xFF8E4CB6),
                                          size: 24,
                                        ),
                                        if (showTooltip)
                                          Positioned(
                                            top: -60,
                                            right: -20,
                                            child: Container(
                                              width: 200,
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.black87,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'Show your QR to passengers for easy payment',
                                                style: GoogleFonts.nunito(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // QR Code Display or Placeholder
                              if (!qrGenerated)
                                // No QR Generated Yet - Show Placeholder
                                GestureDetector(
                                  onTap: _navigateToQRGeneration,
                                  child: DottedBorder(
                                    color: const Color(0xFF8E4CB6),
                                    strokeWidth: 2,
                                    dashPattern: const [8, 4],
                                    borderType: BorderType.RRect,
                                    radius: const Radius.circular(16),
                                    child: Container(
                                      width: double.infinity,
                                      height: 240,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.qr_code_2_rounded,
                                            size: 80,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Tap to generate\nyour QR code',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.nunito(
                                              color: Colors.grey[600],
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              else
                                // QR Code Generated - Show Preview
                                GestureDetector(
                                  onTap: _navigateToQRGeneration,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFF8E4CB6)
                                              .withValues(alpha: 0.1),
                                          const Color(0xFFB945AA)
                                              .withValues(alpha: 0.1),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFF8E4CB6)
                                            .withValues(alpha: 0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.qr_code_2_rounded,
                                            size: 120,
                                            color: const Color(0xFF8E4CB6),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.1),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.check_circle_rounded,
                                                color: Colors.green,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'QR Code Active',
                                                style: GoogleFonts.manrope(
                                                  color: Colors.green,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Tap to view full QR code',
                                          style: GoogleFonts.nunito(
                                            color: const Color(0xFF8E4CB6),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 16),

                              // Action Button
                              SizedBox(
                                width: double.infinity,
                                child: CustomButton(
                                  text: qrGenerated
                                      ? 'View QR Code'
                                      : 'Generate QR Code',
                                  onPressed: _navigateToQRGeneration,
                                  isFilled: true,
                                  textColor: Colors.white,
                                  width: double.infinity,
                                  height: 50,
                                  borderRadius: 30,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 15),

                        // ANALYTICS CARD
                        _buildAnalyticsCard(),

                        const SizedBox(height: 15),

                        // FEEDBACK CARD
                        _buildFeedbackCard(),

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
              Text(
                isBalanceVisible ? amount : '••••••',
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard() {
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
                    '4.2',
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
        ],
      ),
    );
  }

  Widget _buildFeedbackCard() {
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
                    '2',
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