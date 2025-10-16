import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import '../widgets/button.dart';
import '../widgets/navbar.dart';

class CommuterDashboardNav extends StatefulWidget {
  const CommuterDashboardNav({super.key});

  @override
  State<CommuterDashboardNav> createState() => _CommuterDashboardNavState();
}

class _CommuterDashboardNavState extends State<CommuterDashboardNav> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBottomNavBar(
      pages: const [
        CommuterDashboardPage(), // Home Page
        Center(child: Text("📋 Activity")),
        Center(child: Text("✍️ QR Scan")),
        Center(child: Text("🔔 Notifications")),
        Center(child: Text("👤 Profile")),
      ],
      items: const [
        NavItem(icon: Icons.home_rounded, label: 'Home'),
        NavItem(icon: Symbols.overview_rounded, label: 'Activity'),
        NavItem(icon: Symbols.qr_code_scanner_rounded, label: 'QR Scan'),
        NavItem(icon: Icons.notifications_rounded, label: 'Notification'),
        NavItem(icon: Icons.person_rounded, label: 'Profile'),
      ],
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
       padding: EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SvgPicture.asset(
                'assets/images/logo.svg',
                height: 80,
                width: 80,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text('Hi, Naomi',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Welcome back!',
                      style: TextStyle(color: Color(0xFF8E4CB6))),
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
                  topLeft: Radius.circular(10), topRight: Radius.circular(10)),
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
                          style: TextStyle(
                            color: showWallet ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
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
                          style: TextStyle(
                            color: !showWallet ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
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
                  final offsetAnimation =
                      Tween<Offset>(begin: incomingOffset, end: Offset.zero)
                          .animate(animation);
                  return SlideTransition(
                      position: offsetAnimation, child: child);
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
                  const Text('Available Balance',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
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
                  const Text(
                    '₱ ',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isBalanceVisible ? '500.00' : '••••••',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              )
            ],
          ),
          CustomButton(
            text: 'Cash In',
            icon: Icons.add_rounded,
            onPressed: () {},
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
                  const Text('Available Points',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
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
                  Image.asset(
                    'assets/images/wheel token.png',
                    height: 40,
                    width: 40,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isPointsVisible ? '59 pts' : '••••••',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              )
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
          const Text('Commute Analytics',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 4),
          const Text('This week', style: TextStyle(color: Color(0xFF8E4CB6))),
        const Divider(),
        // Analytics items row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAnalyticsItem(Icons.directions_bus, 'Trips', '12 trips',
                  subtitle: '12.6 mi'),
              _buildAnalyticsItem(Icons.account_balance_wallet_outlined,
                  'Spend', '₱300 total'),
            ],
          ),
        ),
      ],
    ),
  );
}


  Widget _buildAnalyticsItem(IconData icon, String title, String value,
      {String? subtitle}) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF8E4CB6)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(value, style: const TextStyle(color: Colors.black87)),
            if (subtitle != null)
              Text(subtitle, style: const TextStyle(color: Colors.black54)),
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
            child: Text('Get 50% off your next ride!\nUse Code: KOMYUTIE50',
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
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
          )
        ],
      ),
    );
  }

  // ---------------- Quick Actions ----------------
  Widget _buildQuickActions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.fromLTRB(0, 0, 0, 30),
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

  Widget _buildActionButton(String title, IconData icon, {double iconSize = 20}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 12),
        leading: Icon(icon, color: Colors.white, size: iconSize),
        onTap: () {},
      ),
    );
  }
}
