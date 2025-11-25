import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import '../providers/transactions.dart';
import '../models/transactions.dart';

class AdminActivityPage extends StatefulWidget {
  const AdminActivityPage({super.key});

  @override
  State<AdminActivityPage> createState() => _AdminActivityPage();
}

class _AdminActivityPage extends State<AdminActivityPage> {
  final List<Map<String, dynamic>> transactionTabs = [
    {"label": "Cash In", "value": 1, "type": "cash_in"},
    {"label": "Cash Out", "value": 2, "type": "cash_out"},
    {"label": "Remittance", "value": 3, "type": "remittance"},
    {"label": "Token Redemption", "value": 4, "type": "token_redemption"},
    {"label": "Fare Payment", "value": 5, "type": "fare_payment"},
  ];

  int activeTransaction = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TransactionProvider>();
      provider.loadTransactions();
    });
  }

  String _getSelectedType() {
    return transactionTabs.firstWhere(
      (t) => t["value"] == activeTransaction,
    )["type"];
  }

  static const LinearGradient _kGradient = LinearGradient(
    colors: [Color(0xFF5B53C2), Color(0xFFB945AA)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 420;
    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final String selectedType = _getSelectedType();
        final filteredActivity = provider.getTransactionsByType(selectedType);

        return Scaffold(
          backgroundColor: const Color(0xFFF7F4FF),
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(13),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Activity',
                                  style: GoogleFonts.manrope(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Manage activity',
                                  style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: _kGradient,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${filteredActivity.length} Items',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9C6BFF).withAlpha(13),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SizedBox(
                          height: isSmall ? 40 : 50,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: transactionTabs
                                  .map(
                                    (tab) => _buildPillTab(
                                      tab["label"],
                                      tab["value"],
                                      activeTransaction == tab["value"],
                                      isSmall,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: provider.isLoading
                      ? _buildActivitySkeleton(context)
                      : provider.errorMessage != null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Error: ${provider.errorMessage}'),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () => provider.refresh(),
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: () => provider.refresh(),
                                child: filteredActivity.isEmpty
                                    ? ListView(
                                        children: [
                                          SizedBox(
                                            height: MediaQuery.of(context).size.height * 0.5,
                                            child: Center(
                                              child: Text(
                                                'No transactions found',
                                                style: GoogleFonts.manrope(
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : ListView.builder(
                                        itemCount: filteredActivity.length,
                                        itemBuilder: (context, index) {
                                          final tx = filteredActivity[index];
                                          return buildTransactionItem(
                                            context,
                                            tx,
                                            currencyFormat,
                                            _showTransactionDetailModal,
                                          );
                                        },
                                      ),
                              ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPillTab(String label, int value, bool isActive, bool isSmall) {
    return GestureDetector(
      onTap: () => setState(() => activeTransaction = value),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: EdgeInsets.symmetric(
          vertical: isSmall ? 10 : 12,
          horizontal: 16,
        ),
        decoration: BoxDecoration(
          gradient: isActive ? _kGradient : null,
          color: isActive ? null : Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: GoogleFonts.manrope(
            fontSize: 12,
            color: isActive ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

// ------------------ Transaction Item Widget ------------------
Widget buildTransactionItem(
  BuildContext context,
  TransactionModel tx,
  NumberFormat currencyFormat,
  void Function(BuildContext, TransactionModel) showModal,
) {
  final String type = tx.type;
  final double amount = tx.amount;

  // Determine if it's earning (green) or cash out (red)
  final bool showSign =
      type == 'cash_in' || type == 'token_redemption' || type == 'cash_out';

  final String title = switch (type) {
    'fare_payment' => 'Trip Earning',
    'cash_in' => 'Cash In',
    'token_redemption' => 'Token Redemption',
    'cash_out' => 'Cash Out',
    'remittance' => 'Remittance',
    _ => 'Transaction',
  };

  final Color amountColor = (type == 'cash_out')
      ? Colors.red
      : (type == 'cash_in' || type == 'token_redemption')
          ? Colors.green
          : const Color(0xFF5B53C2);

  final String date = DateFormat('MMM d, yyyy').format(tx.createdAt);
  final String time = DateFormat('hh:mm a').format(tx.createdAt);

  return InkWell(
    onTap: () => showModal(context, tx),
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color.fromRGBO(156, 39, 176, 0.5), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // LEFT SIDE — title + date/time
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$date, $time',
                style: GoogleFonts.nunito(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          // RIGHT SIDE — amount
          Text(
            '${showSign ? (type == 'cash_out' ? '-' : '+') : ''}${currencyFormat.format(amount.abs())}',
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

// ------------------ Modal ------------------
void _showTransactionDetailModal(
  BuildContext context,
  TransactionModel transaction,
) {
  final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
  final String type = transaction.type;
  final double amount = transaction.amount;
  final DateTime createdAt = transaction.createdAt;

  // Map type to title
  final String modalTitle = switch (type) {
    'fare_payment' => 'Fare Payment Transaction',
    'cash_in' => 'Cash In Transaction',
    'cash_out' => 'Cash Out Transaction',
    'token_redemption' => 'Token Redemption',
    'remittance' => 'Remittance Transaction',
    _ => 'Transaction',
  };

  // Build detail rows based on transaction type
  List<Widget> details;
  switch (type) {
    case 'cash_in':
      details = [
        _buildDetailRow('Date:', DateFormat('MM/dd/yyyy').format(createdAt)),
        _buildDetailRow('Time:', DateFormat('hh:mm a').format(createdAt)),
        _buildDetailRow('Passenger:', transaction.passengerName ?? 'N/A'),
        _buildDetailRow('Amount:', currencyFormat.format(amount.abs())),
        _buildDetailRow('Status:', transaction.status.toUpperCase()),
      ];
      break;

    case 'cash_out':
      details = [
        _buildDetailRow('Date:', DateFormat('MM/dd/yyyy').format(createdAt)),
        _buildDetailRow('Time:', DateFormat('hh:mm a').format(createdAt)),
        _buildDetailRow('Driver/Operator:', transaction.driverName ?? transaction.initiatorName ?? 'N/A'),
        _buildDetailRow('Amount:', currencyFormat.format(amount.abs())),
      ];
      break;

    case 'remittance':
      details = [
        _buildDetailRow('Date:', DateFormat('MM/dd/yyyy').format(createdAt)),
        _buildDetailRow('Time:', DateFormat('hh:mm a').format(createdAt)),
        _buildDetailRow('Driver:', transaction.driverName ?? 'N/A'),
        _buildDetailRow('Plate Number:', transaction.plateNumber ?? 'N/A'),
        _buildDetailRow('Operator:', transaction.operatorName ?? 'N/A'),
      ];
      break;

    case 'token_redemption':
      details = [
        _buildDetailRow('Date:', DateFormat('MM/dd/yyyy').format(createdAt)),
        _buildDetailRow('Time:', DateFormat('hh:mm a').format(createdAt)),
        _buildDetailRow('Passenger:', transaction.passengerName ?? 'N/A'),
        _buildDetailRow('Amount:', currencyFormat.format(amount.abs())),
      ];
      break;

    case 'fare_payment':
      details = [
        _buildDetailRow('Date:', DateFormat('MM/dd/yyyy').format(createdAt)),
        _buildDetailRow('Time:', DateFormat('hh:mm a').format(createdAt)),
        _buildDetailRow('Passenger:', transaction.passengerName ?? 'N/A'),
        _buildDetailRow('Driver:', transaction.driverName ?? 'N/A'),
        _buildDetailRow('Route Code:', transaction.routeCode ?? 'N/A'),
        _buildDetailRow(
          'Number of Passengers:',
          transaction.numPassengers ?? 1,
        ),
      ];
      break;

    default:
      details = [
        _buildDetailRow('Date:', DateFormat('MM/dd/yyyy').format(createdAt)),
        _buildDetailRow('Time:', DateFormat('hh:mm a').format(createdAt)),
      ];
  }

  showDialog(
    context: context,
    useRootNavigator: true,
    barrierColor: Colors.black54,
    builder: (dialogContext) {
      return _buildDetailModal(
        context: dialogContext,
        title: modalTitle,
        details: details,
        totalRow: _buildDetailRow(
          'Amount:',
          currencyFormat.format(amount.abs()),
          isTotal: true,
        ),
        transactionCode: transaction.transactionNumber ?? 'N/A',
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
        border: Border.all(color: brandColor.withAlpha(128)),
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Divider(color: brandColor.withAlpha(128), height: 24),
              ...details,
              Divider(color: brandColor.withAlpha(128), height: 24),
              totalRow,
              if (transactionCode != 'N/A') ...[
                Divider(color: brandColor.withAlpha(128), height: 24),
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
                    fontSize: 11,
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
              onTap: () async {
                // First try popping the root navigator where the dialog was shown.
                final poppedRoot = await Navigator.of(context, rootNavigator: true).maybePop();
                if (!poppedRoot) {
                  // Fallback: try to pop the nearest navigator in case dialog was presented on a nested navigator.
                  await Navigator.of(context).maybePop();
                }
              },
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

// Simple shimmer skeleton to match admin dashboard style
Widget _buildActivitySkeleton(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  return Shimmer.fromColors(
    baseColor: Colors.grey.shade300,
    highlightColor: Colors.grey.shade100,
    child: RefreshIndicator(
      onRefresh: () async {},
      color: const Color(0xFF8E4CB6),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(6, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(6),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: width * 0.15,
                    height: 40,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 12, color: Colors.grey[300]),
                        const SizedBox(height: 8),
                        Container(height: 12, width: width * 0.5, color: Colors.grey[300]),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(width: 60, height: 16, color: Colors.grey[300]),
                ],
              ),
            );
          }),
        ),
      ),
    ),
  );
}