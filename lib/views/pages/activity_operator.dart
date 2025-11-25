import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import '../providers/transactions.dart';
import '../models/transactions.dart';

class OperatorRemittancesPage extends StatefulWidget {
  const OperatorRemittancesPage({super.key});

  @override
  State<OperatorRemittancesPage> createState() => _OperatorRemittancesPageState();
}

class _OperatorRemittancesPageState extends State<OperatorRemittancesPage> {
  String _selectedFilter = 'all'; // all, today, week, month
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TransactionProvider>();
      provider.loadTransactions();
    });
  }

  static const LinearGradient _kGradient = LinearGradient(
    colors: [Color(0xFF5B53C2), Color(0xFFB945AA)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  List<TransactionModel> _filterRemittances(List<TransactionModel> remittances) {
    List<TransactionModel> filtered = remittances;

    // Apply date filter
    if (_selectedFilter != 'all') {
      final now = DateTime.now();
      filtered = filtered.where((tx) {
        switch (_selectedFilter) {
          case 'today':
            return tx.createdAt.year == now.year &&
                   tx.createdAt.month == now.month &&
                   tx.createdAt.day == now.day;
          case 'week':
            final weekAgo = now.subtract(const Duration(days: 7));
            return tx.createdAt.isAfter(weekAgo);
          case 'month':
            return tx.createdAt.year == now.year &&
                   tx.createdAt.month == now.month;
          default:
            return true;
        }
      }).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((tx) {
        final driverName = tx.driverName?.toLowerCase() ?? '';
        final operatorName = tx.operatorName?.toLowerCase() ?? '';
        final plateNumber = tx.plateNumber?.toLowerCase() ?? '';
        final transactionNumber = tx.transactionNumber?.toLowerCase() ?? '';
        
        return driverName.contains(query) ||
               operatorName.contains(query) ||
               plateNumber.contains(query) ||
               transactionNumber.contains(query);
      }).toList();
    }

    return filtered;
  }

  double _calculateTotal(List<TransactionModel> remittances) {
    return remittances.fold(0.0, (sum, tx) => sum + tx.amount);
  }

  @override
  Widget build(BuildContext context) {
    // width previously unused; removed to satisfy analyzer
    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final allRemittances = provider.getTransactionsByType('remittance');
        final filteredRemittances = _filterRemittances(allRemittances);
        final totalAmount = _calculateTotal(filteredRemittances);

        return Scaffold(
          backgroundColor: const Color(0xFFF7F4FF),
          body: SafeArea(
            child: Column(
              children: [
                // Header (match OperatorReportsPage style)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Remittances',
                            style: GoogleFonts.manrope(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      
                    ],
                  ),
                ),
                // Stats Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: _kGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5B53C2).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Remittances',
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currencyFormat.format(totalAmount),
                                style: GoogleFonts.manrope(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${filteredRemittances.length} Transaction${filteredRemittances.length != 1 ? 's' : ''}',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Search and Filter Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(10),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            onChanged: (value) {
                              setState(() => _searchQuery = value);
                            },
                            decoration: InputDecoration(
                              hintText: 'Search by driver, operator, plate...',
                              hintStyle: GoogleFonts.nunito(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Color(0xFF5B53C2),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          setState(() => _selectedFilter = value);
                        },
                        icon: Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            gradient: _kGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF5B53C2).withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.filter_list,
                            color: Colors.white,
                          ),
                        ),
                        itemBuilder: (context) => [
                          _buildFilterMenuItem('all', 'All Time'),
                          _buildFilterMenuItem('today', 'Today'),
                          _buildFilterMenuItem('week', 'This Week'),
                          _buildFilterMenuItem('month', 'This Month'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Remittances List
                Expanded(
                  child: provider.isLoading
                      ? _buildRemittanceSkeleton(context)
                      : provider.errorMessage != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Error loading remittances',
                                    style: GoogleFonts.manrope(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    provider.errorMessage ?? '',
                                    style: GoogleFonts.nunito(
                                      fontSize: 13,
                                      color: Colors.grey.shade500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: () => provider.refresh(),
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Retry'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF5B53C2),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () => provider.refresh(),
                              color: const Color(0xFF5B53C2),
                              child: filteredRemittances.isEmpty
                                  ? ListView(
                                      children: [
                                        SizedBox(
                                          height: MediaQuery.of(context).size.height * 0.5,
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.receipt_long_outlined,
                                                  size: 64,
                                                  color: Colors.grey.shade300,
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  'No remittances found',
                                                  style: GoogleFonts.manrope(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.grey.shade400,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  _searchQuery.isNotEmpty
                                                      ? 'Try adjusting your search'
                                                      : 'No remittances for this period',
                                                  style: GoogleFonts.nunito(
                                                    fontSize: 13,
                                                    color: Colors.grey.shade400,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      itemCount: filteredRemittances.length,
                                      itemBuilder: (context, index) {
                                        final tx = filteredRemittances[index];
                                        return _buildRemittanceCard(
                                          context,
                                          tx,
                                          currencyFormat,
                                        );
                                      },
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

  PopupMenuItem<String> _buildFilterMenuItem(String value, String label) {
    final isSelected = _selectedFilter == value;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            size: 20,
            color: isSelected ? const Color(0xFF5B53C2) : Colors.grey,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? const Color(0xFF5B53C2) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemittanceCard(
    BuildContext context,
    TransactionModel tx,
    NumberFormat currencyFormat,
  ) {
    final String date = DateFormat('MMM d, yyyy').format(tx.createdAt);
    final String time = DateFormat('hh:mm a').format(tx.createdAt);

    return InkWell(
      onTap: () => _showRemittanceDetailModal(context, tx),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF5B53C2).withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.driverName ?? 'Unknown Driver',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (tx.plateNumber != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5B53C2).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tx.plateNumber!,
                            style: GoogleFonts.sourceCodePro(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF5B53C2),
                            ),
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    currencyFormat.format(tx.amount),
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade200, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.business, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    tx.operatorName ?? 'No Operator',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  '$date, $time',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRemittanceDetailModal(
    BuildContext context,
    TransactionModel transaction,
  ) {
    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    final DateTime createdAt = transaction.createdAt;

    final List<Widget> details = [
      _buildDetailRow('Date:', DateFormat('MM/dd/yyyy').format(createdAt)),
      _buildDetailRow('Time:', DateFormat('hh:mm a').format(createdAt)),
      _buildDetailRow('Driver:', transaction.driverName ?? 'N/A'),
      _buildDetailRow('Plate Number:', transaction.plateNumber ?? 'N/A'),
      _buildDetailRow('Operator:', transaction.operatorName ?? 'N/A'),
      _buildDetailRow('Status:', transaction.status.toUpperCase()),
    ];

    showDialog(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return _buildDetailModal(
          context: dialogContext,
          title: 'Remittance Details',
          details: details,
          totalRow: _buildDetailRow(
            'Amount:',
            currencyFormat.format(transaction.amount),
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
                    fontSize: 18,
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
                onTap: () => Navigator.of(context, rootNavigator: true).pop(),
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

  Widget _buildRemittanceSkeleton(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(6),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 16,
                            width: 150,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 12,
                            width: 80,
                            color: Colors.grey[300],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 32,
                      width: 80,
                      color: Colors.grey[300],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(height: 1, color: Colors.grey[200]),
                const SizedBox(height: 12),
                Container(
                  height: 12,
                  width: 200,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 180,
                  color: Colors.grey[300],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}