import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../widgets/background_circles.dart';
import '../widgets/progress_bar.dart';
import '../widgets/button.dart';
import '../pages/success_page.dart';
import '../providers/registration_provider.dart';

class RegistrationVerifyEmail extends StatefulWidget {
  final String email;

  const RegistrationVerifyEmail({super.key, required this.email});

  @override
  State<RegistrationVerifyEmail> createState() =>
      _RegistrationVerifyEmailState();
}

class _RegistrationVerifyEmailState extends State<RegistrationVerifyEmail>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  static const int _resendCooldownSeconds = 60;
  int _remainingSeconds = _resendCooldownSeconds;
  late Ticker _ticker;

  bool _isVerifying = false;
  bool _isResending = false;
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_handleTick);
    _sendInitialOTP();
  }

  // Send initial OTP when page loads
  Future<void> _sendInitialOTP() async {
    setState(() {
      _isResending = true;
    });

    try {
      final registrationProvider = Provider.of<RegistrationProvider>(
        context,
        listen: false,
      );

      debugPrint('📧 Sending OTP to: ${widget.email}');

      // Send OTP without creating account
      final result = await registrationProvider.sendEmailVerificationOTP(
        widget.email,
      );

      if (mounted) {
        setState(() {
          _emailSent = true;
          _isResending = false;
        });

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification code sent to your email!'),
              backgroundColor: Colors.green,
            ),
          );

          _startResendTimer();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to send code'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error sending OTP: $e');

      if (mounted) {
        setState(() {
          _isResending = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send code: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
    _ticker.stop();
    setState(() {
      _remainingSeconds = _resendCooldownSeconds;
    });
    _ticker.start();
  }

  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}s';
  }

  Future<void> _onResendCode() async {
    if (_remainingSeconds == 0 && !_isResending) {
      setState(() {
        _isResending = true;
      });

      try {
        final registrationProvider = Provider.of<RegistrationProvider>(
          context,
          listen: false,
        );

        debugPrint('🔄 Resending OTP to: ${widget.email}');

        final result = await registrationProvider.resendOTP(widget.email);

        if (mounted) {
          if (result['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('New code sent to your email!'),
                backgroundColor: Colors.green,
              ),
            );

            _startResendTimer();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Failed to resend code'),
                backgroundColor: Colors.red,
              ),
            );
          }

          setState(() {
            _isResending = false;
          });
        }
      } catch (e) {
        debugPrint('Error resending OTP: $e');

        if (mounted) {
          setState(() {
            _isResending = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to resend code: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Helper method to get the correct home route based on user role
  String _getHomeRouteForRole(String? userRole) {
    if (userRole == null || userRole.isEmpty) {
      debugPrint('⚠️ User role is null or empty, defaulting to commuter');
      return '/home_commuter';
    }
    
    switch (userRole.toLowerCase()) {
      case 'admin':
        return '/home_admin';
      case 'commuter':
        return '/home_commuter';
      case 'driver':
        return '/home_driver';
      case 'operator':
        return '/home_operator';
      default:
        debugPrint('⚠️ Unknown user role: $userRole, defaulting to commuter');
        return '/home_commuter'; // Default fallback
    }
  }

  Future<void> _onVerifyCode() async {
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

    setState(() {
      _isVerifying = true;
    });

    try {
      final registrationProvider = Provider.of<RegistrationProvider>(
        context,
        listen: false,
      );

      debugPrint('🔍 Verifying OTP: $otp for email: ${widget.email}');

      // Verify OTP and create account
      final verifyResult = await registrationProvider.verifyOTPAndCreateAccount(
        widget.email,
        otp,
      );

      if (!verifyResult['success']) {
        if (mounted) {
          setState(() {
            _isVerifying = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(verifyResult['message'] ?? 'Verification failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      debugPrint('✅ Email verified, creating profile...');

      if (mounted) {
        // Show processing message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified! Creating your account...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Complete the registration (create profile, wallet, etc.)
        final result = await registrationProvider.completeRegistration();

        debugPrint('Registration result: ${result['success']}');

        if (mounted) {
          setState(() {
            _isVerifying = false;
          });

          if (result['success']) {
            // Get role from the registration result instead of database
            final userRole = result['role'] as String?;
            debugPrint('👤 User role from registration: $userRole');

            // Get the appropriate home route based on role
            final homeRoute = _getHomeRouteForRole(userRole);
            debugPrint('🏠 Will navigate to: $homeRoute after showing success');

            // Show the success page and await its auto-close, then navigate
            // using THIS page's context (safer than using the SuccessPage context).
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SuccessPage(
                  title: 'Registration Complete!',
                  subtitle: 'Welcome to komyut',
                ),
              ),
            );

            // After SuccessPage is popped (auto-closed), clear registration
            registrationProvider.clearRegistration();

            if (!mounted) return;

            // Replace current route with role-specific dashboard
            Navigator.pushReplacementNamed(context, homeRoute);
          } else {
            // Registration failed
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Failed to create account'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('General Exception: $e');

      if (mounted) {
        setState(() {
          _isVerifying = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  void _onBackPressed() {
    Navigator.of(context).pop();
  }

  final List<ProgressBarStep> _registrationSteps = [
    ProgressBarStep(title: 'Choose Role', isCompleted: true),
    ProgressBarStep(title: 'Personal Info', isCompleted: true),
    ProgressBarStep(title: 'Set Login', isCompleted: true),
    ProgressBarStep(title: 'Verify Email', isActive: true),
  ];

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double buttonWidth = screenSize.width - (25 * 2);

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
                    Text(
                      'Please enter the code we just sent\nto ${widget.email}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color.fromRGBO(0, 0, 0, 0.699999988079071),
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Loading indicator while sending initial email
                    if (_isResending && !_emailSent) ...[
                      const CircularProgressIndicator(
                        color: Color.fromRGBO(185, 69, 170, 1),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Sending verification code...',
                        style: TextStyle(
                          color: Color.fromRGBO(0, 0, 0, 0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],

                    // OTP Input Fields
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: (screenSize.width - (25 * 2) - (5 * 5)) / 6,
                          child: AspectRatio(
                            aspectRatio: 1,
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
                                counterText: '',
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
                                    _otpFocusNodes[index].unfocus();
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
                      child: _isResending
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color.fromRGBO(185, 69, 170, 1),
                              ),
                            )
                          : Text(
                              _remainingSeconds == 0
                                  ? 'Resend Code'
                                  : 'Resend code in ${_formatDuration(_remainingSeconds)}',
                              style: TextStyle(
                                color: _remainingSeconds == 0
                                    ? const Color.fromRGBO(185, 69, 170, 1)
                                    : const Color.fromRGBO(
                                        0,
                                        0,
                                        0,
                                        0.699999988079071,
                                      ),
                                fontFamily: 'Nunito',
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                    ),
                    const SizedBox(height: 200),

                    // Verify Code Button
                    Opacity(
                      opacity: _isVerifying ? 0.5 : 1.0,
                      child: CustomButton(
                        text: _isVerifying ? 'Verifying...' : 'Verify Code',
                        onPressed: _isVerifying ? () {} : _onVerifyCode,
                        isFilled: true,
                        width: buttonWidth,
                        height: 60,
                        borderRadius: 15,
                        textColor: Colors.white,
                        hasShadow: true,
                      ),
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