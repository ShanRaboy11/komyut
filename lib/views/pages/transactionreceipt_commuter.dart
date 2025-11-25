import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../widgets/button.dart';
import '../widgets/receipttransaction_card.dart'; // Import the new card widget
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
    try {
      final supabase = Supabase.instance.client;

      if (widget.type == 'cash_in') {
        final res = await supabase
            .from('transactions')
            .select('*, payment_methods(name)')
            .eq('id', widget.id)
            .single();
        _data = res;
      } else if (widget.type == 'redemption') {
        final res = await supabase
            .from('points_transactions')
            .select()
            .eq('id', widget.id)
            .single();
        _data = res;
      }

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = 'Failed to load details: $e';
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

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.of(context).padding.bottom + 32,
                ),
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

                    // Extra bottom padding
                    const SizedBox(height: 40),
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
        widget.type == 'redemption' || _data!['category'] == 'redemption';

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

    String method = 'System';
    if (isCashIn) {
      if (_data!['payment_methods'] != null) {
        method = _data!['payment_methods']['name'];
      } else if (_data!['method_name'] != null) {
        method = _data!['method_name'];
      }
    } else {
      method = 'Wallet Balance';
    }

    String? feeNote = isCashIn
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
    );
  }

  Widget _buildSkeletonLoader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Status pill skeleton
              Container(
                width: 100,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 16),
              // Title skeleton
              Container(
                width: 120,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              // Amount skeleton
              Container(
                width: 150,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              // Details skeleton
              ...List.generate(
                3,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 120,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        width: 100,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              // Barcode skeleton
              Container(
                width: 200,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(
            _error!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Retry',
            onPressed: _loadData,
            width: double.infinity,
            height: 48,
            isFilled: true,
            textColor: Colors.white,
          ),
        ],
      ),
    );
  }
}
