import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/logo.dart';
import '../widgets/button.dart';
import '../widgets/big_card.dart';
import 'login.dart';
import 'registration_role.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  double _sheetHeight = 0;
  double _sheetOpacity = 0;
  double _logoOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenSize = MediaQuery.of(context).size; // ✅ FIXED
      setState(() {
        _sheetHeight = screenSize.height * 0.49;
        _sheetOpacity = 1.0; // ✅ Now valid
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _logoOpacity = 1.0; // fade in logo
      });
    });
  }

  void _collapseSheet() {
    setState(() {
      _sheetHeight = 0;
      _sheetOpacity = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: AnimatedOpacity(
          opacity: _logoOpacity,
          duration: const Duration(milliseconds: 2000),
          curve: Curves.easeOut,
          child: IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: Colors.black),
            onPressed: () async {
              _collapseSheet();

              await Future.delayed(const Duration(milliseconds: 200));

              if (!context.mounted) return;

              Navigator.of(context).pop();
            },
          ),
        ),
        title: AnimatedOpacity(
          opacity: _logoOpacity,
          duration: const Duration(milliseconds: 2000),
          curve: Curves.easeOut,
          child: Text(
            'Back',
            style: GoogleFonts.nunito(color: Colors.black, fontSize: 16),
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFDFDFF), Color(0xFFF1F0FA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 39,
              left: 172,
              child: Image.asset("assets/images/Ellipse 1.png"),
            ),
            Positioned(
              top: 39,
              left: 172,
              child: Image.asset("assets/images/Ellipse 1.png"),
            ),
            Positioned(
              top: -134,
              left: 22,
              child: Image.asset("assets/images/Ellipse 3.png"),
            ),
            Positioned(
              top: -134,
              left: 22,
              child: Image.asset("assets/images/Ellipse 3.png"),
            ),
            Positioned(
              top: screenSize.height * 0.20,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _sheetOpacity,
                  duration: const Duration(milliseconds: 2000),
                  curve: Curves.easeOut,
                  child: Logo(
                    vectorWidth: screenSize.width * 0.8,
                    vectorHeight: screenSize.height * 0.22,
                  ),
                ),
              ),
            ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              bottom: 0,
              left: 0,
              right: 0,
              height: _sheetHeight,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 600),
                opacity: _sheetHeight == 0 ? 0 : 1,
                curve: Curves.easeOutCubic,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  decoration: const ShapeDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(0.50, 0.00),
                      end: Alignment(0.50, 1.00),
                      colors: [
                        Color(0xFFB945AA),
                        Color(0xFF8E4CB6),
                        Color(0xFF5B53C2),
                      ],
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(60),
                        topRight: Radius.circular(60),
                      ),
                    ),
                  ),
                  child: BigCard(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 65.0,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Create your Account",
                              style: GoogleFonts.manrope(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  color: Colors.white.withAlpha(204),
                                  height: 1.5,
                                ),
                                children: const <TextSpan>[
                                  TextSpan(
                                    text:
                                        "We're here to help you reach the peaks\nof every ride. ",
                                  ),
                                  TextSpan(
                                    text: 'Are you ready?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 30),

                            CustomButton(
                              text: "Get Started",
                              isFilled: true,
                              fillColor: Colors.white,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const RegistrationRolePage(),
                                  ),
                                );
                              },
                              width: screenSize.width * 0.8,
                              height: 45,
                              fontSize: 16,
                            ),

                            const SizedBox(height: 40),

                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginPage(),
                                  ),
                                );
                              },
                              child: RichText(
                                text: TextSpan(
                                  text: "Already have an account? ",
                                  style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    color: Colors.white.withAlpha(204),
                                  ),
                                  children: const [
                                    TextSpan(
                                      text: "Log In",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
