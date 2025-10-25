import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class OverTheCounterPage extends StatefulWidget {
  const OverTheCounterPage({super.key});

  @override
  State<OverTheCounterPage> createState() => _OverTheCounterPageState();
}

class _OverTheCounterPageState extends State<OverTheCounterPage> {
  final TextEditingController _amountController = TextEditingController(
    text: "0",
  );
  bool _isButtonEnabled = false;

  final Color _brandColor = const Color(0xFF8E4CB6);

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() {
      final text = _amountController.text;
      final isEnabled =
          text.isNotEmpty &&
          double.tryParse(text) != null &&
          double.parse(text) > 0;
      if (isEnabled != _isButtonEnabled) {
        setState(() {
          _isButtonEnabled = isEnabled;
        });
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
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
        Divider(color: _brandColor, thickness: 1),
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
    // We use a Stack to place an invisible TextField over the display text.
    // This gives us full control over the text style while getting native text input.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _brandColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: _brandColor.withOpacity(0.1),
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
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          Divider(color: _brandColor.withOpacity(0.5), height: 20),
          const SizedBox(height: 10),
          Text(
            'PHP',
            style: GoogleFonts.manrope(
              fontSize: 18,
              color: Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(
            height: 80, // To contain the large text and avoid layout shifts
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Display Text that updates
                Text(
                  _amountController.text.isEmpty ? "0" : _amountController.text,
                  style: GoogleFonts.manrope(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                // Invisible TextField
                TextField(
                  controller: _amountController,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  autofocus: true,
                  cursorColor: _brandColor,
                  style: const TextStyle(
                    color: Colors.transparent,
                  ), // Hide the actual text
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    fillColor: Colors.transparent,
                    filled: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
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
                // TODO: Implement navigation to the next step
                print(
                  'Next button pressed with amount: ${_amountController.text}',
                );
              }
            : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: _isButtonEnabled ? _brandColor : Colors.grey,
          backgroundColor: _isButtonEnabled
              ? _brandColor.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          side: BorderSide(
            color: _isButtonEnabled
                ? _brandColor
                : Colors.grey.withOpacity(0.5),
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
