import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

// --- Main Wallet Page Widget ---

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final gradientColors = const [
    Color(0xFFB945AA),
    Color(0xFF8E4CB6),
    Color(0xFF5B53C2),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allows body to go behind the floating navbar
      backgroundColor: const Color(0xFFF6F1FF), // Light purple background
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Wallet',
          style: GoogleFonts.manrope(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 120.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildBalanceCard(),
            const SizedBox(height: 30),
            _buildFareExpensesCard(),
            const SizedBox(height: 24),
            _buildTransactionsTabs(),
          ],
        ),
      ),
      bottomNavigationBar: const CustomFloatingNavBar(),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8E4CB6).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Balance',
                style: GoogleFonts.nunito(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₱ 3 000.00',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/wheel token.png',
                        height: 22,
                      ), // TOKEN IMAGE
                      const SizedBox(width: 6),
                      Text(
                        '10.5',
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: -40,
            right: 0,
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x338E4CB6),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.add, color: gradientColors[1], size: 30),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFareExpensesCard() {
    const double chartHeight = 110;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fare Expenses',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: chartHeight + 24, // chart height + x-axis label space
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: ['100', '75', '50', '25', '0']
                      .map(
                        (e) => Text(
                          e,
                          style: GoogleFonts.nunito(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(width: 10),
                Expanded(child: _buildBarChart(chartHeight)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(double chartHeight) {
    final Map<String, double> weeklyData = {
      'Mon': 78,
      'Tue': 88,
      'Wed': 60,
      'Thu': 75,
      'Fri': 85,
      'Sat': 25,
      'Sun': 25,
    };
    const double maxVal = 100.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: weeklyData.entries.map((entry) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              height: (entry.value / maxVal) * chartHeight,
              width: 20,
              decoration: BoxDecoration(
                color: const Color(0xFFFBC02D),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              entry.key,
              style: GoogleFonts.nunito(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTransactionsTabs() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: gradientColors[1],
          unselectedLabelColor: Colors.grey,
          indicatorColor: gradientColors[1],
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          unselectedLabelStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          tabs: const [
            Tab(text: 'Transactions'),
            Tab(text: 'Tokens'),
          ],
        ),
        SizedBox(
          // Calculated height prevents scrolling conflicts
          height: (68.0 * 6) + 16,
          child: TabBarView(
            controller: _tabController,
            children: [_buildTransactionsList(), _buildTokensList()],
          ),
        ),
        const SizedBox(height: 10),
        _buildViewAllButton(),
      ],
    );
  }

  Widget _buildViewAllButton() {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        foregroundColor: gradientColors[1],
        side: BorderSide(color: gradientColors[1]),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      ),
      child: Text(
        'View All',
        style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTransactionsList() {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 16),
      children: [
        _buildTransactionItem('Cash In', '10/3/25 8:25 PM', '+₱100.00', true),
        _buildTransactionItem('Trip Fare', '10/3/25 3:18 PM', '−₱13.00', false),
        _buildTransactionItem('Trip Fare', '10/3/25 1:02 PM', '−₱13.00', false),
        _buildTransactionItem(
          'Trip Fare',
          '10/2/25 11:02 AM',
          '−₱13.00',
          false,
        ),
        _buildTransactionItem('Trip Fare', '10/2/25 6:02 AM', '−₱13.00', false),
        _buildTransactionItem('Cash In', '10/1/25 8:25 PM', '+₱150.00', true),
      ],
    );
  }

  Widget _buildTransactionItem(
    String title,
    String subtitle,
    String amount,
    bool isCredit,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.nunito(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
          Text(
            amount,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isCredit
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFC62828),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokensList() {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 16),
      children: [
        _buildTokenItem('Token Redemption', '10/3/25 8:25 PM', '-3.0', false),
        _buildTokenItem('Trip Reward', '10/3/25 3:18 PM', '+0.5', true),
        _buildTokenItem('Trip Reward', '10/3/25 1:02 PM', '+0.5', true),
        _buildTokenItem('Trip Reward', '10/2/25 11:02 AM', '+0.5', true),
        _buildTokenItem('Token Redemption', '10/2/25 6:02 AM', '-2.0', false),
        _buildTokenItem('Trip Reward', '10/1/25 8:25 PM', '+0.5', true),
      ],
    );
  }

  Widget _buildTokenItem(
    String title,
    String subtitle,
    String amount,
    bool isCredit,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.nunito(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                amount,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isCredit
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFC62828),
                ),
              ),
              const SizedBox(width: 6),
              Image.asset(
                'assets/images/wheel token.png',
                height: 20,
              ), // TOKEN IMAGE
            ],
          ),
        ],
      ),
    );
  }
}

// --- Custom Floating Navigation Bar Widget ---
// This is an exact recreation of the navbar in your screenshots.

class CustomFloatingNavBar extends StatelessWidget {
  const CustomFloatingNavBar({super.key});

  final gradientColors = const [
    Color(0xFFB945AA),
    Color(0xFF8E4CB6),
    Color(0xFF5B53C2),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 65,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradientColors.reversed.toList()),
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8E4CB6).withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(Symbols.receipt_long, 'Activity', context),
              _buildNavItem(
                Symbols.qr_code_scanner_rounded,
                'QR Scan',
                context,
              ),
              const SizedBox(width: 70), // Space for the home button
              _buildNavItem(Symbols.info, 'Info', context),
              _buildNavItem(Icons.person_outline_rounded, 'Profile', context),
            ],
          ),
        ),
        Positioned(
          bottom: 25,
          child: GestureDetector(
            onTap: () {
              // This takes the user back to the very first screen (dashboard)
              if (Navigator.canPop(context)) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: gradientColors),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[1].withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.home_rounded, color: Colors.white, size: 34),
                  Text(
                    'Home',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, String label, BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Tapping other nav items on this page will just pop back to the dashboard.
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
      },
      behavior: HitTestBehavior.translucent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.9), size: 26),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.manrope(
              color: Colors.white.withOpacity(0.9),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
