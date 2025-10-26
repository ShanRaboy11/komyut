// lib/pages/commuter_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:komyut/views/pages/qr_scan.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import '../widgets/button.dart';
import '../widgets/navbar.dart';
import 'profile.dart';
import 'notification_commuter.dart';
import 'activity_commuter.dart';

class CommuterDashboardNav extends StatefulWidget {
  const CommuterDashboardNav({super.key});

  @override
  State<CommuterDashboardNav> createState() => _CommuterDashboardNavState();
}

class _CommuterDashboardNavState extends State<CommuterDashboardNav> {
  int _currentIndex = 0;
  final GlobalKey<NotificationPageState> notificationKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return AnimatedBottomNavBar(
      pages: [
        const CommuterDashboardPage(),
        const TripsPage(),
        const Center(child: Text("✍️ QR Scan")),
        NotificationPage(key: notificationKey),
        const CommuterProfilePage(),
      ],
      items: const [
        NavItem(icon: Icons.home_rounded, label: 'Home'),
        NavItem(icon: Symbols.overview_rounded, label: 'Activity'),
        NavItem(icon: Symbols.qr_code_scanner_rounded, label: 'QR Scan'),
        NavItem(icon: Icons.notifications_rounded, label: 'Notification'),
        NavItem(icon: Icons.person_rounded, label: 'Profile'),
      ],
      initialIndex: _currentIndex,
      onItemSelected: (index) {
        if (index == 2) {
          // Navigate to QR Scanner as a full-screen route
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QRScannerScreen(
                onScanComplete: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Boarding successful!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          );
        } else {
          // Update tab for other selections
          setState(() {
            _currentIndex = index;
          });
        }
      },
    );
  }
}

class QRScanLoadingScreen extends StatefulWidget {
  const QRScanLoadingScreen({super.key});

  @override
  State<QRScanLoadingScreen> createState() => _QRScanLoadingScreenState();
}

