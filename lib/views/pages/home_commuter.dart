import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import '../widgets/button.dart';
import '../widgets/navbar.dart';
import 'profile.dart';
import 'notification_commuter.dart';
import 'wallet.dart';

class CommuterDashboardNav extends StatefulWidget {
  const CommuterDashboardNav({super.key});

  @override
  State<CommuterDashboardNav> createState() => _CommuterDashboardNavState();
}

class _CommuterDashboardNavState extends State<CommuterDashboardNav> {
  final GlobalKey<NotificationPageState> notificationKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return AnimatedBottomNavBar(
      pages: [
        const CommuterDashboardPage(),
        const Center(child: Text("📋 Activity")),
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
      onNavigationChanged: (index) {
        if (index == 3) {
          notificationKey.currentState?.resetToDefault();
        }
      },
    );
  }
}

// ------------------- Dashboard Page -------------------

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
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: showWallet ? gradientColors : gradientColors,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: const Radius.circular(20),
                bottomRight: const Radius.circular(20),
                topRight: showWallet ? const Radius.circular(10) : Radius.zero,
                topLeft: showWallet ? Radius.zero : const Radius.circular(10),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                bottomLeft: const Radius.circular(20),
                bottomRight: const Radius.circular(20),
                topRight: showWallet ? const Radius.circular(10) : Radius.zero,
                topLeft: showWallet ? Radius.zero : const Radius.circular(10),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                transitionBuilder: (child, animation) {
                  final bool isWalletToPoints =
                      _previousShowWallet && !showWallet;
                  final incomingOffset = isWalletToPoints
                      ? const Offset(-1.0, 0)
                      : const Offset(-1.0, 0);
                  final offsetAnimation = Tween<Offset>(
                    begin: incomingOffset,
                    end: Offset.zero,
                  ).animate(animation);
                  return SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  );
                },
                child: showWallet
                    ? _buildWalletContent(key: const ValueKey(1))
                    : _buildPointsContent(key: const ValueKey(2)),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Analytics
          _buildAnalyticsSection(isSmallScreen),
          const SizedBox(height: 20),

          // Promo
          _buildPromoCard(),
          const SizedBox(height: 20),

          // Quick Actions
          _buildQuickActions(),
        ],
      ),
    );
  }

  // ---------------- Wallet Content ----------------
  Widget _buildWalletContent({Key? key}) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Available Balance',
                    style: GoogleFonts.nunito(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      _isBalanceVisible
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: Colors.white70,
                      size: 18,
                    ),
                    onPressed: () {
                      setState(() {
                        _isBalanceVisible = !_isBalanceVisible;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Text(
                    '₱ ',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isBalanceVisible ? '500.00' : '••••••',
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
          CustomButton(
            text: 'Cash In',
            icon: Icons.add_rounded,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const WalletPage()),
              );
            },
            isFilled: true,
            fillColor: Colors.white,
            textColor: const Color(0xFF5B53C2),
            width: 120,
            height: 45,
            borderRadius: 30,
            hasShadow: false,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ],
      ),
    );
  }

  // ---------------- Points Content ----------------
  Widget _buildPointsContent({Key? key}) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Available Points',
                    style: GoogleFonts.nunito(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      _isPointsVisible
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: Colors.white70,
                      size: 18,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPointsVisible = !_isPointsVisible;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/images/wheel token.svg',
                    height: 40,
                    width: 40,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isPointsVisible ? '59 pts' : '••••••',
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
          CustomButton(
            text: 'Redeem',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const WalletPage()),
              );
            },
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
      ),
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
                  width: 30, // adjust size as needed
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
