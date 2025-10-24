import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  // 0 for Transactions, 1 for Tokens
  int _selectedTabIndex = 0;

  final gradientColors = const [
    Color(0xFFB945AA),
    Color(0xFF8E4CB6),
    Color(0xFF5B53C2),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildBalanceCard(),
                    const SizedBox(height: 20),
                    _buildFareExpensesCard(),
                    const SizedBox(height: 20),
                    _buildHistorySection(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.of(context).pop();
              }
            },
          ),
          Text(
            'Wallet',
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.25),
            Colors.white.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Balance',
                style: GoogleFonts.nunito(color: Colors.white70, fontSize: 16),
              ),
              Row(
                children: [
                  // CHANGED: Replaced the yellow circle with the token image
                  Image.asset(
                    'assets/images/wheel token.png',
                    height: 22,
                    width: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '10.5',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '₱ 3 000.00',
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add,
                  color: Color(0xFF5B53C2),
                  size: 32,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFareExpensesCard() {
    final Map<String, double> weeklyExpenses = {
      'Mon': 85.0,
      'Tue': 100.0,
      'Wed': 65.0,
      'Thu': 78.0,
      'Fri': 92.0,
      'Sat': 25.0,
      'Sun': 25.0,
    };
    const double maxExpense = 110.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fare Expenses',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: weeklyExpenses.entries.map((entry) {
                return _buildBar(entry.key, entry.value, maxExpense);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String day, double value, double maxValue) {
    final barHeight = (value / maxValue) * 90;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          height: barHeight,
          width: 25,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFB945AA),
                const Color(0xFF8E4CB6).withOpacity(0.8),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: GoogleFonts.nunito(
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildHistorySection() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildTabs(),
          _selectedTabIndex == 0
              ? _buildTransactionsList()
              : _buildTokensList(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 10,
                ),
              ),
              child: Text(
                'View All',
                style: GoogleFonts.manrope(
                  color: const Color(0xFF5B53C2),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, left: 20, right: 20),
      child: Row(
        children: [
          _buildTabItem('Transactions', 0),
          const SizedBox(width: 20),
          _buildTabItem('Tokens', 1),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isSelected ? const Color(0xFF5B53C2) : Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 3,
            width: isSelected ? 40 : 0,
            decoration: BoxDecoration(
              color: const Color(0xFF8E4CB6),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    return Column(
      children: [
        _buildTransactionItem("Cash In", "10/3/25 8:25 PM", "+₱100.00", true),
        _buildTransactionItem("Trip Fare", "10/3/25 3:18 PM", "-₱13.00", false),
        _buildTransactionItem("Trip Fare", "10/3/25 1:02 PM", "-₱13.00", false),
        _buildTransactionItem(
          "Trip Fare",
          "10/2/25 11:02 AM",
          "-₱13.00",
          false,
        ),
        _buildTransactionItem("Trip Fare", "10/2/25 6:02 AM", "-₱13.00", false),
        _buildTransactionItem("Cash In", "10/1/25 8:25 PM", "+₱150.00", true),
      ],
    );
  }

  Widget _buildTokensList() {
    return Column(
      children: [
        _buildTokenItem("Token Redemption", "10/3/25 8:25 PM", "-3.0", false),
        _buildTokenItem("Trip Reward", "10/3/25 3:18 PM", "+0.5", true),
        _buildTokenItem("Trip Reward", "10/3/25 1:02 PM", "+0.5", true),
        _buildTokenItem("Token Redemption", "10/2/25 11:02 AM", "-2.0", false),
        _buildTokenItem("Trip Reward", "10/2/25 6:02 AM", "+0.5", true),
        _buildTokenItem("Trip Reward", "10/1/25 8:25 PM", "+0.5", true),
      ],
    );
  }

  Widget _buildTransactionItem(
    String title,
    String date,
    String amount,
    bool isCredit,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    date,
                    style: GoogleFonts.nunito(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              Text(
                amount,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isCredit
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFF44336),
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFF1F0FA)),
        ],
      ),
    );
  }

  Widget _buildTokenItem(
    String title,
    String date,
    String amount,
    bool isCredit,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    date,
                    style: GoogleFonts.nunito(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    amount,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isCredit
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFF44336),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Image.asset(
                    'assets/images/wheel token.png',
                    height: 22,
                    width: 22,
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFF1F0FA)),
        ],
      ),
    );
  }
}
