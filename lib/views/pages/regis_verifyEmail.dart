import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter/scheduler.dart'; 
import '../widgets/background_circles.dart';
import '../widgets/progress_bar.dart';
import '../widgets/button.dart';
// import 'dashboard_page.dart';

class RegistrationVerifyEmail extends StatefulWidget {
  const RegistrationVerifyEmail({super.key});

  @override
  State<RegistrationVerifyEmail> createState() => _RegistrationVerifyEmailState();
}

// Add SingleTickerProviderStateMixin here
class _RegistrationVerifyEmailState extends State<RegistrationVerifyEmail>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (index) => FocusNode());

  // Timer for resend code
  static const int _resendCooldownSeconds = 180; 
  int _remainingSeconds = _resendCooldownSeconds;
  late Ticker _ticker; 

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_handleTick);
    _startResendTimer();
  }

  void _handleTick(Duration elapsed) {
    if (!mounted) return; 
    setState(() {
      _remainingSeconds = _resendCooldownSeconds - elapsed.inSeconds;
      if (_remainingSeconds <= 0) {
        _ticker.stop();
        _remainingSeconds = 0; 
      }
    });
  }

  void _startResendTimer() {
    // Calling stop() is safe even if the ticker is not animating.
    // This ensures any previous timer is stopped before starting a new one.
    _ticker.stop();
    _ticker.start();
  }

  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}s';
  }

  void _onResendCode() {
    if (_remainingSeconds == 0) {
      // Logic to resend the code (e.g., API call)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resending code...')),
      );
      // Reset and restart the timer
      _remainingSeconds = _resendCooldownSeconds;
      _startResendTimer();
    }
  }

  void _onVerifyCode() {
    String otp = _otpControllers.map((controller) => controller.text).join();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete 6-digit code.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // TODO: Implement your actual code verification logic (e.g., API call)
    // For demonstration:
    if (otp == "123456") { // Replace with actual verification
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code verified successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      // TODO: Navigate to the next page after successful verification
      // Navigator.of(context).pushReplacement(
      //   MaterialPageRoute(builder: (_) => DashboardPage()),
      // );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid code. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onBackPressed() {
    Navigator.of(context).pop();
  }

  // Define steps for the progress bar
  final List<ProgressBarStep> _registrationSteps = [
    ProgressBarStep(title: 'Choose Role', isCompleted: true),
    ProgressBarStep(title: 'Personal Info', isCompleted: true),
    ProgressBarStep(title: 'Set Login', isCompleted: true),
    ProgressBarStep(title: 'Verify Email', isActive: true), // Current step
  ];

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    _ticker.dispose(); // Dispose the ticker
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double buttonWidth = screenSize.width - (25 * 2); // Full width for single button

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
            const BackgroundCircles(),
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    ProgressBar(steps: _registrationSteps),
                    const SizedBox(height: 30),
                    const Text(
                      'We sent you a code',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color.fromRGBO(18, 18, 18, 1),
                        fontFamily: 'Manrope',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Please enter the code we just sent\nto your email.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color.fromRGBO(0, 0, 0, 0.699999988079071),
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // OTP Input Fields
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: (screenSize.width - (25 * 2) - (5 * 5)) / 6, 
                          child: AspectRatio(
                            aspectRatio: 1, // Make boxes square
                            child: TextField(
                              controller: _otpControllers[index],
                              focusNode: _otpFocusNodes[index],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(1),
                              ],
                              decoration: InputDecoration(
                                counterText: '', // Hide default character counter
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFCED4DA),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color.fromRGBO(185, 69, 170, 1),
                                    width: 2,
                                  ),
                                ),
                                fillColor: Colors.white,
                                filled: true,
                              ),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color.fromRGBO(185, 69, 170, 1),
                              ),
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  if (index < _otpControllers.length - 1) {
                                    _otpFocusNodes[index + 1].requestFocus();
                                  } else {
                                    _otpFocusNodes[index].unfocus(); // Last field, unfocus
                                  }
                                } else if (value.isEmpty) {
                                  if (index > 0) {
                                    _otpFocusNodes[index - 1].requestFocus();
                                  }
                                }
                              },
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 30),

                    // Resend Code
                    GestureDetector(
                      onTap: _onResendCode,
                      child: Text(
                        _remainingSeconds == 0
                            ? 'Resend Code' // Text changes when timer is 0
                            : 'Resend code in ${_formatDuration(_remainingSeconds)}',
                        style: TextStyle(
                          color: _remainingSeconds == 0
                              ? const Color.fromRGBO(185, 69, 170, 1) // Active color
                              : const Color.fromRGBO(0, 0, 0, 0.699999988079071), // Disabled color
                          fontFamily: 'Nunito', // Corrected to Nunito based on image text style
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 270), // Spacer before buttons

                    // Verify Code Button
                    CustomButton(
                      text: 'Verify Code',
                      onPressed: _onVerifyCode,
                      isFilled: true,
                      width: buttonWidth,
                      height: 60,
                      borderRadius: 15,
                      textColor: Colors.white,
                      hasShadow: true,
                    ),
                    const SizedBox(height: 20),

                    // Back Button
                    CustomButton(
                      text: 'Back',
                      onPressed: _onBackPressed,
                      isFilled: false,
                      width: buttonWidth,
                      height: 60,
                      borderRadius: 15,
                      strokeColor: const Color.fromRGBO(176, 185, 198, 1),
                      outlinedFillColor: Colors.white,
                      textColor: const Color.fromRGBO(176, 185, 198, 1),
                      hasShadow: true,
                    ),
                    const SizedBox(height: 30),
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