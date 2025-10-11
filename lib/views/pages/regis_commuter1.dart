// lib/features/registration/pages/registration_personal_info_page.dart
import 'package:flutter/material.dart';
import '../widgets/text_field.dart'; // Adjust path if necessary
import '../widgets/dropdown.dart'; // Adjust path if necessary
import '../widgets/background_circles.dart'; // Adjust path if necessary
import '../widgets/progress_bar.dart'; // Adjust path if necessary
import '../widgets/option_card.dart'; // Adjust path as option_card.dart is general
import '../widgets/button.dart'; // Adjust path as button.dart (CustomButton) is general


class RegistrationCommuterPersonalInfo extends StatefulWidget {
  const RegistrationCommuterPersonalInfo({super.key});

  @override
  State<RegistrationCommuterPersonalInfo> createState() => RegistrationCommuterPersonalInfoState();
}

class RegistrationCommuterPersonalInfoState extends State<RegistrationCommuterPersonalInfo> {
  final _formKey = GlobalKey<FormState>(); // Key for form validation

  // Text Editing Controllers for input fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String? _selectedSex; // For dropdown
  String? _selectedCategory; // For OptionCard selection

  // Define steps for the progress bar
  final List<ProgressBarStep> _registrationSteps = [
    ProgressBarStep(title: 'Choose Role', isCompleted: true), // Now completed
    ProgressBarStep(title: 'Personal Info', isActive: true), // Current step
    ProgressBarStep(title: 'Set Login'),
    ProgressBarStep(title: 'Verify Email'),
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onNextPressed() {
    if (_formKey.currentState!.validate()) {
      // All fields are valid, process the data
      print('First Name: ${_firstNameController.text}');
      print('Last Name: ${_lastNameController.text}');
      print('Age: ${_ageController.text}');
      print('Sex: $_selectedSex');
      print('Full Address: ${_addressController.text}');
      print('Category: $_selectedCategory');

      // TODO: Navigate to the next registration step (Set Login)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Personal Info Submitted!')),
      );
      // Example navigation:
      // Navigator.of(context).push(MaterialPageRoute(builder: (_) => RegistrationSetLoginPage()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields correctly!')),
      );
    }
  }

  void _onBackPressed() {
    Navigator.of(context).pop(); // Go back to the previous screen (Choose Role)
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double buttonWidth = (screenSize.width - (25 * 2) - 20) / 2;
    final double fieldWidth = screenSize.width - (25 * 2); // Full width minus horizontal padding

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
              child: SingleChildScrollView( // Use SingleChildScrollView for scrollable content
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 50),
                      Align(
                        alignment: Alignment.center,
                        child: ProgressBar(steps: _registrationSteps),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'Tell Us About You',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color.fromRGBO(18, 18, 18, 1),
                          fontFamily: 'Manrope',
                          fontSize: 28,
                          fontWeight: FontWeight.normal,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Provide some basic details so we \ncan set up your account.',
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
                      const Text(
                        '*All fields required unless noted.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 15),

                      // First Name
                      CustomTextField(
                        labelText: 'First Name',
                        controller: _firstNameController,
                        width: fieldWidth,
                        height: 60, // Example height
                        borderColor: const Color.fromRGBO(200, 200, 200, 1),
                        focusedBorderColor: const Color.fromRGBO(185, 69, 170, 1),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your first name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      // Last Name
                      CustomTextField(
                        labelText: 'Last Name',
                        controller: _lastNameController,
                        width: fieldWidth,
                        height: 60,
                        borderColor: const Color.fromRGBO(200, 200, 200, 1),
                        focusedBorderColor: const Color.fromRGBO(185, 69, 170, 1),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your last name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      // Age and Sex in a Row
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              labelText: 'Age',
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              width: (fieldWidth - 15) / 2, // Half width minus spacing
                              height: 60,
                              borderColor: const Color.fromRGBO(200, 200, 200, 1),
                              focusedBorderColor: const Color.fromRGBO(185, 69, 170, 1),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter age';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Invalid age';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: CustomDropdownField<String>(
                              labelText: 'Sex',
                              value: _selectedSex,
                              width: (fieldWidth - 15) / 2, // Half width minus spacing
                              height: 60,
                              borderColor: const Color.fromRGBO(200, 200, 200, 1),
                              focusedBorderColor: const Color.fromRGBO(185, 69, 170, 1),
                              items: const [
                                DropdownMenuItem(value: 'Male', child: Text('Male')),
                                DropdownMenuItem(value: 'Female', child: Text('Female')),
                                DropdownMenuItem(value: 'Prefer not to say', child: Text('Prefer not to say')),
                              ],
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedSex = newValue;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Select sex';
                                }
                                return null;
                              },
                              icon: const Icon(Icons.keyboard_arrow_down, color: Color.fromRGBO(185, 69, 170, 1)), // Custom icon color
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      // Full Address
                      CustomTextField(
                        labelText: 'Full Address',
                        controller: _addressController,
                        width: fieldWidth,
                        height: 60,
                        borderColor: const Color.fromRGBO(200, 200, 200, 1),
                        focusedBorderColor: const Color.fromRGBO(185, 69, 170, 1),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 25),

                      // Category
                      const Text(
                        'Category *',
                        style: TextStyle(
                          color: Color.fromRGBO(18, 18, 18, 1),
                          fontFamily: 'Manrope',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      OptionCard(
                        title: 'Regular',
                        isSelected: _selectedCategory == 'Regular',
                        onTap: () {
                          setState(() {
                            _selectedCategory = 'Regular';
                          });
                        },
                        type: OptionCardType.radio,
                        width: fieldWidth, // Match width of other fields
                        height: 60,
                        selectedColor: const Color.fromRGBO(185, 69, 170, 1),
                        unselectedColor: const Color.fromRGBO(200, 200, 200, 1),
                      ),
                      OptionCard(
                        title: 'Student, PWD, Senior Citizen',
                        isSelected: _selectedCategory == 'Discounted', // You might want a different internal value
                        onTap: () {
                          setState(() {
                            _selectedCategory = 'Discounted'; // Or 'StudentPWDSC'
                          });
                        },
                        type: OptionCardType.radio,
                        width: fieldWidth,
                        height: 60,
                        selectedColor: const Color.fromRGBO(185, 69, 170, 1),
                        unselectedColor: const Color.fromRGBO(200, 200, 200, 1),
                      ),
                      const SizedBox(height: 30), // Space before buttons

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
                      const SizedBox(height: 30), // Extra space at the bottom for scrolling
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