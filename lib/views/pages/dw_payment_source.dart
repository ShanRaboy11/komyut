import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';

class DwSourceSelectionPage extends StatefulWidget {
  final String name;
  final String email;
  final String amount;
  final String paymentMethod;

  const DwSourceSelectionPage({
    super.key,
    required this.name,
    required this.email,
    required this.amount,
    required this.paymentMethod,
  });

  @override
  State<DwSourceSelectionPage> createState() => _DwSourceSelectionPageState();
}

class _DwSourceSelectionPageState extends State<DwSourceSelectionPage> {
  String? _selectedSource;
  bool _agreeToTerms = false;

  final Color _brandColor = const Color(0xFF8E4CB6);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WalletProvider>(
        context,
        listen: false,
      ).fetchPaymentSources(widget.paymentMethod);
    });
  }

  Future<void> _sendInstructions() async {
    // Guard clause to prevent execution if conditions aren't met
    if (_selectedSource == null || !_agreeToTerms) return;

    // Use the provider from context, but don't listen to rebuilds here
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);

    final double amountValue = double.tryParse(widget.amount) ?? 0.0;
    const double serviceFee = 10.00;
    final double totalValue = amountValue + serviceFee;

    try {
      // Call the provider method to send instructions to the backend
      await walletProvider.sendPaymentInstructions(
        name: widget.name,
        email: widget.email,
        amount: totalValue,
        source: _selectedSource!,
      );

      // If the above line completes without error, navigate to the confirmation page
      if (mounted) {
        // Check if the widget is still in the tree
        Navigator.of(context).pushNamed(
          '/dw_confirmation',
          arguments: {
            'name': widget.name,
            'email': widget.email,
            'amount': widget.amount,
            'source': _selectedSource!,
          },
        );
      }
    } catch (e) {
      // If an error occurs, show a SnackBar with the error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double amountValue = double.tryParse(widget.amount) ?? 0.0;
    const double serviceFee = 10.00;
    final double totalValue = amountValue + serviceFee;
    final currencyFormat = NumberFormat.currency(
      locale: 'en_PH',
      symbol: 'PHP',
    );

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
                if (provider.isSourcesLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.sourcesErrorMessage != null) {
                  return Center(child: Text(provider.sourcesErrorMessage!));
                }
                // Pass the fetched data to the build method
                return _buildSourceCard(
                  totalValue,
                  currencyFormat,
                  provider.paymentSources,
                );
              },
            ),
            const SizedBox(height: 30),
            _buildSendButton(),
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
        Image.asset('assets/images/step4.png', width: 40, height: 40),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Step 3',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select your payment source. Deposit instructions will be emailed to the address you provided.',
                style: GoogleFonts.nunito(fontSize: 15, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSourceCard(
    double totalValue,
    NumberFormat currencyFormat,
    List<String> sources,
  ) {
    String descriptionText = '';
    if (_selectedSource != null) {
      if (widget.paymentMethod == 'E-Wallet') {
        descriptionText =
            'Pay manually using the $_selectedSource app. Instructions will be emailed. A surcharge may be applied.';
      } else if (widget.paymentMethod == 'Online Banking') {
        descriptionText =
            'Pay manually via $_selectedSource online. Instructions will be emailed.';
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _brandColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: GoogleFonts.nunito(fontSize: 15, color: Colors.black87),
              children: [
                const TextSpan(text: 'komyut is requesting for '),
                TextSpan(
                  text: currencyFormat.format(totalValue),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: ' (Service Fee of PHP10.00).'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Source',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSource,
                      hint: Text(
                        'Select payment source',
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      isExpanded: true,
                      icon: Icon(Icons.keyboard_arrow_down, color: _brandColor),
                      items: sources.map((String source) {
                        return DropdownMenuItem<String>(
                          value: source,
                          child: Text(
                            source,
                            style: GoogleFonts.manrope(fontSize: 15),
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedSource = newValue;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            descriptionText,
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 10),
          CheckboxListTile(
            value: _agreeToTerms,
            onChanged: (newValue) {
              setState(() {
                _agreeToTerms = newValue ?? false;
              });
            },
            title: Transform.translate(
              offset: const Offset(-8, 0),
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                  children: [
                    const TextSpan(text: 'I agree to the '),
                    TextSpan(
                      text: 'Terms and Conditions',
                      style: TextStyle(
                        color: _brandColor,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          // handle terms tap
                        },
                    ),
                  ],
                ),
              ),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: _brandColor,
            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    // We now use a Consumer to listen to the provider's loading state
    return Consumer<WalletProvider>(
      builder: (context, provider, child) {
        // Button is enabled if not loading, terms are agreed, and a source is selected
        bool isEnabled =
            !provider.isSendingInstructions &&
            _agreeToTerms &&
            _selectedSource != null;

        return Center(
          child: OutlinedButton(
            // Use our new _sendInstructions method
            onPressed: isEnabled ? _sendInstructions : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: isEnabled ? _brandColor : Colors.grey,
              backgroundColor: isEnabled
                  ? _brandColor.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              side: BorderSide(
                color: isEnabled
                    ? _brandColor
                    : Colors.grey.withValues(alpha: 0.5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
            ),
            child: provider.isSendingInstructions
                // Show a loading indicator when sending
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(_brandColor),
                    ),
                  )
                // Show the text otherwise
                : Text(
                    'Send Instructions',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        );
      },
    );
  }
}
