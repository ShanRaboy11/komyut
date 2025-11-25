import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../widgets/button.dart';

class AdminActivityPage extends StatefulWidget {
  const AdminActivityPage({super.key});

  @override
  State<AdminActivityPage> createState() => _AdminActivityPage();
}

class AdminTransaction {
  final String transactionType;
  final String date; // e.g. "Nov 22"
  final String time; // e.g. "07:10 PM"
  final double amount;
  final String? status;

  AdminTransaction({
    required this.transactionType,
    required this.date,
    required this.time,
    required this.amount,
    this.status,
  });
}

class _AdminActivityPage extends State<AdminActivityPage> {
  final List<AdminTransaction> adminActivities = [
    // 🔹 Token Redemption
    AdminTransaction(
      transactionType: "Token Redemption",
      date: "Nov 22",
      time: "07:10 PM",
      amount: 5.00,
    ),
    AdminTransaction(
      transactionType: "Token Redemption",
      date: "Nov 21",
      time: "03:55 PM",
      amount: 10.00,
    ),
    // 🔹 Cash In
    AdminTransaction(
      transactionType: "Cash In",
      date: "Nov 20",
      time: "11:42 AM",
      amount: 150.00,
      status: "Pending",
    ),
    AdminTransaction(
      transactionType: "Cash In",
      date: "Nov 19",
      time: "09:10 AM",
      amount: 200.00,
      status: "Completed",
    ),

    // 🔹 Cash Out
    AdminTransaction(
      transactionType: "Cash Out",
      date: "Nov 18",
      time: "05:25 PM",
      amount: -80.00,
      status: "Rejected",
    ),
    AdminTransaction(
      transactionType: "Cash Out",
      date: "Nov 17",
      time: "02:18 PM",
      amount: -120.00,
      status: "Completed",
    ),
    AdminTransaction(
      transactionType: "Cash Out",
      date: "Nov 17",
      time: "02:30 PM",
      amount: -520.00,
      status: "Pending",
    ),
    // 🔹 Remittance
    AdminTransaction(
      transactionType: "Remittance",
      date: "Nov 16",
      time: "07:40 PM",
      amount: 420.00,
    ),
    AdminTransaction(
      transactionType: "Remittance",
      date: "Nov 15",
      time: "01:25 PM",
      amount: 300.00,
    ),
    // 🔹 Fare Payment
    AdminTransaction(
      transactionType: "Fare Payment",
      date: "Nov 14",
      time: "06:22 PM",
      amount: 12.00,
    ),
    AdminTransaction(
      transactionType: "Fare Payment",
      date: "Nov 14",
      time: "07:02 AM",
      amount: 10.00,
    ),
  ];

  final List<Map<String, dynamic>> transactionTabs = [
    {"label": "Cash In", "value": 1},
    {"label": "Cash Out", "value": 2},
    {"label": "Remittance", "value": 3},
    {"label": "Token Redemption", "value": 4},
    {"label": "Fare Payment", "value": 5},
  ];

  int activeTransaction = 1;

  String? _statusFilter;

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
    final String selectedType = transactionTabs.firstWhere(
      (t) => t["value"] == activeTransaction,
    )["label"];

