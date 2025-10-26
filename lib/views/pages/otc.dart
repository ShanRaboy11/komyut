import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class OverTheCounterPage extends StatefulWidget {
  const OverTheCounterPage({super.key});

  @override
  State<OverTheCounterPage> createState() => _OverTheCounterPageState();
}

class _OverTheCounterPageState extends State<OverTheCounterPage> {
  // Start with an empty controller. We will display "0" in the UI as a fallback.
  final TextEditingController _amountController = TextEditingController();
  bool _isButtonEnabled = false;

  final Color _brandColor = const Color(0xFF8E4CB6);

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged(String value) {
    // This logic runs every time the text field's value changes.
    // It's much faster than a listener and prevents flickering.
    setState(() {
      final isEnabled =
          value.isNotEmpty &&
          int.tryParse(value) != null &&
          int.parse(value) > 0;
      _isButtonEnabled = isEnabled;
    });
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
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/wallet');
          },
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
            const SizedBox(height: 40),
            _buildStepIndicator(),
            const SizedBox(height: 40),
            _buildAmountCard(),
            const SizedBox(height: 40),
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
          'Over-the-Counter',
          style: GoogleFonts.manrope(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Divider(color: _brandColor.withOpacity(0.5), thickness: 1),
      ],
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
                'Input the amount you want to load into your komyut wallet below.',
                style: GoogleFonts.nunito(fontSize: 15, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
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
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          Divider(color: _brandColor.withValues(alpha: 0.5), height: 20),
          const SizedBox(height: 6),

          Text(
            'PHP',
            style: GoogleFonts.manrope(
              fontSize: 18,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 1),
          SizedBox(
            width: double.infinity,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  _amountController.text.isEmpty ? "0" : _amountController.text,
                  style: GoogleFonts.manrope(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextField(
                  controller: _amountController,
                  onChanged: _onAmountChanged,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  showCursor: false,
                  style: const TextStyle(color: Colors.transparent),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    fillColor: Colors.transparent,
                    filled: true,
                    isCollapsed: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
          Text(
            'A PHP 5.00 fee will be charged per transaction.',
            style: GoogleFonts.nunito(fontSize: 13, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return Center(
      child: OutlinedButton(
        onPressed: _isButtonEnabled
            ? () {
                Navigator.of(context).pushNamed(
                  '/otc_confirmation',
                  arguments: _amountController.text,
                );
              }
            : null,
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
