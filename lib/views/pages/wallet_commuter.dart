import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import 'commuter_app.dart';
import 'wallet_history_commuter.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedWeekOffset = 0;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WalletProvider>(context, listen: false).fetchWalletData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _generateTransactionCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final part1 = String.fromCharCodes(
      Iterable.generate(
        15,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
    return 'K0MYUT-XHS$part1'.substring(0, 25);
  }

  String _getMonthAndYear(int offset) {
    final now = DateTime.now();
    final dayInSelectedWeek = now.subtract(Duration(days: -offset * 7));
    return DateFormat('MMM yyyy').format(dayInSelectedWeek);
  }

  List<DateTime> _getWeekDates(int offset) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(
      Duration(days: now.weekday - 1 + (-offset * 7)),
    );
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  void _showTransactionDetailModal(
    BuildContext context,
    Map<String, dynamic> transaction,
  ) {
    final String type = transaction['type'] as String? ?? 'transaction';
    final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: 'P');

    String modalTitle = type
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');

    if (type != 'token_redemption') {
      modalTitle += ' Transaction';
    }

    List<Widget> details = [];
    Widget totalRow;

    details.add(
      _buildDetailRow(
        'Date:',
        DateFormat(
          'MM/dd/yyyy',
        ).format(DateTime.parse(transaction['created_at'])),
      ),
    );
    details.add(
      _buildDetailRow(
        'Time:',
        DateFormat('hh:mm a').format(DateTime.parse(transaction['created_at'])),
      ),
    );

    if (type == 'token_redemption') {
      totalRow = _buildDetailRow(
        'Amount:',
        currencyFormat.format(amount),
        isTotal: true,
      );
    } else if (type == 'cash_in') {
      details.add(_buildDetailRow('Amount:', currencyFormat.format(amount)));

      final paymentMethod = transaction['payment_methods'];
      final channelDisplay =
          (paymentMethod != null && paymentMethod['name'] != null)
          ? paymentMethod['name']
          : 'N/A';
      details.add(_buildDetailRow('Channel:', channelDisplay));

      final status = (transaction['status'] as String?) ?? 'N/A';
      details.add(
        _buildDetailRow(
          'Status:',
          status[0].toUpperCase() + status.substring(1),
        ),
      );

      double total = amount;
      if (channelDisplay == 'Over-the-Counter') {
        total += 5.0;
      } else {
        total += 10.0;
      }
      totalRow = _buildDetailRow(
        'Total:',
        currencyFormat.format(total),
        isTotal: true,
      );
    } else {
      totalRow = _buildDetailRow(
        'Amount:',
        currencyFormat.format(amount),
        isTotal: true,
      );
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (dialogContext) {
        return _buildDetailModal(
          context: dialogContext,
          title: modalTitle,
          details: details,
          totalRow: totalRow,
          transactionCode:
              transaction['transaction_number'] ?? _generateTransactionCode(),
        );
      },
    );
  }

  void _showTokenActivityModal(
    BuildContext context,
    Map<String, dynamic> tokenData,
  ) {
    final amount = (tokenData['amount'] as num?)?.toDouble() ?? 0.0;
    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: 'P');

    final String type = (tokenData['type'] as String?) ?? 'reward';
    final String modalTitle = type == 'redemption'
        ? 'Token Redemption'
        : 'Token Reward';

    final String transactionCode =
        tokenData['transaction_number'] as String? ??
        _generateTransactionCode();

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (dialogContext) {
        return _buildDetailModal(
          context: dialogContext,
          title: modalTitle,
          details: [
            _buildDetailRow(
              'Date:',
              DateFormat(
                'MM/dd/yyyy',
              ).format(DateTime.parse(tokenData['created_at'])),
            ),
            _buildDetailRow(
              'Time:',
              DateFormat(
                'hh:mm a',
              ).format(DateTime.parse(tokenData['created_at'])),
            ),
            _buildDetailRow(
              'Amount:',
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/wheel token.png', height: 16),
                  const SizedBox(width: 6),
                  Text(
                    amount.abs().toStringAsFixed(1),
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          totalRow: _buildDetailRow(
            'Equivalent:',
            currencyFormat.format(amount.abs()),
          ),
          transactionCode: transactionCode,
        );
      },
    );
  }

  Widget _buildDetailModal({
    required BuildContext context,
    required String title,
    required List<Widget> details,
    required Widget totalRow,
    required String transactionCode,
  }) {
    final Color brandColor = const Color(0xFF8E4CB6);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 30),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: brandColor.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: brandColor.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Divider(color: brandColor.withValues(alpha: 0.5), height: 24),
                ...details,
                Divider(color: brandColor.withValues(alpha: 0.5), height: 24),
                totalRow,
                Divider(color: brandColor.withValues(alpha: 0.5), height: 24),
                BarcodeWidget(
                  barcode: Barcode.code128(),
                  data: transactionCode,
                  height: 40,
                  drawText: false,
                ),
                const SizedBox(height: 8),
                Text(
                  transactionCode,
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 12,
                    color: Colors.black54,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            Positioned(
              top: -12,
              right: -12,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, color: brandColor, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value, {bool isTotal = false}) {
    final isValueWidget = value is Widget;

    final bool shouldBeBold =
        isTotal || (label == 'Total:' || label == 'Equivalent:');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 15,
              color: shouldBeBold ? Colors.black87 : Colors.grey[600],
              fontWeight: shouldBeBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isValueWidget)
            value
          else
            Text(
              value.toString(),
              style: GoogleFonts.manrope(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: shouldBeBold ? FontWeight.bold : FontWeight.w600,
              ),
            ),
        ],
      ),
    );
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
      CommuterApp.navigatorKey.currentState?.pushNamed('/otc');
    } else if (optionText == 'Digital Wallet') {
      CommuterApp.navigatorKey.currentState?.pushNamed('/digital_wallet');
    } else if (optionText == 'Wheel Tokens') {
      CommuterApp.navigatorKey.currentState?.pushNamed('/redeem_tokens');
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
      body: Consumer<WalletProvider>(
        builder: (context, provider, child) {
          if (provider.isWalletLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.walletErrorMessage != null) {
            return Center(child: Text(provider.walletErrorMessage!));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 100.0),
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildBalanceCard(provider),
                const SizedBox(height: 30),
                _buildFareExpensesCard(provider.fareExpenses),
                const SizedBox(height: 24),
                _buildTransactionsTabs(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionsTabs(WalletProvider provider) {
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
          _buildTransactionsList(provider.recentTransactions)
        else
          _buildTokensList(provider.recentTokenHistory),
        const SizedBox(height: 20),
        if ((_tabController.index == 0 &&
                provider.recentTransactions.isNotEmpty) ||
            (_tabController.index == 1 &&
                provider.recentTokenHistory.isNotEmpty))
          _buildViewAllButton(),
      ],
    );
  }

  Widget _buildBalanceCard(WalletProvider provider) {
    final currencyFormat = NumberFormat("#,##0.00", "en_US");

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8E4CB6).withValues(alpha: 0.25),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current Balance',
                    style: GoogleFonts.nunito(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showTokenInfoModal(context),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/wheel token.png',
                          height: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          provider.wheelTokens.toString(),
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '₱${currencyFormat.format(provider.balance)}',
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: -18,
          right: 18,
          child: GestureDetector(
            onTap: () => _showDepositOptionsModal(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8E4CB6).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(Icons.add, color: const Color(0xFF8E4CB6), size: 24),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFareExpensesCard(Map<String, double> expenses) {
    final provider = Provider.of<WalletProvider>(context, listen: false);
    final brandColor = const Color(0xFF8E4CB6);
    const double chartHeight = 130;

    final double maxWeeklyExpense = expenses.values.isEmpty
        ? 0.0
        : expenses.values.reduce(max);
    final double dynamicMaxValue = maxWeeklyExpense > 0
        ? maxWeeklyExpense
        : 100.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Fare Expenses',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() => _selectedWeekOffset--);
                      provider.fetchFareExpensesForWeek(_selectedWeekOffset);
                    },
                    color: brandColor,
                    splashRadius: 20,
                  ),
                  Text(
                    _getMonthAndYear(_selectedWeekOffset),
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: brandColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _selectedWeekOffset < 0
                        ? () {
                            setState(() => _selectedWeekOffset++);
                            provider.fetchFareExpensesForWeek(
                              _selectedWeekOffset,
                            );
                          }
                        : null,
                    color: brandColor,
                    disabledColor: brandColor.withValues(alpha: 0.3),
                    splashRadius: 20,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Consumer<WalletProvider>(
            builder: (context, walletProvider, child) {
              if (walletProvider.isFareExpensesLoading) {
                return SizedBox(
                  height: chartHeight + 48,
                  child: const Center(child: CircularProgressIndicator()),
                );
              }
              return Column(
                children: [
                  SizedBox(
                    height: chartHeight,
                    child: _buildBarChart(
                      chartHeight,
                      walletProvider.fareExpenses,
                      dynamicMaxValue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildXAxisLabels(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(
    double chartHeight,
    Map<String, double> weeklyData,
    double maxVal,
  ) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final effectiveMaxVal = maxVal * 1.20;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(days.length, (index) {
        final day = days[index];
        final value = weeklyData[day] ?? 0.0;
        final barHeight = (value / effectiveMaxVal) * chartHeight;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              value > 0 ? value.toInt().toString() : '',
              style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 2),
            Container(
              height: barHeight,
              width: 18,
              decoration: BoxDecoration(
                color: const Color(0xFFFBC02D),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildXAxisLabels() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekDates = _getWeekDates(_selectedWeekOffset);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(days.length, (index) {
        return SizedBox(
          width: 28,
          child: Column(
            children: [
              Text(
                days[index],
                style: GoogleFonts.nunito(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              Text(
                DateFormat('dd').format(weekDates[index]),
                style: GoogleFonts.nunito(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildViewAllButton() {
    return OutlinedButton(
      onPressed: () {
        final type = _tabController.index == 0
            ? HistoryType.transactions
            : HistoryType.tokens;
        CommuterApp.navigatorKey.currentState?.pushNamed(
          '/history',
          arguments: type,
        );
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

  Widget _buildTransactionsList(List<Map<String, dynamic>> transactions) {
    if (transactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: Text('No recent transactions.')),
      );
    }
    return Column(
      children: transactions.asMap().entries.map((entry) {
        int idx = entry.key;
        Map<String, dynamic> transaction = entry.value;
        return _buildTransactionItem(
          transaction,
          isLast: idx == transactions.length - 1,
        );
      }).toList(),
    );
  }

  Widget _buildTokensList(List<Map<String, dynamic>> tokenHistory) {
    if (tokenHistory.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: Text('No recent token activity.')),
      );
    }
    return Column(
      children: tokenHistory.asMap().entries.map((entry) {
        int idx = entry.key;
        Map<String, dynamic> tokenData = entry.value;
        return _buildTokenItem(
          tokenData,
          isLast: idx == tokenHistory.length - 1,
        );
      }).toList(),
    );
  }

  Widget _buildTransactionItem(
    Map<String, dynamic> transaction, {
    bool isLast = false,
  }) {
    final bool isCredit = (transaction['amount'] as num) > 0;
    final String type = transaction['type'] as String;

    final String title = type
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');

    final String amount = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
    ).format(transaction['amount']);
    final String date = DateFormat(
      'MM/d/yy hh:mm a',
    ).format(DateTime.parse(transaction['created_at']));

    return InkWell(
      onTap: () => _showTransactionDetailModal(context, transaction),
      child: Container(
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
                  date,
                  style: GoogleFonts.nunito(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
            Text(
              (isCredit ? '+' : '') + amount,
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
      ),
    );
  }

  Widget _buildTokenItem(
    Map<String, dynamic> tokenData, {
    bool isLast = false,
  }) {
    final bool isCredit = (tokenData['amount'] as num) > 0;
    final String title = (tokenData['type'] as String) == 'redemption'
        ? 'Token Redemption'
        : 'Token Reward';
    final double amount = (tokenData['amount'] as num).toDouble();
    final String date = DateFormat(
      'MM/d/yy hh:mm a',
    ).format(DateTime.parse(tokenData['created_at']));

    return InkWell(
      onTap: () => _showTokenActivityModal(context, tokenData),
      child: Container(
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
                  date,
                  style: GoogleFonts.nunito(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  '${isCredit ? '+' : ''}${amount.toStringAsFixed(1)}',
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
      ),
    );
  }
}
