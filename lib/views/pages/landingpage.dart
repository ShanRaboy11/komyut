import 'package:flutter/material.dart';
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
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Manrope',
                      color: Color(0xFF7B3CBF),
                    ),
                  ),
                  const SizedBox(height: 80),

                  Container(
                    width: MediaQuery.of(
                      context,
                    ).size.width, // Take full width or a specific width
                    height:
                        160 +
                        115.77 -
                        70, // Adjust '70' for desired overlap. (Vector height + Komyut height - overlap)
                    // For example, if you want 70px of overlap, set it to 70.
                    alignment: Alignment
                        .center, // Center the stack's content if it's smaller than the container
                    child: Stack(
                      alignment:
                          Alignment.center, // Center children in the stack
                      children: [
                        // Vector.png (base image)
                        // Positioned without specific 'top', 'bottom' to allow alignment to center/default
                        // or positioned explicitly from the top of the Stack's available space.
                        Positioned(
                          top: -20, // Align to the top of the Container/Stack
                          child: Image.asset(
                            "assets/images/Vector.png",
                            height: 200,
                            width: 250,
                            // width: ... (optional, can also be wrapped in SizedBox for exact width)
                          ),
                        ),

                        // Komyut.png (overlapping image)
                        Positioned(
                          // Calculate 'top' based on Vector.png's height and desired overlap.
                          // If Vector.png is 160px high, and you want Komyut.png to start
                          // 100px down from the top of the stack (meaning 60px overlap):
                          top:
                              160 -
                              45, // 160 (Vector height) - 60 (desired overlap) = 100
                          // Adjust '60' to change overlap. A higher value means less overlap.
                          child: Image.asset(
                            "assets/images/komyut.png",
                            height: 130.77,
                            // width: ... (optional)
                          ),
                        ),
                      ],
                    ),
                  ),

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
