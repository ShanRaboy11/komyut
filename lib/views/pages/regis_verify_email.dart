import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/background_circles.dart';
import '../widgets/progress_bar.dart';
import '../widgets/button.dart';
import '../providers/registration_provider.dart';

class RegistrationVerifyEmail extends StatefulWidget {
  final String email;
  
  const RegistrationVerifyEmail({
    super.key,
    required this.email,
  });

  @override
  State<RegistrationVerifyEmail> createState() => _RegistrationVerifyEmailState();
}

class _RegistrationVerifyEmailState extends State<RegistrationVerifyEmail>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (index) => FocusNode());

  static const int _resendCooldownSeconds = 60;
  int _remainingSeconds = _resendCooldownSeconds;
  late Ticker _ticker;
  
  bool _isVerifying = false;
  bool _isResending = false;
  bool _emailSent = false;

  final supabase = Supabase.instance.client;

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
      // Send OTP to email using Supabase Auth
      await supabase.auth.signInWithOtp(
        email: widget.email,
        emailRedirectTo: null, // No redirect needed for OTP
      );

      if (mounted) {
        setState(() {
          _emailSent = true;
          _isResending = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code sent to your email!'),
            backgroundColor: Colors.green,
          ),
        );

        _startResendTimer();
      }
    } catch (e) {
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
        await supabase.auth.signInWithOtp(
          email: widget.email,
          emailRedirectTo: null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('New code sent to your email!'),
              backgroundColor: Colors.green,
            ),
          );

          _startResendTimer();
          setState(() {
            _isResending = false;
          });
        }
      } catch (e) {
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
      // Verify OTP with Supabase
      final response = await supabase.auth.verifyOTP(
        email: widget.email,
        token: otp,
        type: OtpType.email,
      );

      if (response.session != null && mounted) {
        // OTP verified successfully, now complete registration
        final registrationProvider = Provider.of<RegistrationProvider>(context, listen: false);
        
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

        if (mounted) {
          setState(() {
            _isVerifying = false;
          });

          if (result['success']) {
            // Registration successful
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account created successfully!'),
                backgroundColor: Colors.green,
              ),
            );

            // Navigate to home/dashboard
            // Replace this with your actual home page
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/home', // or your home route
              (route) => false,
            );
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
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });

        String errorMessage = 'Invalid code. Please try again.';
        if (e.message.contains('expired')) {
          errorMessage = 'Code expired. Please request a new one.';
        } else if (e.message.contains('invalid')) {
          errorMessage = 'Invalid code. Please check and try again.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
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
                                    : const Color.fromRGBO(0, 0, 0, 0.699999988079071),
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