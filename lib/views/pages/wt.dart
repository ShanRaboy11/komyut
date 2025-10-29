import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class RedeemTokensPage extends StatefulWidget {
  const RedeemTokensPage({super.key});

  @override
  State<RedeemTokensPage> createState() => _RedeemTokensPageState();
}

class _RedeemTokensPageState extends State<RedeemTokensPage> {
  final TextEditingController _tokenController = TextEditingController();
  String _pesoEquivalent = "P0.00";
  bool _isButtonEnabled = false;
  bool _hasError = false;

  final int _balance = 120;
  final Color _brandColor = const Color(0xFF8E4CB6);
  final gradientColors = const [
    Color(0xFFB945AA),
    Color(0xFF8E4CB6),
    Color(0xFF5B53C2),
  ];

  @override
  void initState() {
    super.initState();
    _tokenController.text = "0";
    _tokenController.addListener(_onTokenAmountChanged);
  }

  void _onTokenAmountChanged() {
    String text = _tokenController.text;

    if (text.length > 1 && text.startsWith('0')) {
      text = text.substring(1);
      _tokenController.text = text;
      _tokenController.selection = TextSelection.fromPosition(
        TextPosition(offset: _tokenController.text.length),
      );
    }

    if (text.isEmpty) {
      _tokenController.text = "0";
      _tokenController.selection = TextSelection.fromPosition(
        TextPosition(offset: 1),
      );
    }

    final double? amount = double.tryParse(_tokenController.text);
    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: 'P');

    if (amount != null && amount > 0) {
      if (amount > _balance) {
        setState(() {
          _pesoEquivalent = currencyFormat.format(amount);
          _hasError = true;
          _isButtonEnabled = false;
        });
      } else {
        setState(() {
          _pesoEquivalent = currencyFormat.format(amount);
          _hasError = false;
          _isButtonEnabled = true;
        });
      }
    } else {
      setState(() {
        _pesoEquivalent = "P0.00";
        _isButtonEnabled = false;
        _hasError = false;
      });
    }
  }

  @override
  void dispose() {
    _tokenController.removeListener(_onTokenAmountChanged);
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          'Cash In',
          style: GoogleFonts.manrope(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(30.0, 16.0, 30.0, 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 0),
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 50.0),
                  child: Image.asset(
                    'assets/images/token_exchange.png',
                    height: 250,
                  ),
                ),
                _buildTokenBalance(),
              ],
            ),
            const SizedBox(height: 50),
            _buildInputSection(),
            const SizedBox(height: 30),
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wheel Tokens',
          style: GoogleFonts.manrope(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Divider(color: _brandColor.withValues(alpha: 0.5), thickness: 1),
      ],
    );
  }

  Widget _buildTokenBalance() {
    return Column(
      children: [
        Text(
          '120',
          style: GoogleFonts.manrope(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: _brandColor,
          ),
        ),
        Text(
          'Wheel Tokens',
          style: GoogleFonts.manrope(
            fontSize: 18,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter wheel tokens to redeem',
          style: GoogleFonts.nunito(
            fontSize: 15,
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _hasError
                      ? Colors.red
                      : _brandColor.withValues(alpha: 0.3),
                  width: _hasError ? 2 : 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: TextField(
                      controller: _tokenController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: false,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(7),
                      ],
                      cursorColor: _brandColor,
                      cursorHeight: 20,
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _hasError ? Colors.red : _brandColor,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _pesoEquivalent,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _hasError ? Colors.red : _brandColor,
                    ),
                  ),
                ],
              ),
            ),

            const Positioned(
              child: Icon(Icons.chevron_right, color: Colors.black54, size: 30),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            _hasError
                ? 'You only have $_balance tokens available.'
                : 'Each Wheel Token is equivalent to 1 Peso.',
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: _hasError ? Colors.red : Colors.black45,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton() {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isButtonEnabled
                ? gradientColors
                : [Colors.grey.shade400, Colors.grey.shade500],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ElevatedButton(
          onPressed: _isButtonEnabled
              ? () {
                  Navigator.of(context).pushNamed(
                    '/token_confirmation',
                    arguments: _tokenController.text,
                  );
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
          ),
          child: Text(
            'Next',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
