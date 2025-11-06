import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import 'commuter_app.dart';

class DwPaymentMethodPage extends StatefulWidget {
  final String name;
  final String email;
  final String amount;

  const DwPaymentMethodPage({
    super.key,
    required this.name,
    required this.email,
    required this.amount,
  });

  @override
  State<DwPaymentMethodPage> createState() => _DwPaymentMethodPageState();
}

class _DwPaymentMethodPageState extends State<DwPaymentMethodPage> {
  String? _selectedMethod;

  final Color _brandColor = const Color(0xFF8E4CB6);
  final gradientColors = const [
    Color(0xFFB945AA),
    Color(0xFF8E4CB6),
    Color(0xFF5B53C2),
  ];

  @override
  void initState() {
    super.initState();
    // Fetch the user profile to get the ID for display
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WalletProvider>(context, listen: false).fetchUserProfile();
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
            const SizedBox(height: 30),
            Consumer<WalletProvider>(
              builder: (context, provider, child) {
                if (provider.isProfileLoading && provider.userProfile == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                final userId =
                    provider.userProfile?['user_id']?.toString() ?? 'N/A';

                return _buildDetailsCard(userId);
              },
            ),
            const SizedBox(height: 20),
            _buildPaymentMethodCard(),
            const SizedBox(height: 30),
            _buildPayButton(),
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
          'Digital Wallet',
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

  Widget _buildStepIndicator() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset('assets/images/step3.png', width: 40, height: 40),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Step 2',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Review details and select a payment method. Click PAY to continue.',
                style: GoogleFonts.nunito(fontSize: 15, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard(String userId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _brandColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          _buildDetailRow('User ID:', userId),
          _buildDetailRow('Name:', widget.name),
          _buildDetailRow('Email Address:', widget.email),
          _buildDetailRow(
            'Amount:',
            double.parse(widget.amount).toStringAsFixed(2),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    String displayedValue = value;

    if (label.toLowerCase().contains('email') && value.contains('@')) {
      final parts = value.split('@');
      if (parts[0].length > 12) {
        displayedValue = '${parts[0].substring(0, 9)}...@${parts[1]}';
      }
    } else if (label.toLowerCase().contains('name') && value.length > 28) {
      displayedValue = '${value.substring(0, 28)}...';
    } else if (label.toLowerCase() == 'user id:' && value.length > 18) {
      displayedValue = '${value.substring(0, 18)}...';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(fontSize: 15, color: Colors.grey[600]),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              displayedValue,
              textAlign: TextAlign.end,
              softWrap: false,
              overflow: TextOverflow.fade,
              maxLines: 1,
              style: GoogleFonts.manrope(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _brandColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(
            'Payment Method',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Divider(color: _brandColor.withValues(alpha: 0.5), height: 24),
          const SizedBox(height: 10),
          _buildPaymentOption('Online Banking'),
          const SizedBox(height: 12),
          _buildPaymentOption('E-Wallet'),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String title) {
    bool isSelected = _selectedMethod == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = title;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: isSelected
            ? BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
                borderRadius: BorderRadius.circular(12),
              )
            : BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _brandColor),
              ),
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : _brandColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPayButton() {
    bool isEnabled = _selectedMethod != null;
    return Center(
      child: OutlinedButton(
        onPressed: isEnabled
            ? () {
                CommuterApp.navigatorKey.currentState?.pushNamed(
                  '/dw_payment_source',
                  arguments: {
                    'name': widget.name,
                    'email': widget.email,
                    'amount': widget.amount,
                    'paymentMethod': _selectedMethod!,
                  },
                );
              }
            : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: isEnabled ? _brandColor : Colors.grey,
          backgroundColor: isEnabled
              ? _brandColor.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          side: BorderSide(
            color: isEnabled ? _brandColor : Colors.grey.withValues(alpha: 0.5),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 14),
        ),
        child: Text(
          'Pay',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
