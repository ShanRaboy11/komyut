import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/text_field.dart';
import '../widgets/background_circles.dart';
import '../widgets/progress_bar.dart';
import '../widgets/button.dart';
import '../pages/regis_verify_email.dart';
import '../providers/registration_provider.dart';

class RegistrationSetLogin extends StatefulWidget {
  const RegistrationSetLogin({super.key});

  @override
  State<RegistrationSetLogin> createState() => _RegistrationSetLoginState();
}

class _RegistrationSetLoginState extends State<RegistrationSetLogin> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final List<ProgressBarStep> _registrationSteps = [
    ProgressBarStep(title: 'Choose Role', isCompleted: true),
    ProgressBarStep(title: 'Personal Info', isCompleted: true),
    ProgressBarStep(title: 'Set Login', isActive: true),
    ProgressBarStep(title: 'Verify Email'),
  ];

  @override
  void initState() {
    super.initState();
    // Load previously entered data if exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final registrationProvider = Provider.of<RegistrationProvider>(
        context,
        listen: false,
      );
      final data = registrationProvider.registrationData;

      if (data['email'] != null) {
        _emailController.text = data['email'];
      }
    });
  }

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
      String? firstError;
      int errorCount = 0;

      String? emailError = _emailController.text.isEmpty
          ? 'Email address is required'
          : (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(_emailController.text)
                ? 'Invalid email format. Please use a valid email address'
                : null);

      if (emailError != null) {
        errorCount++;
        firstError ??= emailError;
      }

      String? passwordError = _passwordController.text.isEmpty
          ? 'Password is required'
          : (_passwordController.text.length < 8
                ? 'Password must be at least 8 characters long'
                : null);

      if (passwordError != null) {
        errorCount++;
        firstError ??= passwordError;
      }

      String? confirmPasswordError = _confirmPasswordController.text.isEmpty
          ? 'Please confirm your password'
          : (_confirmPasswordController.text != _passwordController.text
                ? 'Passwords do not match. Please try again'
                : null);

      if (confirmPasswordError != null) {
        errorCount++;
        firstError ??= confirmPasswordError;
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
        SnackBar(content: Text(snackBarMessage), backgroundColor: Colors.red),
      );
      return;
    }

    // Save login info to provider
    final registrationProvider = Provider.of<RegistrationProvider>(
      context,
      listen: false,
    );

    registrationProvider.saveLoginInfo(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    debugPrint('Login info saved: ${registrationProvider.registrationData}');

    // Navigate to verification page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            RegistrationVerifyEmail(email: _emailController.text.trim()),
      ),
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
    final registrationProvider = Provider.of<RegistrationProvider>(context);

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
                      Text(
                        'Secure Your Account',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          color: Color.fromRGBO(18, 18, 18, 1),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Create your login details to keep\nyour account safe.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          color: Color.fromRGBO(0, 0, 0, 0.699999988079071),
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '*All fields required unless noted.',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Email Address
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Email Address *',
                          style: GoogleFonts.manrope(
                            color: Color.fromRGBO(18, 18, 18, 1),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        labelText: '',
                        controller: _emailController,
                        width: fieldWidth,
                        height: 50,
                        borderColor: const Color.fromRGBO(200, 200, 200, 1),
                        focusedBorderColor: const Color.fromRGBO(
                          185,
                          69,
                          170,
                          1,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email address is required';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value)) {
                            return 'Invalid email format';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      // Password
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Password *',
                          style: GoogleFonts.manrope(
                            color: Color.fromRGBO(18, 18, 18, 1),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        labelText: '',
                        controller: _passwordController,
                        width: fieldWidth,
                        height: 50,
                        borderColor: const Color.fromRGBO(200, 200, 200, 1),
                        focusedBorderColor: const Color.fromRGBO(
                          185,
                          69,
                          170,
                          1,
                        ),
                        obscureText: !_isPasswordVisible,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
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
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      // Confirm Password
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Confirm Password *',
                          style: GoogleFonts.manrope(
                            color: Color.fromRGBO(18, 18, 18, 1),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        labelText: '',
                        controller: _confirmPasswordController,
                        width: fieldWidth,
                        height: 50,
                        borderColor: const Color.fromRGBO(200, 200, 200, 1),
                        focusedBorderColor: const Color.fromRGBO(
                          185,
                          69,
                          170,
                          1,
                        ),
                        obscureText: !_isConfirmPasswordVisible,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: const Color.fromRGBO(185, 69, 170, 1),
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 60),

                      // Navigation Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomButton(
                            text: 'Back',
                            onPressed: _onBackPressed,
                            isFilled: false,
                            width: buttonWidth,
                            borderRadius: 15,
                            strokeColor: const Color.fromRGBO(176, 185, 198, 1),
                            outlinedFillColor: Colors.white,
                            textColor: const Color.fromRGBO(176, 185, 198, 1),
                            hasShadow: true,
                          ),
                          const SizedBox(width: 20),
                          Opacity(
                            opacity: registrationProvider.isLoading ? 0.5 : 1.0,
                            child: CustomButton(
                              text: registrationProvider.isLoading
                                  ? 'Saving...'
                                  : 'Next',
                              onPressed: registrationProvider.isLoading
                                  ? () {}
                                  : _onNextPressed,
                              isFilled: true,
                              width: buttonWidth,
                              borderRadius: 15,
                              textColor: Colors.white,
                              hasShadow: true,
                            ),
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
