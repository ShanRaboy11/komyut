import 'package:flutter/material.dart';
import '../widgets/logo.dart';
import '../widgets/button.dart'; 
import '../widgets/big_card.dart'; 
import '../pages/login.dart'; 

class CreateAccountPage extends StatelessWidget {
  const CreateAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Back',
          style: TextStyle(color: Colors.black),
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
              top: screenSize.height * 0.13,
              left: 0,
              right: 0,
              child: Center(
                child: Logo(
                  vectorWidth: screenSize.width * 0.8,
                  vectorHeight: screenSize.height * 0.22,
                ),
              ),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: screenSize.height * 0.57, 
              child: BigCard( 
                child: Padding( 
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 65.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "Create your Account",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Manrope',
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "We're here to help you reach the peaks\nof every ride. Are you ready?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Manrope',
                          color: Colors.white.withAlpha(204),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 30),

                      CustomButton(
                        text: "Get Started",
                        isFilled: true,
                        fillColor: Colors.white,
                        onPressed: () {

                        },
                        width: screenSize.width * 0.8,
                        height: 60,
                      ),

                      const SizedBox(height: 30),
                      const Text(
                        "Sign up with",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontFamily: 'Manrope',
                        ),
                      ),
                      const SizedBox(height: 15),

                      // --- Social Login Buttons (Facebook & Google) ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSocialButton(context, 'assets/images/facebook.png'),
                          const SizedBox(width: 20),
                          _buildSocialButton(context, 'assets/images/google.png'),
                        ],
                      ),

                      const Spacer(),

                      // --- "Already have an account?" text with "Log In" link ---
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                          );
                        },
                        child: RichText(
                          text: TextSpan(
                            text: "Already have an account? ",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withAlpha(204),
                              fontFamily: 'Manrope',
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
          ],
        ),
      ),
    );
  }

  // Helper Widget for Social Buttons (can remain here or be moved to a shared utility)
  Widget _buildSocialButton(BuildContext context, String imagePath) {
    return GestureDetector(
      onTap: () {
        
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Image.asset(
            imagePath,
            width: 30,
            height: 30,
          ),
        ),
      ),
    );
  }
}