class _QRScanLoadingScreenState extends State<QRScanLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 0.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white, // Example background color
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Logo
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: Stack(
                        children: [
                          // Gradient Border Circle (Bottom Layer)
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFFB945AA),
                                  Color(0xFF8E4CB6),
                                  Color(0xFF5B53C2),
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha((255 * 0.3).round()),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                          ),
                          // White Fill Circle (Top Layer)
                          Center(
                            child: Container(
                              width: 110, // Slightly smaller than the border circle
                              height: 110,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Image.asset( // Changed from SvgPicture.asset to Image.asset
  'assets/images/logo.png',
  fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),

            // Loading Text
            Text(
              'Opening QR Scanner...',
              style: GoogleFonts.manrope(
                color: Color(0xFFB945AA), // Changed to white for visibility on black background
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Loading Indicator
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8E4CB6)),
                strokeWidth: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============== DASHBOARD PAGE ===============
class CommuterDashboardPage extends StatefulWidget {
  const CommuterDashboardPage({super.key});

  @override
  State<CommuterDashboardPage> createState() => _CommuterDashboardPageState();
}

class _CommuterDashboardPageState extends State<CommuterDashboardPage> {
  bool showWallet = true;
  bool _previousShowWallet = true;

  bool _isBalanceVisible = true;
  bool _isPointsVisible = true;

  final gradientColors = const [
    Color(0xFFB945AA),
    Color(0xFF8E4CB6),
    Color(0xFF5B53C2),
  ];

  void _switchTab(bool goWallet) {
    setState(() {
      _previousShowWallet = showWallet;
      showWallet = goWallet;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(30, 10, 30, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SvgPicture.asset('assets/images/logo.svg', height: 80, width: 80),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Hi, Naomi',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    'Welcome back!',
                    style: GoogleFonts.manrope(
                      color: Color(0xFF8E4CB6),
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 5),

          // Wallet / Points Tabs
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _switchTab(true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        gradient: showWallet
                            ? LinearGradient(colors: gradientColors)
                            : null,
                        color: showWallet ? null : Colors.transparent,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          bottomLeft: Radius.circular(0),
                          topRight: Radius.circular(10),
                          bottomRight: Radius.circular(0),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Wallet',
                          style: GoogleFonts.manrope(
                            color: showWallet ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _switchTab(false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        gradient: !showWallet
                            ? LinearGradient(colors: gradientColors)
                            : null,
                        color: !showWallet ? null : Colors.transparent,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(10),
                          bottomRight: Radius.circular(0),
                          topLeft: Radius.circular(10),
                          bottomLeft: Radius.circular(0),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Points',
                          style: GoogleFonts.manrope(
                            color: !showWallet ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Wallet / Points Card Container
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, animation) {
              final offsetAnimation = Tween<Offset>(
                begin: Offset(_previousShowWallet ? 1 : -1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              ));

              return SlideTransition(
                position: offsetAnimation,
                child: child,
              );
            },
            child: Container(
              key: ValueKey<bool>(showWallet),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: showWallet
                  ? _buildWalletCard(isSmallScreen)
                  : _buildPointsCard(isSmallScreen),
            ),
          ),

          const SizedBox(height: 20),
          _buildAnalyticsSection(isSmallScreen),
          const SizedBox(height: 20),
          _buildPromoCard(),
          const SizedBox(height: 20),
          _buildQuickActions(),
        ],
      ),
    );
  }

  // ---------------- Wallet Card ----------------
  Widget _buildWalletCard(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Balance',
          style: GoogleFonts.manrope(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  _isBalanceVisible ? '₱500.00' : '₱•••.••',
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isBalanceVisible = !_isBalanceVisible;
                    });
                  },
                  child: Icon(
                    _isBalanceVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
            CustomButton(
              text: 'Top Up',
              onPressed: () {},
              isFilled: true,
              fillColor: Colors.white,
              textColor: const Color(0xFFB945AA),
              width: 100,
              height: 40,
              borderRadius: 30,
              hasShadow: false,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
      ],
    );
  }

  // ---------------- Points Card ----------------
  Widget _buildPointsCard(bool isSmallScreen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Points',
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SvgPicture.asset(
                  'assets/images/coin.svg',
                  height: 30,
                  width: 30,
                ),
                const SizedBox(width: 8),
                Text(
                  _isPointsVisible ? '1,234' : '•,•••',
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isPointsVisible = !_isPointsVisible;
                    });
                  },
                  child: Icon(
                    _isPointsVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
        CustomButton(
          text: 'Redeem',
          onPressed: () {},
          isFilled: true,
          fillColor: Colors.white,
          textColor: const Color(0xFFB945AA),
          width: 120,
          height: 45,
          borderRadius: 30,
          hasShadow: false,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          imagePath: 'assets/images/redeem.svg',
        ),
      ],
    );
  }

  // ---------------- Analytics Section ----------------
  Widget _buildAnalyticsSection(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF8E4CB6), width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Title + button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Commute Analytics',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'This week',
                    style: GoogleFonts.nunito(
                      color: Color(0xFF8E4CB6),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {},
                icon: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8E4CB6), Color(0xFF5B53C2)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(),
          // Analytics items row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAnalyticsItem(
                  Icons.directions_bus,
                  'Trips',
                  '12 trips',
                  subtitle: '12.6 mi',
                ),
                _buildAnalyticsItem(
                  Icons.account_balance_wallet_outlined,
                  'Spend',
                  '₱300 total',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsItem(
    IconData icon,
    String title,
    String value, {
    String? subtitle,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF8E4CB6)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(value, style: GoogleFonts.nunito(color: Colors.black87)),
            if (subtitle != null)
              Text(subtitle, style: GoogleFonts.nunito(color: Colors.black54)),
          ],
        ),
      ],
    );
  }

  // ---------------- Promo ----------------
  Widget _buildPromoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            Symbols.featured_seasonal_and_gifts_rounded,
            color: const Color(0xFFB3A11B),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              'Get 50% off your next ride!\nUse Code: KOMYUTIE50',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          CustomButton(
            text: 'Claim Now',
            onPressed: () {},
            isFilled: true,
            fillColor: const Color(0xFF8E4CB6),
            textColor: Colors.white,
            width: 120,
            height: 40,
            borderRadius: 20,
            hasShadow: false,
            fontSize: 14,
          ),
        ],
      ),
    );
  }

  // ---------------- Quick Actions ----------------
  Widget _buildQuickActions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.fromLTRB(0, 0, 0, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildActionButton('Find Route', Icons.route),
          const SizedBox(height: 10),
          _buildActionButton('Report an issue', Icons.report_problem_outlined),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon, {
    double iconSize = 20,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(
          title,
          style: GoogleFonts.manrope(color: Colors.white, fontSize: 18),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white,
          size: 12,
        ),
        leading: Icon(icon, color: Colors.white, size: iconSize),
        onTap: () {},
      ),
    );
  }
}