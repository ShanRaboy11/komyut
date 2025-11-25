import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
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

      // Ensure we query the correct table based on type
      if (widget.type == 'cash_in') {
        res = await supabase
            .from('transactions')
            .select('*, payment_methods(name)') // Join name
            .eq('id', widget.id)
            .maybeSingle(); // Safer than single()
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
        throw "Transaction not found in DB. ID: ${widget.id}";
      }

      _data = res;
      setState(() => _loading = false);
    } catch (e) {
      debugPrint("Receipt Error: $e"); // View this in console
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

    // Safely get method name
    String method = 'System';
    if (isCashIn) {
      if (_data!['payment_methods'] != null &&
          _data!['payment_methods'] is Map) {
        method = _data!['payment_methods']['name'] ?? 'Method';
      } else if (_data!['method_name'] != null) {
        method = _data!['method_name'];
      }
    } else {
      method = 'Wallet Balance';
    }

    // --- FEE LOGIC (5 for Counter, 10 for Others) ---
    double transactionFee = 10.00;
    if (isCashIn && method.toLowerCase().contains('counter')) {
      transactionFee = 5.00;
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
    );
  }

  Widget _buildSkeletonLoader() =>
      const Center(child: CircularProgressIndicator());
  Widget _buildErrorState() => Center(
    child: Text(
      _error ?? "Unknown Error",
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.red),
    ),
  );
}
