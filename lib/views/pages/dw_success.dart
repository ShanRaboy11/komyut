import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/button.dart';

class DwSuccessPage extends StatefulWidget {
  const DwSuccessPage({super.key});

  @override
  State<DwSuccessPage> createState() => _DwSuccessPageState();
}

class _DwSuccessPageState extends State<DwSuccessPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _glowAnimation = Tween<double>(begin: 0.55, end: 0.75).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 130),
            _buildSuccessIcon(),
            const SizedBox(height: 32),
            Text(
              'Payment Processing',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your payment will be confirmed and your wallet balance updated within 3-5 business days.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 120),
            _buildHomeButton(context),
            const SizedBox(height: 24),
            _buildWalletButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Center(
      child: SizedBox(
        width: 180,
        height: 180,
        child: AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFF5B53C2,
                    ).withValues(alpha: _glowAnimation.value),
                    blurRadius: 30,
                    spreadRadius: 4,
                    offset: Offset.zero,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Image.asset('assets/images/gradient_check.png'),
        ),
      ),
    );
  }

  Widget _buildHomeButton(BuildContext context) {
    return CustomButton(
      text: "Home",
      onPressed: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      isFilled: true,
      textColor: Colors.white,
    );
  }

  Widget _buildWalletButton(BuildContext context) {
    return CustomButton(
      text: "Wallet",
      onPressed: () {
        Navigator.of(
          context,
        ).popUntil((route) => route.settings.name == '/wallet');
      },
      isFilled: false,
    );
  }
}
