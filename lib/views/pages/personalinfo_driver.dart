import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PersonalInfoDriverPage extends StatefulWidget {
  final Map<String, dynamic> profileData;
  
  const PersonalInfoDriverPage({
    super.key,
    required this.profileData,
  });

  @override
  State<PersonalInfoDriverPage> createState() => _PersonalInfoDriverPageState();
}

class _PersonalInfoDriverPageState extends State<PersonalInfoDriverPage> {
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
  late TextEditingController operatorController;
  late TextEditingController licenseIdController;
  late TextEditingController plateNumberController;
  late TextEditingController routeCodeController;
  late TextEditingController puvTypeController; // ✨ NEW
  
  String? licenseImageUrl;
  String? puvType; // ✨ NEW - Store actual value

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final profile = widget.profileData;
    final driver = profile['drivers'] is List 
        ? (profile['drivers'] as List).firstOrNull 
        : profile['drivers'];
    
    // Debug log to check driver data
    debugPrint('Driver data: $driver');
    if (driver != null) {
      debugPrint('Vehicle plate: ${driver['vehicle_plate']}');
      debugPrint('Route code field: ${driver['route_code']}');
      debugPrint('Routes object: ${driver['routes']}');
    }
    
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
    sexController = TextEditingController(
      text: profile['sex'] ?? '',
    );
    addressController = TextEditingController(
      text: profile['address'] ?? '',
    );
    
    // Driver specific fields
    if (driver != null) {
      licenseIdController = TextEditingController(
        text: driver['license_number'] ?? '',
      );
      
      plateNumberController = TextEditingController(
        text: driver['vehicle_plate'] ?? '',
      );
      
      // Get route code from the routes relationship (via route_id)
      String routeCode = '';
      if (driver['routes'] != null && driver['routes'] is Map) {
        routeCode = driver['routes']['code'] ?? '';
      }
      // Fallback to direct route_code field if routes relationship is not available
      if (routeCode.isEmpty) {
        routeCode = driver['route_code'] ?? '';
      }
      
      routeCodeController = TextEditingController(text: routeCode);
      
      // ✨ NEW: Get PUV type
      puvType = driver['puv_type'] ?? 'traditional';
      String puvTypeDisplay = puvType == 'modern' ? 'Modern' : 'Traditional';
      puvTypeController = TextEditingController(text: puvTypeDisplay);
      
      // Handle license image URL
      final rawImageUrl = driver['license_image_url'];
      if (rawImageUrl != null && rawImageUrl.isNotEmpty) {
        // Check if it's already a full URL or needs to be converted from storage path
        if (rawImageUrl.startsWith('http://') || rawImageUrl.startsWith('https://')) {
          licenseImageUrl = rawImageUrl;
        } else {
          // It's a storage path, generate public URL
          try {
            licenseImageUrl = _supabase.storage
                .from('public')
                .getPublicUrl(rawImageUrl);
          } catch (e) {
            debugPrint('Error generating public URL: $e');
            licenseImageUrl = null;
          }
        }
        debugPrint('Driver license image URL: $licenseImageUrl');
      }
      
      // Get operator name from nested operator data or operator_name field
      String operatorName = driver['operator_name'] ?? '';
      if (driver['operators'] != null) {
        operatorName = driver['operators']['company_name'] ?? operatorName;
      }
      operatorController = TextEditingController(text: operatorName);
    } else {
      licenseIdController = TextEditingController();
      operatorController = TextEditingController();
      plateNumberController = TextEditingController();
      routeCodeController = TextEditingController();
      puvTypeController = TextEditingController();
    }
  }

  Future<void> _saveChanges() async {
    setState(() => isSaving = true);
    
    try {
      final profileId = widget.profileData['id'];
      final driver = widget.profileData['drivers'] is List 
          ? (widget.profileData['drivers'] as List).firstOrNull 
          : widget.profileData['drivers'];
      
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

      // Update driver specific info
      if (driver != null) {
        // Look up route_id from route code
        String? routeId;
        final routeCode = routeCodeController.text.trim();
        
        if (routeCode.isNotEmpty) {
          try {
            final routeResult = await _supabase
                .from('routes')
                .select('id')
                .eq('code', routeCode)
                .maybeSingle();
            
            if (routeResult != null) {
              routeId = routeResult['id'];
            }
          } catch (e) {
            debugPrint('Error looking up route: $e');
          }
        }
        
        await _supabase
            .from('drivers')
            .update({
              'license_number': licenseIdController.text.trim(),
              'vehicle_plate': plateNumberController.text.trim(),
              'route_code': routeCodeController.text.trim(),
              'route_id': routeId, // Update the foreign key
              'puv_type': puvType, // ✨ NEW: Save PUV type
            })
            .eq('id', driver['id']);
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
    ageController.dispose();
    sexController.dispose();
    addressController.dispose();
    operatorController.dispose();
    licenseIdController.dispose();
    plateNumberController.dispose();
    routeCodeController.dispose();
    puvTypeController.dispose(); // ✨ NEW
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
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
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
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                  ),
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

                      _buildLabel("Assigned Operator"),
                      _buildTextField(operatorController, readOnly: true),

                      _buildLabel("Driver's License"),
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
                          child: licenseImageUrl != null && licenseImageUrl!.isNotEmpty
                              ? Image.network(
                                  licenseImageUrl!,
                                  fit: BoxFit.cover,
                                  height: 200,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      height: 200,
                                      alignment: Alignment.center,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          CircularProgressIndicator(
                                            color: primary1,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Loading image...',
                                            style: GoogleFonts.nunito(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    debugPrint('Image load error: $error');
                                    debugPrint('Image URL was: $licenseImageUrl');
                                    return Container(
                                      height: 200,
                                      alignment: Alignment.center,
                                      padding: EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.error_outline, size: 48, color: Colors.red),
                                          SizedBox(height: 8),
                                          Text(
                                            'Failed to load image',
                                            style: GoogleFonts.manrope(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            error.toString(),
                                            style: GoogleFonts.nunito(
                                              fontSize: 11,
                                              color: Colors.red[700],
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  height: 200,
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text(
                                        'No license image uploaded',
                                        style: GoogleFonts.nunito(color: Colors.grey),
                                      ),
                                      if (licenseImageUrl != null)
                                        Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Text(
                                            'URL: $licenseImageUrl',
                                            style: GoogleFonts.nunito(
                                              fontSize: 10,
                                              color: Colors.grey[600],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                        ),
                      ),

                      _buildLabel("Driver License ID No"),
                      _buildTextField(licenseIdController),

                      // ✨ NEW: PUV Type field
                      _buildLabel("PUV Type"),
                      _buildTextField(puvTypeController, readOnly: true),

                      // Plate Number and Route Code in a row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel("Plate Number"),
                                _buildTextField(plateNumberController),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel("Route Code"),
                                _buildTextField(routeCodeController),
                              ],
                            ),
                          ),
                        ],
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