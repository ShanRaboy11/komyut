import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:provider/provider.dart';
import '../widgets/button.dart';
import '../providers/wallet_provider.dart';

class OperatorWalletPage extends StatefulWidget {
  final VoidCallback? onBack;

  const OperatorWalletPage({super.key, this.onBack});

  @override
  State<OperatorWalletPage> createState() => _OperatorWalletPageState();
}

class _OperatorWalletPageState extends State<OperatorWalletPage> {
  int _selectedWeekOffset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<OperatorWalletProvider>();
      if (provider.recentTransactions.isEmpty && !provider.isLoading) {
        provider.loadWalletDashboard();
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: Colors.black54),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          'My Wallet',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<OperatorWalletProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.recentTransactions.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF5B53C2)),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadWalletDashboard(),
            color: const Color(0xFF5B53C2),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    _buildBalanceCard(provider.currentBalance),
                    const SizedBox(height: 24),

                    CustomButton(
                      text: 'Cash Out',
                      onPressed: () {
                        Navigator.of(context).pushNamed('/cash_out');
                      },
                      isFilled: true,
                      fillColor: const Color(0xFF5B53C2),
                      textColor: Colors.white,
                      height: 50,
                      fontSize: 16,
                      hasShadow: true,
                    ),
                    const SizedBox(height: 32),

                    _buildWeeklyEarningsCard(provider),
                    const SizedBox(height: 32),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Recent Transactions',
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/wallet_history');
                          },
                          child: Text(
                            'View All',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF5B53C2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (provider.recentTransactions.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            'No recent transactions',
                            style: GoogleFonts.nunito(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: min(provider.recentTransactions.length, 5),
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildTransactionTile(
                            context,
                            provider.recentTransactions[index],
                          );
                        },
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB945AA), Color(0xFF5B53C2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B53C2).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Balance',
            style: GoogleFonts.nunito(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(balance),
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyEarningsCard(OperatorWalletProvider provider) {
    final brandColor = const Color(0xFF8E4CB6);
    const double chartHeight = 130;
    final weeklyEarnings = provider.weeklyEarnings;

    final double maxWeeklyExpense = weeklyEarnings.values.isEmpty
        ? 0.0
        : weeklyEarnings.values.reduce(max);
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
                    onPressed: () {
                      setState(() => _selectedWeekOffset--);
                      provider.fetchWeeklyEarnings(_selectedWeekOffset);
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
          if (provider.isChartLoading)
            SizedBox(
              height: chartHeight,
              child: const Center(child: CircularProgressIndicator()),
            )
          else
            SizedBox(
              height: chartHeight,
              child: _buildBarChart(
                chartHeight,
                weeklyEarnings,
                dynamicMaxValue,
              ),
            ),
          const SizedBox(height: 8),
          _buildXAxisLabels(),
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
        final barHeight = effectiveMaxVal > 0
            ? (value / effectiveMaxVal) * chartHeight
            : 0.0;

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

  Widget _buildTransactionTile(
    BuildContext context,
    Map<String, dynamic> transaction,
  ) {
    final bool isCredit = (transaction['amount'] as num) > 0;
    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    final amount = currencyFormat.format((transaction['amount'] as num).abs());
    final String type = transaction['type'] ?? 'remittance';

    String title;
    if (type == 'remittance') {
      title = 'Remittance: ${transaction['driver_name'] ?? 'Unknown Driver'}';
    } else if (type == 'cash_out') {
      title = 'Cash Out';
    } else {
      title = transaction['description'] ?? 'Transaction';
    }

    DateTime txDate;
    try {
      txDate = DateTime.parse(transaction['created_at'] ?? transaction['date']);
    } catch (e) {
      txDate = DateTime.now();
    }

    final date = DateFormat('MMM d, hh:mm a').format(txDate);

    return InkWell(
      onTap: () => _showTransactionDetailModal(context, transaction),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: GoogleFonts.nunito(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${isCredit ? '+' : '-'}$amount',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isCredit ? Colors.green.shade700 : Colors.red.shade700,
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
    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: 'P');
    final String type = transaction['type'] ?? 'remittance';
    final double amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;

    String modalTitle;
    if (type == 'remittance') {
      modalTitle = 'Remittance Transaction';
    } else if (type == 'cash_out') {
      modalTitle = 'Cash Out Transaction';
    } else {
      modalTitle = 'Transaction Details';
    }

    final String transactionCode =
        transaction['transaction_number'] ??
        'TX-${Random().nextInt(999999) + 100000}';

    DateTime txDate;
    try {
      txDate = DateTime.parse(transaction['created_at'] ?? transaction['date']);
    } catch (e) {
      txDate = DateTime.now();
    }

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return _buildDetailModal(
          context: dialogContext,
          title: modalTitle,
          details: [
            _buildDetailRow('Date:', DateFormat('MM/dd/yyyy').format(txDate)),
            _buildDetailRow('Time:', DateFormat('hh:mm a').format(txDate)),
            if (type == 'remittance') ...[
              _buildDetailRow('Driver:', transaction['driver_name'] ?? 'N/A'),
              _buildDetailRow(
                'Vehicle:',
                transaction['vehicle_plate'] ?? 'N/A',
              ),
            ],
          ],
          totalRow: _buildDetailRow(
            'Amount:',
            currencyFormat.format(amount.abs()),
            isTotal: true,
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
          border: Border.all(color: brandColor.withValues(alpha: 128)),
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
                Divider(color: brandColor.withValues(alpha: 128), height: 24),
                ...details,
                Divider(color: brandColor.withValues(alpha: 128), height: 24),
                totalRow,
                if (transactionCode != 'N/A') ...[
                  Divider(color: brandColor.withValues(alpha: 128), height: 24),
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
          Flexible(
            child: Text(
              value.toString(),
              textAlign: TextAlign.right,
              style: GoogleFonts.manrope(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
