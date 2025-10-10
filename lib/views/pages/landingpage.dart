import 'package:flutter/material.dart';
import '../widgets/button.dart';
import '../widgets/logo.dart';

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

            // Foreground content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Welcome",
                    style: TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Manrope',
                      color: Color(0xFF7B3CBF),
                    ),
                  ),
                  const SizedBox(height: 80),

                  const Logo(),

                  const SizedBox(height: 120),
                  CustomButton(
                    text: "Create Account",
                    onPressed: () {},
                    isFilled: true,
                  ),

                  const SizedBox(height: 20),
                  CustomButton(
                    text: "Log In",
                    onPressed: () {},
                    isFilled: false,
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
