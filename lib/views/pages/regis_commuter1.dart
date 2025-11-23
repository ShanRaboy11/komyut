import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../widgets/text_field.dart';
import '../widgets/dropdown.dart';
import '../widgets/background_circles.dart';
import '../widgets/progress_bar.dart';
import '../widgets/option_card.dart';
import '../widgets/button.dart';
import '../pages/regis_set_login.dart';
import '../providers/registration_provider.dart';
import 'package:file_picker/file_picker.dart';

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
  File? _idProofFile;

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
      if (data['age'] != null) {
        _ageController.text = data['age'].toString();
      }
      if (data['sex'] != null) {
        setState(() {
          _selectedSex = data['sex'];
        });
      }
      if (data['address'] != null) {
        _addressController.text = data['address'];
      }
      if (data['category'] != null) {
        setState(() {
          // Capitalize first letter for display
          final cat = data['category'].toString();
          _selectedCategory = cat == 'regular' ? 'regular' : 'Discounted';
        });
      }
      if (data['id_proof_path'] != null) {
        setState(() {
          _uploadedFileName = data['id_proof_path'].split('/').last;
          _idProofFile = File(data['id_proof_path']);
        });
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onNextPressed() {
    bool isFormValid = _formKey.currentState!.validate();

    if (isFormValid && _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (isFormValid &&
        _selectedCategory == 'Discounted' &&
        _idProofFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload proof of ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields correctly!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (isFormValid && _selectedCategory != null) {
      final registrationProvider = Provider.of<RegistrationProvider>(
        context,
        listen: false,
      );

      // Save synchronously (the provider method handles async internally)
      registrationProvider
          .savePersonalInfo(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            age: int.parse(_ageController.text.trim()),
            sex: _selectedSex!,
            address: _addressController.text.trim(),
            category: _selectedCategory!,
            idProofFile: _idProofFile,
          )
          .then((success) {
            if (success && mounted) {
              debugPrint(
                'Personal info saved: ${registrationProvider.registrationData}',
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

  Future<void> _handleFileUpload() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (!mounted) return;

      if (result != null && result.files.isNotEmpty) {
        final PlatformFile file = result.files.first;

        setState(() {
          _uploadedFileName = file.name;
          _idProofFile = File(file.path!);
        });

        if (!mounted) return;
      }
    } catch (e) {
      if (!mounted) return;
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
                            fontSize: 11,
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

                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              labelText: 'Age',
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              height: 50,
                              borderColor: const Color.fromRGBO(
                                200,
                                200,
                                200,
                                1,
                              ),
                              focusedBorderColor: const Color.fromRGBO(
                                185,
                                69,
                                170,
                                1,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter age';
                                }
                                final age = int.tryParse(value);
                                if (age == null) {
                                  return 'Invalid age';
                                }
                                if (age < 13 || age > 120) {
                                  return 'Age must be 13-120';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 15),
                          Flexible(
                            child: CustomDropdownField<String>(
                              labelText: 'Sex',
                              initialValue: _selectedSex,
                              height: 50,
                              borderColor: const Color.fromRGBO(
                                200,
                                200,
                                200,
                                1,
                              ),
                              focusedBorderColor: const Color.fromRGBO(
                                185,
                                69,
                                170,
                                1,
                              ),
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
                            return 'Please enter your address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Category *',
                          style: GoogleFonts.manrope(
                            color: Color.fromRGBO(18, 18, 18, 1),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: OptionCard(
                              title: 'Regular',
                              isSelected: _selectedCategory == 'regular',
                              onTap: () {
                                setState(() {
                                  _selectedCategory = 'regular';
                                  _idProofFile = null;
                                  _uploadedFileName = null;
                                });
                              },
                              type: OptionCardType.radio,
                              margin: const EdgeInsets.only(right: 5.0),
                              height: 45,
                              width: 160,
                              textSize: 14,
                              selectedColor: const Color.fromRGBO(
                                185,
                                69,
                                170,
                                1,
                              ),
                              unselectedColor: const Color.fromRGBO(
                                200,
                                200,
                                200,
                                1,
                              ),
                            ),
                          ),
                          Expanded(
                            child: OptionCard(
                              title: 'Student, PWD, Senior Citizen',
                              isSelected: _selectedCategory == 'Discounted',
                              onTap: () {
                                setState(() {
                                  _selectedCategory = 'Discounted';
                                });
                              },
                              type: OptionCardType.radio,
                              margin: const EdgeInsets.only(left: 5.0),
                              width: 160,
                              height: 50,
                              selectedColor: const Color.fromRGBO(
                                185,
                                69,
                                170,
                                1,
                              ),
                              unselectedColor: const Color.fromRGBO(
                                200,
                                200,
                                200,
                                1,
                              ),
                              textSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      if (_selectedCategory == 'Discounted') ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Upload Proof of ID *',
                            style: GoogleFonts.manrope(
                              color: Color.fromRGBO(18, 18, 18, 1),
                              fontSize: 15,
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
                              height: 45,
                              borderRadius: 15,
                              textColor: Colors.white,
                              hasShadow: true,
                              fontSize: 14,
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
                                  style: GoogleFonts.nunito(
                                    color: Colors.green,
                                    fontSize: 12,
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
