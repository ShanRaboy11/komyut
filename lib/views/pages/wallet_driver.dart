import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:provider/provider.dart';

import '../providers/wallet_provider.dart';
import 'wallet_history_driver.dart';

class DriverWalletPage extends StatelessWidget {
  const DriverWalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DriverWalletProvider()..fetchWalletData(),
      child: const _DriverWalletView(),
    );
  }
}

class _DriverWalletView extends StatefulWidget {
  const _DriverWalletView();

  @override
  State<_DriverWalletView> createState() => _DriverWalletViewState();
}

class _DriverWalletViewState extends State<_DriverWalletView> {
  int _selectedWeekOffset = 0;

  @override
  Widget build(BuildContext context) {
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
      body: Consumer<DriverWalletProvider>(
        builder: (context, provider, child) {
          if (provider.isPageLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null &&
              provider.recentTransactions.isEmpty) {
            return Center(child: Text(provider.errorMessage!));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 120.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBalanceCards(currencyFormat, provider),
                const SizedBox(height: 24),
                _buildRemitButton(),
                const SizedBox(height: 32),
                _buildEarningsChartCard(provider),
                const SizedBox(height: 32),
                _buildHistorySection(currencyFormat, provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCards(
    NumberFormat currencyFormat,
    DriverWalletProvider provider,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildBalanceItem(
            title: "Today's Earnings",
            amount: currencyFormat.format(provider.todayEarnings),
            color: const Color(0xFF388E3C),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildBalanceItem(
            title: 'Total Balance',
            amount: currencyFormat.format(provider.totalBalance),
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

  Widget _buildRemitButton() {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Symbols.upload_rounded, size: 20),
      label: Text(
        'Remit to Operator',
        style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF8E4CB6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildEarningsChartCard(DriverWalletProvider provider) {
    const double chartHeight = 130;
    final weeklyData = provider.weeklyEarnings;
    final brandColor = const Color(0xFF8E4CB6);

    final double maxWeeklyValue = weeklyData.values.isEmpty
        ? 0.0
        : weeklyData.values.reduce(max);
    final double dynamicMaxValue = maxWeeklyValue > 0 ? maxWeeklyValue : 1000.0;

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
            children: [
              Text(
                'Weekly Earnings',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() => _selectedWeekOffset--);
                      provider.fetchWeeklyEarnings(_selectedWeekOffset);
                    },
                    color: brandColor,
                    splashRadius: 20,
                  ),
                  Text(
                    DateFormat('MMM yyyy').format(
                      DateTime.now().subtract(
                        Duration(days: -_selectedWeekOffset * 7),
                      ),
                    ),
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
                            provider.fetchWeeklyEarnings(_selectedWeekOffset);
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
          provider.isChartLoading
              ? SizedBox(
                  height: chartHeight + 48,
                  child: const Center(child: CircularProgressIndicator()),
                )
              : Column(
                  children: [
                    SizedBox(
                      height: chartHeight,
                      child: _buildBarChart(
                        chartHeight,
                        weeklyData,
                        dynamicMaxValue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildXAxisLabels(),
                  ],
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

    String formatKiloValue(num value) {
      if (value >= 1000) {
        String formatted = (value / 1000).toStringAsFixed(1);
        if (formatted.endsWith('.0'))
          formatted = formatted.substring(0, formatted.length - 2);
        return '${formatted}k';
      }
      return value.toInt().toString();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(days.length, (index) {
        final day = days[index];
        final value = weeklyData[day] ?? 0.0;
        final barHeight = effectiveMaxVal == 0
            ? 0.0
            : (value / effectiveMaxVal) * chartHeight;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              value > 0 ? formatKiloValue(value) : '',
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
    final now = DateTime.now();
    final startOfWeek = now.subtract(
      Duration(days: now.weekday - 1 + (-_selectedWeekOffset * 7)),
    );
    final weekDates = List.generate(
      7,
      (index) => startOfWeek.add(Duration(days: index)),
    );

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

  Widget _buildHistorySection(
    NumberFormat currencyFormat,
    DriverWalletProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'History',
          style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (provider.recentTransactions.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No recent transactions.'),
            ),
          )
        else
          Column(
            children: [
              ...provider.recentTransactions.asMap().entries.map((entry) {
                return _buildTransactionItem(
                  entry.value,
                  currencyFormat,
                  isLast: entry.key == provider.recentTransactions.length - 1,
                );
              }),
              const SizedBox(height: 20),
              _buildViewAllButton(),
            ],
          ),
      ],
    );
  }

  Widget _buildViewAllButton() {
    return OutlinedButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const WalletHistoryDriverPage(),
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF8E4CB6),
        side: const BorderSide(color: Color(0xFF8E4CB6)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      ),
      child: Text(
        'View All',
        style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTransactionItem(
    Map<String, dynamic> tx,
    NumberFormat currencyFormat, {
    bool isLast = false,
  }) {
    final String type = tx['type'] ?? 'fare_payment';
    final double amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
    final bool isEarning = type == 'fare_payment';
    final Color amountColor = isEarning
        ? const Color(0xFF2E7D32)
        : const Color(0xFFC62828);
    final String title = isEarning ? 'Trip Earning' : 'Remittance';
    final String date = DateFormat(
      'MM/d/yy hh:mm a',
    ).format(DateTime.parse(tx['created_at']));

    return InkWell(
      onTap: () => _showTransactionDetailModal(context, tx),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
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
              '${amount >= 0 ? '+' : ''}${currencyFormat.format(amount)}',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetailModal(
    BuildContext context,
    Map<String, dynamic> transaction,
  ) {
    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    final String type = transaction['type'] ?? 'fare_payment';
    final double amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
    final bool isEarning = type == 'fare_payment';
    final String modalTitle = isEarning ? 'Trip Earning' : 'Remittance';

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
              ).format(DateTime.parse(transaction['created_at'])),
            ),
            _buildDetailRow(
              'Time:',
              DateFormat(
                'hh:mm a',
              ).format(DateTime.parse(transaction['created_at'])),
            ),
          ],
          totalRow: _buildDetailRow(
            'Amount:',
            currencyFormat.format(amount.abs()),
            isTotal: true,
          ),
          transactionCode: transaction['transaction_number'] ?? 'N/A',
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 15,
              color: isTotal ? Colors.black87 : Colors.grey[600],
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value.toString(),
            style: GoogleFonts.manrope(
              fontSize: 15,
              color: Colors.black87,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
