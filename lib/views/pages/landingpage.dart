import 'package:flutter/material.dart';
import '../widgets/button.dart';
import '../widgets/logo.dart';
import '../pages/create_account.dart';
// import '../pages/login.dart';
import '../pages/home_commuter.dart';

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
            // Your Positioned background elements
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

            // Foreground content wrapped in SingleChildScrollView
            Center(
              child: SingleChildScrollView(
                // Added SingleChildScrollView here
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
                            // builder: (context) => const LoginPage(),
                            builder: (context) => const CommuterDashboardNav(),
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
}
