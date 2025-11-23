import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/text_field.dart';
import '../widgets/background_circles.dart';
import '../widgets/progress_bar.dart';
import '../widgets/button.dart';
import '../pages/regis_set_login.dart';
import '../providers/registration_provider.dart';

class RegistrationOperatorPersonalInfo extends StatefulWidget {
  const RegistrationOperatorPersonalInfo({super.key});

  @override
  State<RegistrationOperatorPersonalInfo> createState() =>
      RegistrationOperatorPersonalInfoState();
}

class RegistrationOperatorPersonalInfoState
    extends State<RegistrationOperatorPersonalInfo> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _companyAddressController =
      TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();

  final List<ProgressBarStep> _registrationSteps = [
    ProgressBarStep(title: 'Choose Role', isCompleted: true),
    ProgressBarStep(title: 'Personal Info', isActive: true),
    ProgressBarStep(title: 'Set Login'),
    ProgressBarStep(title: 'Verify Email'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final registrationProvider = Provider.of<RegistrationProvider>(
        context,
        listen: false,
      );
      final data = registrationProvider.registrationData;

      if (data['first_name'] != null) {
        _firstNameController.text = data['first_name'];
      }
      if (data['last_name'] != null) {
        _lastNameController.text = data['last_name'];
      }
      if (data['company_name'] != null) {
        _companyNameController.text = data['company_name'];
      }
      if (data['company_address'] != null) {
        _companyAddressController.text = data['company_address'];
      }
      if (data['contact_email'] != null) {
        _contactEmailController.text = data['contact_email'];
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _contactEmailController.dispose();
    super.dispose();
  }

  void _onNextPressed() {
    bool isFormValid = _formKey.currentState!.validate();

    if (!isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields correctly!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (isFormValid) {
      final registrationProvider = Provider.of<RegistrationProvider>(
        context,
        listen: false,
      );

      registrationProvider
          .saveOperatorPersonalInfo(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            companyName: _companyNameController.text.trim(),
            companyAddress: _companyAddressController.text.trim(),
            contactEmail: _contactEmailController.text.trim(),
          )
          .then((success) {
            if (success && mounted) {
              debugPrint(
                'Operator personal info saved: ${registrationProvider.registrationData}',
              );

              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RegistrationSetLogin()),
              );
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    registrationProvider.errorMessage ??
                        'Failed to save information',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          });
    }
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
                        'Tell Us About You',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          color: Color.fromRGBO(18, 18, 18, 1),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Provide some basic details so we \ncan set up your account.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          color: Color.fromRGBO(0, 0, 0, 0.699999988079071),
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '*All fields required unless noted.',
                          style: GoogleFonts.nunito(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      CustomTextField(
                        labelText: 'First Name',
                        controller: _firstNameController,
                        width: fieldWidth,
                        height: 50,
                        borderColor: const Color.fromRGBO(200, 200, 200, 1),
                        focusedBorderColor: const Color.fromRGBO(
                          185,
                          69,
                          170,
                          1,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your first name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      CustomTextField(
                        labelText: 'Last Name',
                        controller: _lastNameController,
                        width: fieldWidth,
                        height: 50,
                        borderColor: const Color.fromRGBO(200, 200, 200, 1),
                        focusedBorderColor: const Color.fromRGBO(
                          185,
                          69,
                          170,
                          1,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your last name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      CustomTextField(
                        labelText: 'Company/Business Name',
                        controller: _companyNameController,
                        width: fieldWidth,
                        height: 50,
                        borderColor: const Color.fromRGBO(200, 200, 200, 1),
                        focusedBorderColor: const Color.fromRGBO(
                          185,
                          69,
                          170,
                          1,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter company/business name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      CustomTextField(
                        labelText: 'Company Full Address',
                        controller: _companyAddressController,
                        width: fieldWidth,
                        height: 50,
                        borderColor: const Color.fromRGBO(200, 200, 200, 1),
                        focusedBorderColor: const Color.fromRGBO(
                          185,
                          69,
                          170,
                          1,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter company address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      CustomTextField(
                        labelText: 'Contact Email',
                        controller: _contactEmailController,
                        width: fieldWidth,
                        height: 50,
                        keyboardType: TextInputType.emailAddress,
                        borderColor: const Color.fromRGBO(200, 200, 200, 1),
                        focusedBorderColor: const Color.fromRGBO(
                          185,
                          69,
                          170,
                          1,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter contact email';
                          }
                          // Basic email validation
                          final emailRegex = RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          );
                          if (!emailRegex.hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),

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
                          CustomButton(
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
