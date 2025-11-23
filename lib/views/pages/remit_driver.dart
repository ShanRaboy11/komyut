import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

import '../providers/wallet_provider.dart';
import 'driver_app.dart';

class RemitPageDriver extends StatefulWidget {
  const RemitPageDriver({super.key});

  @override
  State<RemitPageDriver> createState() => _RemitPageDriverState();
}

class _RemitPageDriverState extends State<RemitPageDriver> {
  final TextEditingController _amountController = TextEditingController();
  bool _isButtonEnabled = false;
  String? _errorText;

  final Color _brandColor = const Color(0xFF8E4CB6);
  final List<Color> _gradientColors = const [
    Color(0xFFB945AA),
    Color(0xFF8E4CB6),
    Color(0xFF5B53C2),
  ];

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_validateInput);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DriverWalletProvider>(
        context,
        listen: false,
      ).fetchWalletData();
    });
  }

  void _validateInput() {
    if (!mounted) return;

    final provider = Provider.of<DriverWalletProvider>(context, listen: false);
    final currentBalance = provider.totalBalance;

    if (_amountController.text.length > 1 &&
        _amountController.text.startsWith('0')) {
      _amountController.text = _amountController.text.substring(1);
      _amountController.selection = TextSelection.fromPosition(
        TextPosition(offset: _amountController.text.length),
      );
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    setState(() {
      if (amount <= 0) {
        _isButtonEnabled = false;
        _errorText = null;
      } else if (amount > currentBalance) {
        _isButtonEnabled = false;
        _errorText = 'Amount exceeds your current balance.';
      } else {
        _isButtonEnabled = true;
        _errorText = null;
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _onNextPressed() {
    if (!_isButtonEnabled) return;

    final provider = Provider.of<DriverWalletProvider>(context, listen: false);

    DriverApp.navigatorKey.currentState?.pushNamed(
      '/remit_confirmation',
      arguments: {
        'amount': _amountController.text,
        'operatorName': provider.operatorName,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

    return Consumer<DriverWalletProvider>(
      builder: (context, provider, child) {
        final currentBalance = provider.totalBalance;
        final operatorName = provider.operatorName;

        final amountValue = double.tryParse(_amountController.text) ?? 0;
        final remainingBalance = currentBalance - amountValue;

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
              'Remittance',
              style: GoogleFonts.manrope(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: provider.isPageLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildInfoCard(
                        'Current Balance',
                        currencyFormat.format(currentBalance),
                        Symbols.account_balance_wallet_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard('Recipient', operatorName, Symbols.person),
                      const SizedBox(height: 40),
                      _buildAmountCard(),
                      const SizedBox(height: 16),
                      Center(
                        child: _errorText != null
                            ? Text(
                                _errorText!,
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  color: Colors.red,
                                ),
                              )
                            : Text(
                                'Remaining Balance: ${currencyFormat.format(remainingBalance)}',
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                      ),
                      const SizedBox(height: 32),
                      _buildNextButton(),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildInfoCard(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _brandColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: _brandColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard() {
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
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: _amountController,
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
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return Center(
      child: OutlinedButton(
        onPressed: _isButtonEnabled ? _onNextPressed : null,
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
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 14),
        ),
        child: Text(
          'Next',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
