import 'package:flutter/material.dart';
//import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/button.dart';

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
                      fontSize: 45,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7B3CBF),
                    ),
                  ),
                  const SizedBox(height: 30),

                Image.asset(
                    "assets/images/Vector.png", 
                    height: 160,
                  ),

                 Image.asset(
                    "assets/images/komyut.png", 
                    height: 115.77,
                  ),

                  const SizedBox(height: 60),
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
