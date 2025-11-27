import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PersonalInfoOperatorPage extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const PersonalInfoOperatorPage({super.key, required this.profileData});

  @override
  State<PersonalInfoOperatorPage> createState() =>
      _PersonalInfoOperatorPageState();
}

class _PersonalInfoOperatorPageState extends State<PersonalInfoOperatorPage> {
  final _supabase = Supabase.instance.client;
  bool isEditing = false;
  bool isSaving = false;
  final Color primary1 = const Color(0xFF8E4CB6);

  late TextEditingController emailController;
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController companyController;
  late TextEditingController companyAddressController;
  late TextEditingController contactEmailController;
  late TextEditingController contactPhoneController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final profile = widget.profileData;
    final operator = profile['operators'] is List
        ? (profile['operators'] as List).firstOrNull
        : profile['operators'];

    emailController = TextEditingController(
      text: _supabase.auth.currentUser?.email ?? '',
    );
    firstNameController = TextEditingController(
      text: profile['first_name'] ?? '',
    );
    lastNameController = TextEditingController(
      text: profile['last_name'] ?? '',
    );

    // Operator specific fields
    if (operator != null) {
      companyController = TextEditingController(
        text: operator['company_name'] ?? '',
      );
      companyAddressController = TextEditingController(
        text: operator['company_address'] ?? '',
      );
      contactEmailController = TextEditingController(
        text: operator['contact_email'] ?? '',
      );
      contactPhoneController = TextEditingController(
        text: operator['contact_phone'] ?? '',
      );
    } else {
      companyController = TextEditingController();
      companyAddressController = TextEditingController();
      contactEmailController = TextEditingController();
      contactPhoneController = TextEditingController();
    }
  }

  Future<void> _saveChanges() async {
    setState(() => isSaving = true);

    try {
      final profileId = widget.profileData['id'];
      final operator = widget.profileData['operators'] is List
          ? (widget.profileData['operators'] as List).firstOrNull
          : widget.profileData['operators'];

      // Update profile
      await _supabase
          .from('profiles')
          .update({
            'first_name': firstNameController.text.trim(),
            'last_name': lastNameController.text.trim(),
          })
          .eq('id', profileId);

      // Update operator specific info
      if (operator != null) {
        await _supabase
            .from('operators')
            .update({
              'company_name': companyController.text.trim(),
              'company_address': companyAddressController.text.trim(),
              'contact_email': contactEmailController.text.trim(),
              'contact_phone': contactPhoneController.text.trim(),
            })
            .eq('id', operator['id']);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          isEditing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    companyController.dispose();
    companyAddressController.dispose();
    contactEmailController.dispose();
    contactPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width * 0.07;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF8F4FF), Color(0xFFF7F4FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 20,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.black87,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          "Personal Info",
                          style: GoogleFonts.manrope(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    if (!isEditing)
                      IconButton(
                        onPressed: () => setState(() => isEditing = true),
                        icon: Icon(Icons.edit_outlined, color: primary1),
                      )
                    else
                      IconButton(
                        onPressed: isSaving ? null : _saveChanges,
                        icon: isSaving
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: primary1,
                                ),
                              )
                            : Icon(Icons.check, color: primary1),
                      ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Email Address"),
                      _buildTextField(emailController, readOnly: true),

                      _buildLabel("First Name"),
                      _buildTextField(firstNameController),

                      _buildLabel("Last Name"),
                      _buildTextField(lastNameController),

                      _buildLabel("Company/Business Name"),
                      _buildTextField(companyController),

                      _buildLabel("Company Address"),
                      _buildTextField(companyAddressController),

                      _buildLabel("Contact Email"),
                      _buildTextField(
                        contactEmailController,
                        keyboardType: TextInputType.emailAddress,
                      ),

                      _buildLabel("Contact Phone"),
                      _buildTextField(
                        contactPhoneController,
                        keyboardType: TextInputType.phone,
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontWeight: FontWeight.w600,
          fontSize: 14.5,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, {
    bool readOnly = false,
    TextInputType? keyboardType,
  }) {
    final effectiveReadOnly = readOnly || !isEditing;

    return TextField(
      controller: controller,
      readOnly: effectiveReadOnly,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        filled: true,
        fillColor: effectiveReadOnly ? Colors.transparent : Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 161, 165, 170),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary1, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 12,
        ),
      ),
      style: GoogleFonts.nunito(fontSize: 15, color: Colors.black87),
    );
  }
}
