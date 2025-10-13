import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/background_circles.dart'; 
import '../widgets/progress_bar.dart';
import '../widgets/option_card.dart'; 
import '../widgets/button.dart'; 
import '../pages/regis_commuter1.dart';
import '../providers/registration_provider.dart';

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
  void initState() {
    super.initState();
    // Load previously selected role if exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final registrationProvider = Provider.of<RegistrationProvider>(context, listen: false);
      final savedRole = registrationProvider.getField('role');
      if (savedRole != null) {
        setState(() {
          _selectedRole = savedRole.substring(0, 1).toUpperCase() + savedRole.substring(1);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final registrationProvider = Provider.of<RegistrationProvider>(context);

    void onNextPressed() {
      if (_selectedRole != null) {
        // Save role to provider
        registrationProvider.saveRole(_selectedRole!);
        
        debugPrint('Selected Role: $_selectedRole');
        debugPrint('Registration Data: ${registrationProvider.registrationData}');
        
        // Navigate to next page
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const RegistrationCommuterPersonalInfo(),
          ),
        );
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

                  OptionCard(
                    title: 'Commuter',
                    isSelected: _selectedRole == 'Commuter',
                    height: 60,
                    onTap: () {
                      setState(() {
                        _selectedRole = 'Commuter';
                      });
                    },
                    type: OptionCardType.radio,
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
                    type: OptionCardType.radio,
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
                    type: OptionCardType.radio,
                  ),

                  const Spacer(),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 60.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomButton(
                          text: 'Back',
                          onPressed: onBackPressed,
                          isFilled: false,
                          width: buttonWidth,
                          height: 50,
                          borderRadius: 15,
                          strokeColor: const Color.fromRGBO(176, 185, 198, 1),
                          outlinedFillColor: Colors.white,
                          textColor: const Color.fromRGBO(176, 185, 198, 1),
                          hasShadow: true,
                        ),
                        const SizedBox(width: 20),
                        CustomButton(
                          text: registrationProvider.isLoading ? 'Loading...' : 'Next',
                          onPressed: registrationProvider.isLoading ? () {} : onNextPressed,
                          isFilled: true,
                          width: buttonWidth,
                          height: 50,
                          borderRadius: 15,
                          textColor: Colors.white,
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