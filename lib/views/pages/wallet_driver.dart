import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

// Dummy Data Models (for clarity)
class Transaction {
  final String type; // 'earning' or 'remittance'
  final double amount;
  final DateTime date;
  final String? description;

  Transaction({
    required this.type,
    required this.amount,
    required this.date,
    this.description,
  });
}

class DriverWalletPage extends StatefulWidget {
  const DriverWalletPage({super.key});

  @override
  State<DriverWalletPage> createState() => _DriverWalletPageState();
}

class _DriverWalletPageState extends State<DriverWalletPage> {
  int _selectedWeekOffset = 0; // 0 for current week, -1 for last week, etc.

  // --- DUMMY DATA ---
  final double _totalEarnings = 12540.50;
  final double _todayEarnings = 850.00;

  Map<String, double> _getDummyWeeklyData(int weekOffset) {
    final random = Random(weekOffset);
    return {
      'Mon': random.nextDouble() * 1200 + 200,
      'Tue': random.nextDouble() * 2500 + 300, // Added higher value for testing
      'Wed': random.nextDouble() * 1800 + 150,
      'Thu': random.nextDouble() * 2800 + 400, // Added higher value for testing
      'Fri': random.nextDouble() * 2200 + 250,
      'Sat': random.nextDouble() * 1500 + 300,
      'Sun': random.nextDouble() * 900,
    };
  }

  final List<Transaction> _dummyTransactions = [
    Transaction(
      type: 'earning',
      amount: 50.00,
      date: DateTime.now().subtract(const Duration(hours: 1)),
      description: 'Trip #AB123',
    ),
    Transaction(
      type: 'earning',
      amount: 75.50,
      date: DateTime.now().subtract(const Duration(hours: 2)),
      description: 'Trip #CD456',
    ),
    Transaction(
      type: 'remittance',
      amount: -500.00,
      date: DateTime.now().subtract(const Duration(hours: 5)),
      description: 'To Operator J. Doe',
    ),
    Transaction(
      type: 'earning',
      amount: 45.00,
      date: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      description: 'Trip #EF789',
    ),
  ];

  String _getMonthAndYear(int offset) {
    final now = DateTime.now();
    final dayInSelectedWeek = now.subtract(Duration(days: -offset * 7));
    // Change the format to "MMM yyyy" (e.g., "Nov 2025")
    return DateFormat('MMM yyyy').format(dayInSelectedWeek);
  }

  List<DateTime> _getWeekDates(int offset) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(
      Duration(days: now.weekday - 1 + (-offset * 7)),
    );
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  String _formatKiloValue(num value) {
    if (value >= 1000) {
      String formatted = (value / 1000).toStringAsFixed(1);
      if (formatted.endsWith('.0')) {
        formatted = formatted.substring(0, formatted.length - 2);
      }
      return '${formatted}k';
    }
    return value.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    final brandColor = const Color(0xFF8E4CB6);
    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

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
        // MODIFIED: Increased bottom padding to prevent being covered by a nav bar.
        padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 120.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBalanceCards(currencyFormat),
            const SizedBox(height: 24),
            _buildRemitButton(brandColor),
            const SizedBox(height: 32),
            _buildEarningsChartCard(brandColor),
            const SizedBox(height: 32),
            _buildHistorySection(currencyFormat),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCards(NumberFormat currencyFormat) {
    return Row(
      children: [
        Expanded(
          child: _buildBalanceItem(
            title: "Today's Earnings",
            amount: currencyFormat.format(_todayEarnings),
            color: const Color(0xFF388E3C), // A nice green
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildBalanceItem(
            title: 'Total Balance',
            amount: currencyFormat.format(_totalEarnings),
            color: const Color(0xFF5B53C2),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceItem({
    required String title,
    required String amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amount,
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemitButton(Color brandColor) {
    return ElevatedButton.icon(
      onPressed: () {
        // TODO: Implement remittance logic (e.g., show a dialog)
      },
      icon: const Icon(Symbols.upload_rounded, size: 20),
      label: Text(
        'Remit to Operator',
        style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: brandColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  // --- REBUILT CHART WIDGET ---
  // --- REBUILT CHART WIDGET ---
  // --- REBUILT CHART WIDGET ---
  Widget _buildEarningsChartCard(Color brandColor) {
    const double chartHeight = 130;
    // The max value is still needed to calculate the relative height of the bars
    const double fixedMaxValue = 3000.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16), // Adjusted padding
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
          // The header row for title and week navigation remains the same
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Weekly Earnings',
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
                    onPressed: () => setState(() => _selectedWeekOffset--),
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
                        ? () => setState(() => _selectedWeekOffset++)
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
          // MODIFIED: This now contains a Column to hold the chart and the new labels widget
          Column(
            children: [
              SizedBox(
                height: chartHeight, // This SizedBox now only holds the bars
                child: _buildBarChart(
                  chartHeight,
                  _getDummyWeeklyData(_selectedWeekOffset),
                  fixedMaxValue,
                ),
              ),
              const SizedBox(height: 8),
              _buildXAxisLabels(), // The new, separate widget for the X-axis
            ],
          ),
        ],
      ),
    );
  }

  // --- REBUILT BAR CHART WIDGET ---
  Widget _buildBarChart(
    double chartHeight,
    Map<String, double> weeklyData,
    double maxVal,
  ) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    // MODIFIED: Re-added the 20% headroom to prevent overflow
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
              value > 0 ? _formatKiloValue(value) : '',
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
    final brandColor = const Color(0xFF8E4CB6);
    return OutlinedButton(
      onPressed: () {
        // TODO: Navigate to the driver's full transaction history page.
        // For example: Navigator.pushNamed(context, '/driver_history');
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: brandColor,
        side: BorderSide(color: brandColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      ),
      child: Text(
        'View All',
        style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildHistorySection(NumberFormat currencyFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'History',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        if (_dummyTransactions.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No transactions yet.'),
            ),
          )
        else
          Column(
            children: [
              // MODIFIED: This loop now tracks the index
              ..._dummyTransactions.asMap().entries.map((entry) {
                final int index = entry.key;
                final Transaction tx = entry.value;
                return _buildTransactionItem(
                  tx,
                  currencyFormat,
                  // Pass a boolean to identify the last item
                  isLast: index == _dummyTransactions.length - 1,
                );
              }),
              const SizedBox(height: 20),
              _buildViewAllButton(),
            ],
          ),
      ],
    );
  }

  Widget _buildTransactionItem(
    Transaction tx,
    NumberFormat currencyFormat, {
    bool isLast = false, // New optional parameter
  }) {
    final bool isEarning = tx.type == 'earning';
    final Color amountColor = isEarning
        ? const Color(0xFF2E7D32)
        : const Color(0xFFC62828);
    final IconData iconData = isEarning
        ? Symbols.payments_rounded
        : Symbols.upload_rounded;
    final String title = isEarning ? 'Trip Earning' : 'Remittance';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        // MODIFIED: The border color is now conditional
        border: Border(
          bottom: BorderSide(
            color: isLast ? Colors.transparent : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(iconData, color: amountColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
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
                  tx.description ??
                      DateFormat('MMM d, hh:mm a').format(tx.date),
                  style: GoogleFonts.nunito(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            '${isEarning ? '+' : ''}${currencyFormat.format(tx.amount)}',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}
