import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';

class OperatorCashOutPage extends StatefulWidget {
  const OperatorCashOutPage({super.key});

  @override
  State<OperatorCashOutPage> createState() => _OperatorCashOutPageState();
}

class _OperatorCashOutPageState extends State<OperatorCashOutPage> {
  final TextEditingController _amountController = TextEditingController();
  bool _isButtonEnabled = false;
  String? _errorText;

  final Color _brandColor = const Color(0xFF8E4CB6);

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged(String value, double currentBalance) {
    if (value.length > 1 && value.startsWith('0')) {
      _amountController.text = value.substring(1);
      _amountController.selection = TextSelection.fromPosition(
        TextPosition(offset: _amountController.text.length),
      );
    }

    final amount = int.tryParse(_amountController.text) ?? 0;
    final fee = 15.00;
    final totalDeduction = amount + fee;

    setState(() {
      if (amount <= 0) {
        _isButtonEnabled = false;
        _errorText = null;
      } else if (totalDeduction > currentBalance) {
        _isButtonEnabled = false;
        _errorText = 'Insufficient balance to cover amount and fee.';
      } else {
        _isButtonEnabled = true;
        _errorText = null;
      }
    });
  }

  void _onNextPressed() {
    if (!_isButtonEnabled) return;

    Navigator.of(
      context,
    ).pushNamed('/cash_out_confirmation', arguments: _amountController.text);
  }

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
          icon: const Icon(Icons.chevron_left_rounded, color: Colors.black54),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Cash Out',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<OperatorWalletProvider>(
        builder: (context, provider, child) {
          final currentBalance = provider.currentBalance;
          final amountValue = double.tryParse(_amountController.text) ?? 0;

          final fee = 15.00;
          final totalDeduction = amountValue > 0 ? (amountValue + fee) : 0.0;
          final remainingBalance = currentBalance - totalDeduction;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Withdraw Cash',
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Divider(
                  color: _brandColor.withValues(alpha: 0.5),
                  thickness: 1,
                ),
                const SizedBox(height: 40),

                _buildStepIndicator(),
                const SizedBox(height: 48),

                _buildAmountCard(currentBalance),
                const SizedBox(height: 16),

                Center(
                  child: _errorText != null
                      ? Text(
                          _errorText!,
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : Text(
                          'Remaining Balance: ${currencyFormat.format(remainingBalance < 0 ? 0 : remainingBalance)}',
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                ),
                const SizedBox(height: 32),

                _buildNextButton(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset('assets/images/step1.png', width: 40, height: 40),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Step 1',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Input the amount you want to withdraw from your komyut wallet below.',
                style: GoogleFonts.nunito(fontSize: 15, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountCard(double currentBalance) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _brandColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: _brandColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Enter Amount',
            style: GoogleFonts.manrope(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          Divider(color: _brandColor.withValues(alpha: 0.5), height: 24),
          SizedBox(
            width: double.infinity,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '₱',
                      style: GoogleFonts.manrope(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _amountController.text.isEmpty
                          ? "0"
                          : _amountController.text,
                      style: GoogleFonts.manrope(
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: _amountController,
                  onChanged: (val) => _onAmountChanged(val, currentBalance),
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  showCursor: false,
                  style: const TextStyle(color: Colors.transparent),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(5),
                  ],
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    fillColor: Colors.transparent,
                    filled: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'A PHP 15.00 fee will be charged per transaction.',
            style: GoogleFonts.nunito(fontSize: 13, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton(OperatorWalletProvider provider) {
    return Center(
      child: OutlinedButton(
        onPressed: (provider.isLoading || !_isButtonEnabled)
            ? null
            : _onNextPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: _isButtonEnabled ? _brandColor : Colors.grey,
          backgroundColor: _isButtonEnabled
              ? _brandColor.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          side: BorderSide(
            color: _isButtonEnabled
                ? _brandColor
                : Colors.grey.withValues(alpha: 0.5),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 10),
        ),
        child: provider.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                'Next',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }
}
