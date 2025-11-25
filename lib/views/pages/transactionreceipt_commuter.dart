import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../widgets/button.dart';
import '../widgets/receipttransaction_card.dart';
import 'commuter_app.dart';

class TransactionReceiptPage extends StatefulWidget {
  final String id;
  final String type; // 'cash_in', 'redemption', or 'static'
  final Map<String, dynamic>? staticData;

  const TransactionReceiptPage({
    super.key,
    required this.id,
    required this.type,
    this.staticData,
  });

  @override
  State<TransactionReceiptPage> createState() => _TransactionReceiptPageState();
}

class _TransactionReceiptPageState extends State<TransactionReceiptPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    if (widget.type == 'static') {
      _data = widget.staticData;
      _loading = false;
    } else {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final supabase = Supabase.instance.client;
      Map<String, dynamic>? res;

      // Fetch all columns including 'status'
      if (widget.type == 'cash_in') {
        res = await supabase
            .from('transactions')
            .select('*, payment_methods(name)')
            .eq('id', widget.id)
            .maybeSingle();
      } else if (widget.type == 'redemption') {
        res = await supabase
            .from('points_transactions')
            .select()
            .eq('id', widget.id)
            .maybeSingle();
      } else {
        throw "Unknown transaction type: ${widget.type}";
      }

      if (res == null) {
        throw "Transaction not found. ID: ${widget.id}";
      }

      _data = res;
      setState(() => _loading = false);
    } catch (e) {
      debugPrint("Receipt Error: $e");
      setState(() {
        _error = 'Failed to load details. \n$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.black87,
                        size: 24,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  Text(
                    'Transaction Receipt',
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Symbols.download,
                        color: Colors.black87,
                        size: 24,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: SvgPicture.asset(
                        'assets/images/logo.svg',
                        height: 70,
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_loading)
                      _buildSkeletonLoader()
                    else if (_error != null)
                      _buildErrorState()
                    else if (_data != null)
                      _buildReceiptCard()
                    else
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No data found'),
                      ),

                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: CustomButton(
                        text: 'Back to Home',
                        onPressed: () {
                          CommuterApp.navigatorKey.currentState
                              ?.pushNamedAndRemoveUntil('/', (route) => false);
                        },
                        width: double.infinity,
                        height: 50,
                        textColor: Colors.white,
                        isFilled: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptCard() {
    final isCashIn =
        widget.type == 'cash_in' ||
        (widget.type == 'static' && _data!['category'] == 'cash_in');
    final isRedemption =
        widget.type == 'redemption' ||
        (widget.type == 'static' && _data!['category'] == 'redemption');

    final rawAmount = _data!['amount'] ?? _data!['change'] ?? 0;
    final double amount = (rawAmount is num) ? rawAmount.toDouble().abs() : 0.0;

    final dateStr = _data!['created_at'] ?? DateTime.now().toIso8601String();
    final dt = DateTime.parse(dateStr).toLocal();
    final dateFormatted = DateFormat('MM/dd/yyyy').format(dt);
    final timeFormatted = DateFormat('HH:mm').format(dt);

    String title = isCashIn ? 'Cash In' : 'Token Redemption';
    String ref =
        _data!['transaction_number'] ??
        _data!['id']?.toString().toUpperCase() ??
        '---';

    // --- STATUS ---
    String status;
    if (isCashIn) {
      status = _data!['status']?.toString() ?? 'pending';
    } else {
      // Redemptions are usually instant or don't have a status col in points_transactions
      status = _data!['status']?.toString() ?? 'completed';
    }

    // --- METHOD ---
    String method = 'System';
    if (isCashIn) {
      if (_data!['payment_methods'] != null &&
          _data!['payment_methods'] is Map) {
        method = _data!['payment_methods']['name'] ?? 'Method';
      } else if (_data!['method_name'] != null) {
        method = _data!['method_name'];
      }
    } else {
      // For redemption, the "Source" is Wallet Balance
      method = 'Wallet Balance';
    }

    // --- FEE LOGIC (STRICT) ---
    // Start with 0.0
    double transactionFee = 0.00;

    // Only apply fee if it is Cash In
    if (isCashIn) {
      // Default fee is 10
      transactionFee = 10.00;
      // If "counter", fee is 5
      if (method.toLowerCase().contains('counter')) {
        transactionFee = 5.00;
      }
    }

    String feeNote = isCashIn
        ? "A convenience fee has been applied to this transaction."
        : "No fees applied for this redemption.";

    return TransactionReceiptCard(
      title: title,
      amount: amount,
      date: dateFormatted,
      time: timeFormatted,
      paymentMethod: method,
      referenceNumber: ref,
      isRedemption: isRedemption,
      feeNote: feeNote,
      feeAmount: transactionFee,
      status: status,
    );
  }

  Widget _buildSkeletonLoader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          children: [
            Container(width: 100, height: 14, color: Colors.white),
            const SizedBox(height: 12),
            Container(width: 150, height: 32, color: Colors.white),
            const SizedBox(height: 16),
            Container(
              width: 80,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: 60, height: 14, color: Colors.white),
                Container(width: 80, height: 14, color: Colors.white),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: 60, height: 14, color: Colors.white),
                Container(width: 80, height: 14, color: Colors.white),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            Container(width: 200, height: 50, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Symbols.error, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(
            _error ?? "An unexpected error occurred",
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              color: Colors.red[700],
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Retry',
            onPressed: _loadData,
            width: 120,
            height: 40,
            isFilled: true,
            textColor: Colors.white,
          ),
        ],
      ),
    );
  }
}
