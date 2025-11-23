import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:barcode_widget/barcode_widget.dart';

class WalletHistoryOperatorPage extends StatefulWidget {
  const WalletHistoryOperatorPage({super.key});

  @override
  State<WalletHistoryOperatorPage> createState() =>
      _WalletHistoryOperatorPageState();
}

class _WalletHistoryOperatorPageState extends State<WalletHistoryOperatorPage> {
  // --- HARDCODED DATA ---
  final List<Map<String, dynamic>> _dummyTransactions = [
    {
      'id': 'tx_101',
      'type': 'remittance_received',
      'amount': 850.00,
      'created_at': DateTime.now()
          .subtract(const Duration(minutes: 45))
          .toIso8601String(),
      'transaction_number': 'REM-88219001',
      'driver_name': 'Juan Dela Cruz',
      'vehicle_plate': 'ABC 1234',
    },
    {
      'id': 'tx_102',
      'type': 'remittance_received',
      'amount': 1200.50,
      'created_at': DateTime.now()
          .subtract(const Duration(hours: 3))
          .toIso8601String(),
      'transaction_number': 'REM-88219002',
      'driver_name': 'Pedro Penduko',
      'vehicle_plate': 'XYZ 9876',
    },
    {
      'id': 'tx_103',
      'type': 'cash_out',
      'amount': 5000.00,
      'created_at': DateTime.now()
          .subtract(const Duration(days: 1, hours: 2))
          .toIso8601String(),
      'transaction_number': 'WTH-55102933',
      'details': 'Transfer to BDO',
    },
    {
      'id': 'tx_104',
      'type': 'remittance_received',
      'amount': 640.00,
      'created_at': DateTime.now()
          .subtract(const Duration(days: 1, hours: 5))
          .toIso8601String(),
      'transaction_number': 'REM-88218888',
      'driver_name': 'Jose Rizal',
      'vehicle_plate': 'ABC 1234',
    },
    {
      'id': 'tx_105',
      'type': 'admin_fee',
      'amount': 150.00,
      'created_at': DateTime.now()
          .subtract(const Duration(days: 2))
          .toIso8601String(),
      'transaction_number': 'FEE-11223344',
      'details': 'Weekly platform maintenance',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Transactions',
          style: GoogleFonts.manrope(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 16.0),
            child: Text(
              'All Transactions',
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: _dummyTransactions.isEmpty
                ? const Center(child: Text('No history found.'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 40.0),
                    itemCount: _dummyTransactions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _dummyTransactions[index];
                      return _TransactionItem(transaction: item);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const _TransactionItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    final String type = transaction['type'] ?? 'remittance_received';
    final double amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;

    final bool isEarning = type == 'remittance_received';

    String title;
    if (type == 'remittance_received') {
      title = 'Remittance: ${transaction['driver_name'] ?? 'Unknown Driver'}';
    } else if (type == 'cash_out') {
      title = 'Cash Out to Bank';
    } else {
      title = 'System Fee';
    }

    final Color amountColor = isEarning
        ? Colors.green.shade700
        : Colors.red.shade700;

    final String date = DateFormat(
      'MMM d, hh:mm a',
    ).format(DateTime.parse(transaction['created_at']));

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
              '${isEarning ? '+' : '-'}${currencyFormat.format(amount.abs())}',
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

  // --- MODAL LOGIC ---

  void _showTransactionDetailModal(
    BuildContext context,
    Map<String, dynamic> transaction,
  ) {
    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: 'P');
    final String type = transaction['type'] ?? 'remittance_received';
    final double amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;

    String modalTitle;
    if (type == 'remittance_received') {
      modalTitle = 'Remittance Received';
    } else if (type == 'cash_out') {
      modalTitle = 'Cash Out';
    } else {
      modalTitle = 'Transaction Details';
    }

    final String transactionCode = transaction['transaction_number'] ?? 'N/A';

    showDialog(
      context: context,
      barrierColor: Colors.black54,
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
            // ADDED DRIVER & VEHICLE INFO IF REMITTANCE
            if (type == 'remittance_received') ...[
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
