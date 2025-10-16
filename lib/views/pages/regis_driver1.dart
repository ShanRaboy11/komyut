import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../widgets/text_field.dart'; 
import '../widgets/dropdown.dart'; 
import '../widgets/background_circles.dart'; 
import '../widgets/progress_bar.dart'; 
import '../widgets/button.dart'; 
import '../pages/regis_set_login.dart';
import '../providers/registration_provider.dart';
import 'package:file_picker/file_picker.dart';

class RegistrationDriverPersonalInfo extends StatefulWidget {
  const RegistrationDriverPersonalInfo({super.key});

  @override
  State<RegistrationDriverPersonalInfo> createState() =>
      RegistrationDriverPersonalInfoState();
}

class RegistrationDriverPersonalInfoState
    extends State<RegistrationDriverPersonalInfo> {
  final _formKey = GlobalKey<FormState>(); 

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _licenseNumberController = TextEditingController();
  final TextEditingController _assignedOperatorController = TextEditingController();

  String? _selectedSex; 
  String? _uploadedLicenseFileName;
  File? _driverLicenseFile;

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
      final registrationProvider = Provider.of<RegistrationProvider>(context, listen: false);
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
      if (data['license_number'] != null) {
        _licenseNumberController.text = data['license_number'];
      }
      if (data['assigned_operator'] != null) {
        _assignedOperatorController.text = data['assigned_operator'];
      }
      if (data['driver_license_path'] != null) {
        setState(() {
          _uploadedLicenseFileName = data['driver_license_path'].split('/').last;
          _driverLicenseFile = File(data['driver_license_path']);
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
    _licenseNumberController.dispose();
    _assignedOperatorController.dispose();
    super.dispose();
  }

  void _onNextPressed() {
    bool isFormValid = _formKey.currentState!.validate();
    
    if (isFormValid && _driverLicenseFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload your driver license'),
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

    if (isFormValid) {
      final registrationProvider = Provider.of<RegistrationProvider>(context, listen: false);
      
      registrationProvider.saveDriverPersonalInfo(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        sex: _selectedSex!,
        address: _addressController.text.trim(),
        licenseNumber: _licenseNumberController.text.trim(),
        assignedOperator: _assignedOperatorController.text.trim().isEmpty 
            ? null 
            : _assignedOperatorController.text.trim(),
        driverLicenseFile: _driverLicenseFile!,
      ).then((success) {
        if (success && mounted) {
          debugPrint('Driver personal info saved: ${registrationProvider.registrationData}');
          
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RegistrationSetLogin()),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(registrationProvider.errorMessage ?? 'Failed to save information'),
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

  Future<void> _handleLicenseUpload() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (!mounted) return;

      if (result != null && result.files.isNotEmpty) {
        final PlatformFile file = result.files.first;
        
        setState(() {
          _uploadedLicenseFileName = file.name;
          _driverLicenseFile = File(file.path!);
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
                                final age = int.tryParse(value);
                                if (age == null) {
                                  return 'Invalid age';
                                }
                                if (age < 18 || age > 120) {
                                  return 'Age must be 18-120';
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
                      const SizedBox(height: 15),

                      CustomTextField(
                        labelText: 'Assigned Operator (optional)',
                        controller: _assignedOperatorController,
                        width: fieldWidth,
                        height: 60,
                        borderColor: const Color.fromRGBO(200, 200, 200, 1),
                        focusedBorderColor: const Color.fromRGBO(185, 69, 170, 1),
                      ),
                      const SizedBox(height: 15),

                      CustomTextField(
                        labelText: 'Driver\'s License Number',
                        controller: _licenseNumberController,
                        width: fieldWidth,
                        height: 60,
                        borderColor: const Color.fromRGBO(200, 200, 200, 1),
                        focusedBorderColor: const Color.fromRGBO(185, 69, 170, 1),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your license number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Upload Driver License *',
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
                            text: 'Upload License',
                            onPressed: _handleLicenseUpload,
                            isFilled: true,
                            width: 150,
                            height: 50,
                            borderRadius: 15,
                            textColor: Colors.white,
                            hasShadow: true,
                          ),
                        ),
                      ),
                      if (_uploadedLicenseFileName != null) ...[
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
                                'License uploaded successfully',
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
                      const SizedBox(height: 40),                    
                      
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
                            text: registrationProvider.isLoading ? 'Saving...' : 'Next',
                            onPressed: registrationProvider.isLoading ? () {} : _onNextPressed,
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