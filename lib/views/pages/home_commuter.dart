import 'package:flutter/material.dart';
import '../widgets/button.dart';

class CommuterDashboard extends StatefulWidget {
  const CommuterDashboard({Key? key}) : super(key: key);

  @override
  State<CommuterDashboard> createState() => _CommuterDashboardState();
}

class _CommuterDashboardState extends State<CommuterDashboard>
    with SingleTickerProviderStateMixin {
  bool showWallet = true;

  final gradientColors = const [
    Color(0xFFB945AA),
    Color(0xFF8E4CB6),
    Color(0xFF5B53C2),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      bottomNavigationBar: _buildBottomNav(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('assets/images/logo.svg', height: 40),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      Text('Hi, Naomi',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Welcome back!',
                          style: TextStyle(color: Color(0xFF8E4CB6))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Wallet / Points Tabs
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => showWallet = true),
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
                              topLeft: Radius.circular(16),
                              bottomLeft: Radius.circular(0),
                              topRight: Radius.circular(0),
                              bottomRight: Radius.circular(0),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Wallet',
                              style: TextStyle(
                                color: showWallet
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => showWallet = false),
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
                              topRight: Radius.circular(16),
                              bottomRight: Radius.circular(0),
                              topLeft: Radius.circular(0),
                              bottomLeft: Radius.circular(0),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Points',
                              style: TextStyle(
                                color: !showWallet
                                    ? Colors.white
                                    : Colors.black87,
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

              // Wallet / Points Card
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                transitionBuilder: (child, animation) {
    final offsetAnimation = Tween<Offset>(
      begin: showWallet ? const Offset(-1.0, 0) : const Offset(1.0, 0),
      end: Offset.zero,
    ).animate(animation);
    return SlideTransition(position: offsetAnimation, child: child);
                },
                child: showWallet
                    ? _buildWalletCard(key: const ValueKey(1))
                    : _buildPointsCard(key: const ValueKey(2)),
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
        ),
      ),
    );
  }

  // 🟣 Wallet Card
  Widget _buildWalletCard({Key? key}) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Available Balance',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          const Text('₱500.00',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          CustomButton(
            text: 'Cash In',
            onPressed: () {},
            isFilled: true,
            fillColor: Colors.white,
            textColor: const Color(0xFF5B53C2),
            width: double.infinity,
            height: 45,
            borderRadius: 30,
            hasShadow: false,
          ),
        ],
      ),
    );
  }

  // 🟣 Points Card
  Widget _buildPointsCard({Key? key}) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors.reversed.toList()),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Available Points',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          const Text('59 pts',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          CustomButton(
            text: 'Redeem',
            onPressed: () {},
            isFilled: true,
            fillColor: Colors.white,
            textColor: const Color(0xFFB945AA),
            width: double.infinity,
            height: 45,
            borderRadius: 30,
            hasShadow: false,
          ),
        ],
      ),
    );
  }

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
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(value, style: const TextStyle(color: Colors.black87)),
            if (subtitle != null)
              Text(subtitle, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ],
    );
  }

  Widget _buildPromoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text('Get 50% off your next ride!\nUse Code: KOMYUTIE50',
                style: TextStyle(fontWeight: FontWeight.w500)),
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
          )
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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

  Widget _buildActionButton(String title, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
        leading: Icon(icon, color: Colors.white),
        onTap: () {},
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF8E4CB6),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
        BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none), label: 'Alerts'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
