import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'wallet_history.dart';
import 'otc.dart';

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
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showTokenInfoModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Wheel Token',
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 40,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/images/wheel token.png',
                            height: 80,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '1 Wheel Token = 1 Peso',
                            style: GoogleFonts.manrope(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Earn and use Wheel Tokens to make your rides more rewarding! Complete a ride to earn 0.5 Wheel Token.',
                      textAlign: TextAlign.justify,
                      style: GoogleFonts.nunito(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'The more you ride, the more tokens you collect — and the more you save! Start earning today and make every ride count!',
                      textAlign: TextAlign.justify,
                      style: GoogleFonts.nunito(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: -12,
                  right: -12,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleDepositNavigation(String optionText) {
    if (!mounted) return;

    if (optionText == 'Over-the-Counter') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const OverTheCounterPage()),
      );
    }
  }

  void _showDepositOptionsModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modal Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  color: gradientColors[1],
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: Text(
                          'Deposit to komyut',
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => Navigator.of(dialogContext).pop(),
                          child: const Icon(Icons.close, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                // Modal Body
                Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      _buildDepositOptionItem(
                        icon: Image.asset(
                          'assets/images/otc.png',
                          width: 26,
                          height: 26,
                          fit: BoxFit.contain,
                        ),
                        text: 'Over-the-Counter',
                        dialogContext: dialogContext,
                      ),
                      _buildDepositOptionItem(
                        icon: Image.asset(
                          'assets/images/dw.png',
                          width: 30,
                          height: 30,
                          fit: BoxFit.contain,
                        ),
                        text: 'Digital Wallet',
                        dialogContext: dialogContext,
                      ),
                      _buildDepositOptionItem(
                        icon: Image.asset(
                          'assets/images/wt.png',
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                        ),
                        text: 'Wheel Tokens',
                        isLast: true,
                        dialogContext: dialogContext,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDepositOptionItem({
    required Widget icon,
    required String text,
    required BuildContext dialogContext,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: () {
        Navigator.of(dialogContext).pop();
        _handleDepositNavigation(text);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          border: Border(
            bottom: isLast
                ? BorderSide.none
                : BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: Row(
          children: [
            SizedBox(width: 35, child: Center(child: icon)),
            const SizedBox(width: 16),
            Text(
              text,
              style: GoogleFonts.manrope(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: gradientColors[1],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FF),
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
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 100.0),
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
        if (_tabController.index == 0)
          _buildTransactionsList()
        else
          _buildTokensList(),
        const SizedBox(height: 20),
        _buildViewAllButton(),
      ],
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
            color: const Color(0xFF8E4CB6).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Balance',
                    style: GoogleFonts.nunito(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₱ 3 000.00',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _showTokenInfoModal(context),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    children: [
                      Image.asset('assets/images/wheel token.png', height: 22),
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
                ),
              ),
            ],
          ),
          Positioned(
            bottom: -40,
            right: 0,
            child: GestureDetector(
              onTap: () => _showDepositOptionsModal(context),
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
            color: Colors.grey.withValues(alpha: 0.1),
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
            height: chartHeight + 24,
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

  Widget _buildViewAllButton() {
    return OutlinedButton(
      onPressed: () {
        final type = _tabController.index == 0
            ? HistoryType.transactions
            : HistoryType.tokens;
        Navigator.of(context).pushNamed('/history', arguments: type);
      },
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
    return Column(
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
        _buildTransactionItem(
          'Cash In',
          '10/1/25 8:25 PM',
          '+₱150.00',
          true,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildTokensList() {
    return Column(
      children: [
        _buildTokenItem('Token Redemption', '10/3/25 8:25 PM', '-3.0', false),
        _buildTokenItem('Trip Reward', '10/3/25 3:18 PM', '+0.5', true),
        _buildTokenItem('Trip Reward', '10/3/25 1:02 PM', '+0.5', true),
        _buildTokenItem('Trip Reward', '10/2/25 11:02 AM', '+0.5', true),
        _buildTokenItem('Token Redemption', '10/2/25 6:02 AM', '-2.0', false),
        _buildTokenItem(
          'Trip Reward',
          '10/1/25 8:25 PM',
          '+0.5',
          true,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildTransactionItem(
    String title,
    String subtitle,
    String amount,
    bool isCredit, {
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isLast ? Colors.transparent : Colors.grey[200]!,
          ),
        ),
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

  Widget _buildTokenItem(
    String title,
    String subtitle,
    String amount,
    bool isCredit, {
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isLast ? Colors.transparent : Colors.grey[200]!,
          ),
        ),
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
              Image.asset('assets/images/wheel token.png', height: 20),
            ],
          ),
        ],
      ),
    );
  }
}
