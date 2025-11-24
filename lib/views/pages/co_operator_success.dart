import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/button.dart';
import 'operator_app.dart';

class OperatorCashOutSuccessPage extends StatefulWidget {
  const OperatorCashOutSuccessPage({super.key});

  @override
  State<OperatorCashOutSuccessPage> createState() =>
      _OperatorCashOutSuccessPageState();
}

class _OperatorCashOutSuccessPageState extends State<OperatorCashOutSuccessPage>
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
              'Withdrawal Successful!',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 18, // Matched Driver style
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 100),
            _buildHomeButton(context),
            const SizedBox(height: 10), // Matched Driver style
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
        OperatorApp.navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );
      },
      isFilled: true,
      textColor: Colors.white,
    );
  }

  Widget _buildWalletButton(BuildContext context) {
    return CustomButton(
      text: "Wallet",
      onPressed: () {
        OperatorApp.navigatorKey.currentState?.popUntil(
          ModalRoute.withName('/'),
        );
      },
      isFilled: false,
    );
  }
}
