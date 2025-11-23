import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PersonalInfoCommuterPage extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const PersonalInfoCommuterPage({super.key, required this.profileData});

  @override
  State<PersonalInfoCommuterPage> createState() =>
      _PersonalInfoCommuterPageState();
}

class _PersonalInfoCommuterPageState extends State<PersonalInfoCommuterPage> {
  final _supabase = Supabase.instance.client;
  bool isEditing = false;
  bool isSaving = false;
  final Color primary1 = const Color(0xFF8E4CB6);

  late TextEditingController emailController;
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController ageController;
  late TextEditingController sexController;
  late TextEditingController addressController;
  late TextEditingController categoryController;

  String? attachmentUrl;
  String? commuterCategory;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final profile = widget.profileData;
    final commuter = profile['commuters'] is List
        ? (profile['commuters'] as List).firstOrNull
        : profile['commuters'];

    emailController = TextEditingController(
      text: _supabase.auth.currentUser?.email ?? '',
    );
    firstNameController = TextEditingController(
      text: profile['first_name'] ?? '',
    );
    lastNameController = TextEditingController(
      text: profile['last_name'] ?? '',
    );
    ageController = TextEditingController(
      text: profile['age']?.toString() ?? '',
    );
    sexController = TextEditingController(text: profile['sex'] ?? '');
    addressController = TextEditingController(text: profile['address'] ?? '');

    commuterCategory = commuter?['category'] ?? 'regular';
    categoryController = TextEditingController(
      text: _formatCategory(commuterCategory ?? 'regular'),
    );

    // Get attachment URL if exists
    if (commuter != null && commuter['attachment_id'] != null) {
      _loadAttachment(commuter['attachment_id']);
    }
  }

  String _formatCategory(String category) {
    switch (category) {
      case 'senior':
        return 'Senior Citizen';
      case 'student':
        return 'Student';
      case 'pwd':
        return 'PWD';
      case 'discounted':
        return 'Discounted';
      default:
        return 'Regular';
    }
  }

  Future<void> _loadAttachment(String attachmentId) async {
    try {
      final response = await _supabase
          .from('attachments')
          .select('url')
          .eq('id', attachmentId)
          .single();

      if (mounted) {
        setState(() {
          attachmentUrl = response['url'];
        });
      }
    } catch (e) {
      debugPrint('Error loading attachment: $e');
    }
  }

  Future<void> _saveChanges() async {
    setState(() => isSaving = true);

    try {
      final profileId = widget.profileData['id'];

      // Update profile
      await _supabase
          .from('profiles')
          .update({
            'first_name': firstNameController.text.trim(),
            'last_name': lastNameController.text.trim(),
            'age': int.tryParse(ageController.text.trim()),
            'sex': sexController.text.trim(),
            'address': addressController.text.trim(),
          })
          .eq('id', profileId);

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
    ageController.dispose();
    sexController.dispose();
    addressController.dispose();
    categoryController.dispose();
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
                            fontSize: 18,
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

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel("Age"),
                                _buildTextField(
                                  ageController,
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel("Sex"),
                                _buildTextField(sexController),
                              ],
                            ),
                          ),
                        ],
                      ),

                      _buildLabel("Full Address"),
                      _buildTextField(addressController),

                      _buildLabel("Category"),
                      _buildTextField(categoryController, readOnly: true),

                      // Only show ID section for non-regular commuters
                      if (commuterCategory != null &&
                          commuterCategory != 'regular') ...[
                        _buildLabel("ID"),
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color.fromARGB(255, 161, 165, 170),
                            ),
                            color: Colors.grey[200],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: attachmentUrl != null
                                ? Image.network(
                                    attachmentUrl!,
                                    fit: BoxFit.cover,
                                    height: 200,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          {
                                            return Container(
                                              height: 200,
                                              alignment: Alignment.center,
                                              child: CircularProgressIndicator(
                                                color: primary1,
                                              ),
                                            );
                                          }
                                        },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 200,
                                        alignment: Alignment.center,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.error_outline, size: 48),
                                            SizedBox(height: 8),
                                            Text('Failed to load image'),
                                          ],
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    height: 200,
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.image_not_supported,
                                          size: 48,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'No ID uploaded',
                                          style: GoogleFonts.nunito(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                      ],
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
          fontSize: 14,
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
      style: GoogleFonts.nunito(fontSize: 12, color: Colors.black87),
    );
  }
}
