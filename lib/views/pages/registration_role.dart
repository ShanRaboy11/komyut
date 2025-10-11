import 'package:flutter/material.dart';
import '../widgets/background_circles.dart'; 
import '../widgets/progress_bar.dart';
import '../widgets/option_card.dart'; 
import '../widgets/button.dart'; 
import '../pages/regis_commuter1.dart';

class RegistrationRolePage extends StatefulWidget {
  const RegistrationRolePage({super.key});

  @override
  State<RegistrationRolePage> createState() => _RegistrationRolePageState();
}

class _RegistrationRolePageState extends State<RegistrationRolePage> {
  String? _selectedRole;

  final List<ProgressBarStep> _registrationSteps = [
    ProgressBarStep(title: 'Choose Role', isActive: true), 
    ProgressBarStep(title: 'Personal Info'),
    ProgressBarStep(title: 'Set Login'),
    ProgressBarStep(title: 'Verify Email'),
  ];

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    void onNextPressed() {
      if (_selectedRole != null) {
        print('Selected Role: $_selectedRole');
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => RegistrationCommuterPersonalInfo()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a role!')),
        );
      }
    }

    void onBackPressed() {
      Navigator.of(context).pop(); 
    }

    final double buttonWidth = (screenSize.width - (25 * 2) - 20) / 2;


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
              child: Column(
                children: [
                  const SizedBox(height: 50), 
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: ProgressBar(steps: _registrationSteps),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Page Title
                  const Text(
                    'Choose Role',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color.fromRGBO(18, 18, 18, 1),
                      fontFamily: 'Manrope',
                      fontSize: 28,
                      letterSpacing: 0,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Page Description
                  const Text(
                    'Select how you’ll be using komyut. \nThis helps us tailor the experience for you.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color.fromRGBO(0, 0, 0, 0.699999988079071),
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      letterSpacing: 0,
                      fontWeight: FontWeight.normal,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Role Option Cards (using the general OptionCard)
                  OptionCard(
                    title: 'Commuter',
                    isSelected: _selectedRole == 'Commuter',
                    height: 60,
                    onTap: () {
                      setState(() {
                        _selectedRole = 'Commuter';
                      });
                    },
                    type: OptionCardType.radio, // Explicitly set to radio type
                  ),
                  OptionCard(
                    title: 'Driver',
                    isSelected: _selectedRole == 'Driver',
                    height: 60,
                    onTap: () {
                      setState(() {
                        _selectedRole = 'Driver';
                      });
                    },
                    type: OptionCardType.radio, // Explicitly set to radio type
                  ),
                  OptionCard(
                    title: 'Operator',
                    isSelected: _selectedRole == 'Operator',
                    height: 60,
                    onTap: () {
                      setState(() {
                        _selectedRole = 'Operator';
                      });
                    },
                    type: OptionCardType.radio, // Explicitly set to radio type
                  ),

                  const Spacer(), // Pushes content upwards, leaving space for buttons at bottom

                  // Navigation Buttons (using CustomButton for both)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 60.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back Button
                        CustomButton(
                          text: 'Back',
                          onPressed: onBackPressed,
                          isFilled: false, // Outlined style
                          width: buttonWidth,
                          height: 50,
                          borderRadius: 15,
                          strokeColor: const Color.fromRGBO(176, 185, 198, 1), // Grey border
                          outlinedFillColor: Colors.white, // White fill for outlined
                          textColor: const Color.fromRGBO(176, 185, 198, 1), // Grey text
                          hasShadow: true,
                        ),
                        const SizedBox(width: 20), // Space between buttons
                        // Next Button
                        CustomButton(
                          text: 'Next',
                          onPressed: onNextPressed,
                          isFilled: true, // Filled with gradient
                          width: buttonWidth,
                          height: 50,
                          borderRadius: 15,
                          textColor: Colors.white, // White text
                          hasShadow: true,
                        ),
                      ],
                    ),
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