    final filteredActivity = adminActivities.where((r) {
      if (r.transactionType != selectedType) return false;

      // Only filter status for Cash In / Cash Out
      if ((selectedType == 'Cash In' || selectedType == 'Cash Out') &&
          _statusFilter != null) {
        return r.status == _statusFilter;
      }

      return true;
    }).toList();

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
            if (selectedType == 'Cash In' || selectedType == 'Cash Out')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _statusFilter == "Pending"
                          ? "Pending Transactions"
                          : _statusFilter == "Completed"
                          ? "Completed Transactions"
                          : _statusFilter == "Rejected"
                          ? "Rejected Transactions"
                          : "All Transactions",
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: "Filter by Status",
                      onSelected: (value) {
                        setState(() {
                          _statusFilter =
                              value; // <-- create this variable in your state
                        });
                      },
                      offset: const Offset(0, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'Pending', child: Text('Pending')),
                        PopupMenuItem(
                          value: 'Completed',
                          child: Text('Completed'),
                        ),
                        PopupMenuItem(
                          value: 'Rejected',
                          child: Text('Rejected'),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _statusFilter == null
                              ? const Color.fromARGB(255, 207, 206, 206)
                              : const Color.fromARGB(255, 207, 206, 206),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          size: 20,
                          color: _statusFilter == null
                              ? Colors.grey.shade700
                              : Colors.white,
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
                child: ListView.builder(
                  itemCount: filteredActivity.length,
                  itemBuilder: (context, index) {
                    final tx = filteredActivity[index];
                    final Map<String, dynamic> txMap = {
                      'type': tx.transactionType.toLowerCase().replaceAll(
                        ' ',
                        '_',
                      ),
                      'amount': tx.amount,
                      'created_at': DateTime.now().toIso8601String(),
                      'transaction_number': 'TXN${index + 1000}',
                      'status': tx.status, // ✅ now included
                    };
                    return buildTransactionItem(
                      context,
                      txMap,
                      currencyFormat,
                      _showTransactionDetailModal,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
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
  Map<String, dynamic> tx,
  NumberFormat currencyFormat,
  void Function(BuildContext, Map<String, dynamic>) showModal,
) {
  final String type = tx['type'] ?? 'fare_payment';
  final double amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;

  // Determine if it's earning (green) or cash out (red)
  final bool showSign =
      type == 'cash_in' || type == 'token_redemption' || type == 'cash_out';

  final String title = (type == 'fare_payment')
      ? 'Trip Earning'
      : (type == 'cash_in')
      ? 'Cash In'
      : (type == 'token_redemption')
      ? 'Token Redemption'
      : (type == 'cash_out')
      ? 'Cash Out'
      : 'Remittance';

  final Color amountColor = (type == 'cash_out')
      ? Colors.red
      : (type == 'cash_in' || type == 'token_redemption')
      ? Colors.green
      : const Color(0xFF5B53C2);

  final String date = DateFormat(
    'MMM d, yyyy',
  ).format(DateTime.parse(tx['created_at']));
  final String time = DateFormat(
    'hh:mm a',
  ).format(DateTime.parse(tx['created_at']));

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
  Map<String, dynamic> transaction,
) {
  final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
  final String type = transaction['type'] ?? 'fare_payment';
  final double amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
  final DateTime createdAt = DateTime.parse(transaction['created_at']);
  final bool isPendingCashInOrOut =
      (transaction['type'] == 'cash_in' || transaction['type'] == 'cash_out') &&
      transaction['status'] == 'Pending';

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
        _buildDetailRow('Passenger:', transaction['passenger'] ?? 'John Doe'),
        _buildDetailRow('Amount:', currencyFormat.format(amount.abs())),
        _buildDetailRow('Channel:', transaction['channel'] ?? 'Cash'),
        _buildDetailRow('Status:', transaction['status'] ?? 'Completed'),
      ];
      break;

    case 'cash_out':
      details = [
        _buildDetailRow('Date:', DateFormat('MM/dd/yyyy').format(createdAt)),
        _buildDetailRow('Time:', DateFormat('hh:mm a').format(createdAt)),
        _buildDetailRow('Driver/Operator:', transaction['driver'] ?? 'N/A'),
      ];
      break;

    case 'remittance':
      details = [
        _buildDetailRow('Date:', DateFormat('MM/dd/yyyy').format(createdAt)),
        _buildDetailRow('Time:', DateFormat('hh:mm a').format(createdAt)),
        _buildDetailRow('Driver:', transaction['driver'] ?? 'N/A'),
        _buildDetailRow('Plate Number:', transaction['plate_number'] ?? 'N/A'),
        _buildDetailRow('Operator:', transaction['operator'] ?? 'N/A'),
      ];
      break;

    case 'token_redemption':
      details = [
        _buildDetailRow('Date:', DateFormat('MM/dd/yyyy').format(createdAt)),
        _buildDetailRow('Time:', DateFormat('hh:mm a').format(createdAt)),
        _buildDetailRow('Passenger:', transaction['passenger'] ?? 'John Doe'),
      ];
      break;

    case 'fare_payment':
      details = [
        _buildDetailRow('Date:', DateFormat('MM/dd/yyyy').format(createdAt)),
        _buildDetailRow('Time:', DateFormat('hh:mm a').format(createdAt)),
        _buildDetailRow('Passenger:', transaction['passenger'] ?? 'John Doe'),
        _buildDetailRow('Driver:', transaction['driver'] ?? 'N/A'),
        _buildDetailRow('Route Code:', transaction['route_code'] ?? 'N/A'),
        _buildDetailRow(
          'Number of Passengers:',
          transaction['num_passengers'] ?? 1,
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
        showActionButtons: isPendingCashInOrOut,
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
  required bool showActionButtons,
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

              const SizedBox(height: 8),
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

              if (showActionButtons) ...[
                Divider(color: brandColor.withAlpha(128), height: 24),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: "Reject",
                        isFilled: false,
                        strokeColor: const Color(0xFF5B53C2),
                        outlinedFillColor: Colors.white,
                        textColor: const Color(0xFF5B53C2),
                        onPressed: () {},
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: "Accept",
                        isFilled: true,
                        textColor: Colors.white,
                        onPressed: () {},
                        fontSize: 14,
                      ),
                    ),
                  ],
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
