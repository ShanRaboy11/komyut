import 'package:flutter/material.dart';
import '../widgets/text_field.dart';
import '../widgets/background_circles.dart';
import '../widgets/progress_bar.dart';
import '../widgets/button.dart';
import '../pages/regis_verifyEmail.dart';

class RegistrationSetLogin extends StatefulWidget {
  const RegistrationSetLogin({super.key});

  @override
  State<RegistrationSetLogin> createState() => _RegistrationSetLoginState();
}

class _RegistrationSetLoginState extends State<RegistrationSetLogin> {
  final _formKey = GlobalKey<FormState>();

  // Text Editing Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Password visibility toggles
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Define steps for the progress bar
  final List<ProgressBarStep> _registrationSteps = [
    ProgressBarStep(title: 'Choose Role', isCompleted: true),
    ProgressBarStep(title: 'Personal Info', isCompleted: true),
    ProgressBarStep(title: 'Set Login', isActive: true), // Current step
    ProgressBarStep(title: 'Verify Email'),
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onNextPressed() {
    bool formIsValid = _formKey.currentState!.validate();

    if (!formIsValid) {
      // If the form is not valid, we need to determine the SnackBar message.
      String? firstError;
      int errorCount = 0;

      // Manually check each validator to count errors and find the first one.
      // We're essentially re-running the validation logic here to get the messages.
      String? emailError = _emailController.text.isEmpty
          ? 'Email address is required'
          : (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text)
              ? 'Invalid email format. Please use a valid email address'
              : null);

      if (emailError != null) {
        errorCount++;
        if (firstError == null) firstError = emailError;
      }

      String? passwordError = _passwordController.text.isEmpty
          ? 'Password is required'
          : (_passwordController.text.length < 8
              ? 'Password must be at least 8 characters long'
              : null);

      if (passwordError != null) {
        errorCount++;
        if (firstError == null) firstError = passwordError;
      }

      String? confirmPasswordError = _confirmPasswordController.text.isEmpty
          ? 'Please confirm your password'
          : (_confirmPasswordController.text != _passwordController.text
              ? 'Passwords do not match. Please try again'
              : null);

      if (confirmPasswordError != null) {
        errorCount++;
        if (firstError == null) firstError = confirmPasswordError;
      }

      String snackBarMessage;
      if (errorCount > 1) { 
        snackBarMessage = 'Please fill in all required fields correctly!';
      } else if (firstError != null) {
        snackBarMessage = firstError;
      } else {
        snackBarMessage = 'Please fill in all required fields correctly!';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(snackBarMessage),
          backgroundColor: Colors.red,
        ),
      );
      return; 
    }

    Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => RegistrationVerifyEmail()),
    );
  }

  void _onBackPressed() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double buttonWidth = (screenSize.width - (25 * 2) - 20) / 2;
    final double fieldWidth = screenSize.width - (25 * 2);

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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 50),
                      ProgressBar(steps: _registrationSteps),
                      const SizedBox(height: 30),
                      const Text(
                        'Secure Your Account',
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
                        'Create your login details to keep\nyour account safe.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color.fromRGBO(0, 0, 0, 0.699999988079071),
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '*All fields required unless noted.',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Email Address
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Email Address *',
                          style: TextStyle(
                            color: Color.fromRGBO(18, 18, 18, 1),
                            fontFamily: 'Manrope',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        labelText: '',
                        controller: _emailController,
                        width: fieldWidth,
                        height: 60,
                        borderColor: const Color.fromRGBO(200, 200, 200, 1),
                        focusedBorderColor: const Color.fromRGBO(185, 69, 170, 1),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email address is required';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return 'Invalid email format. Please use a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      // Password
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Password *',
                          style: TextStyle(
                            color: Color.fromRGBO(18, 18, 18, 1),
                            fontFamily: 'Manrope',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        labelText: '',
                        controller: _passwordController,
                        width: fieldWidth,
                        height: 60,
                        borderColor: const Color.fromRGBO(200, 200, 200, 1),
                        focusedBorderColor: const Color.fromRGBO(185, 69, 170, 1),
                        obscureText: !_isPasswordVisible,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: const Color.fromRGBO(185, 69, 170, 1),
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          if (value.length < 8) {
                            return 'Password must be at least 8 characters long';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      // Confirm Password
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Confirm Password *',
                          style: TextStyle(
                            color: Color.fromRGBO(18, 18, 18, 1),
                            fontFamily: 'Manrope',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        labelText: '',
                        controller: _confirmPasswordController,
                        width: fieldWidth,
                        height: 60,
                        borderColor: const Color.fromRGBO(200, 200, 200, 1),
                        focusedBorderColor: const Color.fromRGBO(185, 69, 170, 1),
                        obscureText: !_isConfirmPasswordVisible,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: const Color.fromRGBO(185, 69, 170, 1),
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match. Please try again';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 120), // Extra space before buttons

                      // Navigation Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
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
                          const SizedBox(width: 20),
                          CustomButton(
                            text: 'Next',
                            onPressed: _onNextPressed,
                            isFilled: true,
                            width: buttonWidth,
                            height: 60,
                            borderRadius: 15,
                            textColor: Colors.white,
                            hasShadow: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
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