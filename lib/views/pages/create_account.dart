import 'package:flutter/material.dart';
import '../widgets/logo.dart';
import '../widgets/button.dart'; 
import '../widgets/big_card.dart'; 
import '../widgets/social_button.dart';
import '../pages/login.dart'; 
import '../pages/registration_role.dart';
import '../pages/qr_scan.dart';

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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegistrationRolePage()),
                            //builder: (context) => const QRScannerScreen()),
                        );
                      },
                        width: screenSize.width * 0.8,
                        height: 60,
                      ),

                      const SizedBox(height: 65),
                      
                       Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.white.withAlpha(100), 
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Text(
                              "Sign up with",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontFamily: 'Manrope',
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.white.withAlpha(100), 
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SocialButton(
                            imagePath: 'assets/images/facebook.png',
                            onPressed: () {
                              // Handle Facebook login
                            },
                          ),
                          const SizedBox(width: 20),
                          SocialButton(
                            imagePath: 'assets/images/google.png',
                            onPressed: () {
                              // Handle Google login
                            },
                          ),
                        ],
                      ),

                      const Spacer(),

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
}
