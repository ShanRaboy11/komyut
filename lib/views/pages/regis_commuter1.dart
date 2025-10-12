import 'package:flutter/material.dart';
import '../widgets/text_field.dart'; 
import '../widgets/dropdown.dart'; 
import '../widgets/background_circles.dart'; 
import '../widgets/progress_bar.dart'; 
import '../widgets/option_card.dart'; 
import '../widgets/button.dart'; 
import '../pages/regis_setLogin.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io'; 

class RegistrationCommuterPersonalInfo extends StatefulWidget {
  const RegistrationCommuterPersonalInfo({super.key});

  @override
  State<RegistrationCommuterPersonalInfo> createState() =>
      RegistrationCommuterPersonalInfoState();
}

class RegistrationCommuterPersonalInfoState
    extends State<RegistrationCommuterPersonalInfo> {
  final _formKey = GlobalKey<FormState>(); 

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String? _selectedSex; 
  String? _selectedCategory;
  String? _uploadedFileName;

  final List<ProgressBarStep> _registrationSteps = [
    ProgressBarStep(title: 'Choose Role', isCompleted: true), 
    ProgressBarStep(title: 'Personal Info', isActive: true), 
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
    // Validate form fields first
    bool isFormValid = _formKey.currentState!.validate();
    
    // If form is valid but category is not selected
    if (isFormValid && _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // If category is Discounted but no ID uploaded
    if (isFormValid && _selectedCategory == 'Discounted' && _uploadedFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload proof of ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // If form is invalid (multiple fields empty)
    if (!isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields correctly!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // If everything is valid, navigate
    if (isFormValid && _selectedCategory != null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RegistrationSetLogin()),
      );
    }
  }

  void _onBackPressed() {
    Navigator.of(context).pop();
  }

  // Function to handle image upload
  Future<void> _handleFileUpload() async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _uploadedFileName = result.files.first.name;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ID uploaded: ${result.files.first.name}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Failed to upload image'),
        backgroundColor: Colors.red,
      ),
    );
  }
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
                        'Tell Us About You',
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

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '*All fields required unless noted.',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 15),

                      CustomTextField(
                        labelText: 'First Name',
                        controller: _firstNameController,
                        width: fieldWidth,
                        height: 60, 
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

                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              labelText: 'Age',
                              controller: _ageController,
                              keyboardType: TextInputType.number,
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
                              initialValue: _selectedSex,
                              height: 60,
                              borderColor: const Color.fromRGBO(200, 200, 200, 1),
                              focusedBorderColor: const Color.fromRGBO(185, 69, 170, 1),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Male',
                                  child: Text('Male'),
                                ),
                                DropdownMenuItem(
                                  value: 'Female',
                                  child: Text('Female'),
                                ),
                                DropdownMenuItem(
                                  value: 'Prefer not to say',
                                  child: Text('Prefer not to say'),
                                ),
                              ],
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedSex = newValue;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Select sex';
                                }
                                return null;
                              },
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                color: Color.fromRGBO(185, 69, 170, 1),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

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

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Category *',
                          style: TextStyle(
                            color: Color.fromRGBO(18, 18, 18, 1),
                            fontFamily: 'Manrope',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OptionCard(
                            title: 'Regular',
                            isSelected: _selectedCategory == 'Regular',
                            onTap: () {
                              setState(() {
                                _selectedCategory = 'Regular';
                              });
                            },
                            type: OptionCardType.radio,
                            margin: const EdgeInsets.only(right: 12.0),
                            height: 50,
                            width: 160,
                            textSize: 16,
                            selectedColor: const Color.fromRGBO(185, 69, 170, 1),
                            unselectedColor: const Color.fromRGBO(200, 200, 200, 1),
                          ),
                          OptionCard(
                            title: 'Student, PWD, Senior Citizen',
                            isSelected: _selectedCategory == 'Discounted',
                            onTap: () {
                              setState(() {
                                _selectedCategory = 'Discounted';
                              });
                            },
                            type: OptionCardType.radio,
                            margin: const EdgeInsets.only(left: 12.0),
                            width: 160,
                            height: 50,
                            selectedColor: const Color.fromRGBO(185, 69, 170, 1),
                            unselectedColor: const Color.fromRGBO(200, 200, 200, 1),
                            textSize: 12,
                          ),
                        ],
                      ),
                      const SizedBox(height: 30), 
                      
                      // Conditionally show Upload ID section
                      if (_selectedCategory == 'Discounted') ...[
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Upload Proof of ID *',
                            style: TextStyle(
                              color: Color.fromRGBO(18, 18, 18, 1),
                              fontFamily: 'Manrope',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 150,
                            child: CustomButton(
                              text: 'Upload ID',
                              onPressed: _handleFileUpload,
                              isFilled: true,
                              width: 150,
                              height: 50,
                              borderRadius: 15,
                              textColor: Colors.white,
                              hasShadow: true,
                            ),
                          ),
                        ),
                        if (_uploadedFileName != null) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 16,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'ID uploaded successfully',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 50),
                      ],
                      
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