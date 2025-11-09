import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/button.dart';
import '../widgets/logo.dart';
import 'create_account.dart';
import 'login.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              top: 672,
              left: -94,
              child: Image.asset("assets/images/Ellipse 2.png"),
            ),
            Positioned(
              top: 672,
              left: -94,
              child: Image.asset("assets/images/Ellipse 2.png"),
            ),
            Positioned(
              top: 454,
              left: -293,
              child: Image.asset("assets/images/Ellipse 4.png"),
            ),
            Positioned(
              top: 454,
              left: -293,
              child: Image.asset("assets/images/Ellipse 4.png"),
            ),
            Positioned(
              top: 454,
              left: -293,
              child: Image.asset("assets/images/Ellipse 5.png"),
            ),
            Positioned(
              top: 454,
              left: -293,
              child: Image.asset("assets/images/Ellipse 5.png"),
            ),

            Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildWelcomeText(),
                    const SizedBox(height: 80),

                    const Logo(),

                    const SizedBox(height: 120),
                    CustomButton(
                      text: "Create Account",
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreateAccountPage(),
                          ),
                        );
                      },
                      isFilled: true,
                      textColor: Colors.white,
                    ),

                    const SizedBox(height: 20),
                    CustomButton(
                      text: "Log In",
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      isFilled: false,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    const gradient = LinearGradient(
      colors: [Color(0xFFB945AA), Color(0xFF8E4CB6), Color(0xFF5B53C2)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(
        "Welcome",
        style: GoogleFonts.manrope(
          fontSize: 50,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
