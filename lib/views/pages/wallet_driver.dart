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
    final random = Random(weekOffset); // Seed random for consistent "old" data
    return {
      'Mon': random.nextDouble() * 800 + 100,
      'Tue': random.nextDouble() * 900 + 150,
      'Wed': random.nextDouble() * 750 + 50,
      'Thu': random.nextDouble() * 1000 + 200,
      'Fri': random.nextDouble() * 1200 + 250,
      'Sat': random.nextDouble() * 1500 + 300,
      'Sun': random.nextDouble() * 600,
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
    Transaction(
      type: 'earning',
      amount: 120.00,
      date: DateTime.now().subtract(const Duration(days: 1, hours: 6)),
      description: 'Trip #GH012',
    ),
    Transaction(
      type: 'remittance',
      amount: -1000.00,
      date: DateTime.now().subtract(const Duration(days: 2, hours: 2)),
      description: 'To Operator J. Doe',
    ),
    Transaction(
      type: 'earning',
      amount: 60.00,
      date: DateTime.now().subtract(const Duration(days: 2, hours: 8)),
      description: 'Trip #IJ345',
    ),
  ];

  // Helper to get date range string
  String _getWeekDateRange(int offset) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(
      Duration(days: now.weekday - 1 + (-offset * 7)),
    );
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final format = DateFormat('MMM d');
    return '${format.format(startOfWeek)} - ${format.format(endOfWeek)}';
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
        automaticallyImplyLeading: false, // No back button needed on a tab page
        title: Text(
          'Wallet & Activity',
          style: GoogleFonts.manrope(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 40.0),
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

  Widget _buildEarningsChartCard(Color brandColor) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Earnings',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: brandColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() {
                          _selectedWeekOffset--;
                        });
                      },
                      color: brandColor,
                      iconSize: 20,
                      splashRadius: 20,
                    ),
                    Text(
                      _getWeekDateRange(_selectedWeekOffset),
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: brandColor,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _selectedWeekOffset < 0
                          ? () {
                              setState(() {
                                _selectedWeekOffset++;
                              });
                            }
                          : null, // Disable for future weeks
                      color: brandColor,
                      disabledColor: brandColor.withValues(alpha: 0.3),
                      iconSize: 20,
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 120,
            child: _buildBarChart(_getDummyWeeklyData(_selectedWeekOffset)),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(Map<String, double> weeklyData) {
    final double maxVal = weeklyData.values.fold(
      0.0,
      (prev, e) => e > prev ? e : prev,
    );
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: days.map((day) {
        final value = weeklyData[day] ?? 0.0;
        final barHeight = (value / (maxVal == 0 ? 1 : maxVal)) * 100;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              height: barHeight,
              width: 18,
              decoration: BoxDecoration(
                color: const Color(0xFFFBC02D),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              day,
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
        _dummyTransactions.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No transactions yet.'),
                ),
              )
            : Column(
                children: _dummyTransactions.map((tx) {
                  return _buildTransactionItem(tx, currencyFormat);
                }).toList(),
              ),
      ],
    );
  }

  Widget _buildTransactionItem(Transaction tx, NumberFormat currencyFormat) {
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
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
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
