import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegistrationService {
  final _registrationData = <String, dynamic>{};
  final _supabase = Supabase.instance.client;

  // Get all registration data
  Map<String, dynamic> getRegistrationData() {
    return Map<String, dynamic>.from(_registrationData);
  }

  // Step 1: Save role
  void saveRole(String role) {
    _registrationData['role'] = role;
    debugPrint('✅ Role saved: $role');
    debugPrint('Current data: $_registrationData');
  }

  // Step 2a: Save commuter personal info
  void savePersonalInfo({
    required String firstName,
    required String lastName,
    required int age,
    required String sex,
    required String address,
    required String category,
    String? idProofPath,
  }) {
    _registrationData['first_name'] = firstName;
    _registrationData['last_name'] = lastName;
    _registrationData['age'] = age;
    _registrationData['sex'] = sex;
    _registrationData['address'] = address;
    _registrationData['category'] = category;
    if (idProofPath != null) {
      _registrationData['id_proof_path'] = idProofPath;
    }
    debugPrint('✅ Personal info saved');
    debugPrint('Current data: $_registrationData');
  }

  // Step 2b: Save driver personal info (UPDATED with vehicle and route)
  void saveDriverPersonalInfo({
    required String firstName,
    required String lastName,
    required int age,
    required String sex,
    required String address,
    required String licenseNumber,
    String? assignedOperator,
    required String driverLicensePath,
    required String vehiclePlate, 
    required String routeCode,
    required String puvType,
  }) {
    _registrationData['first_name'] = firstName;
    _registrationData['last_name'] = lastName;
    _registrationData['age'] = age;
    _registrationData['sex'] = sex;
    _registrationData['address'] = address;
    _registrationData['license_number'] = licenseNumber;
    _registrationData['assigned_operator'] = assignedOperator;
    _registrationData['driver_license_path'] = driverLicensePath;
    _registrationData['vehicle_plate'] = vehiclePlate;
    _registrationData['route_code'] = routeCode; 
    _registrationData['puv_type'] = puvType;
    debugPrint('✅ Driver personal info saved');
    debugPrint('Current data: $_registrationData');
  }

  Future<String?> uploadDriverLicense(File file, String licenseNumber) async {
    try {
      debugPrint('📤 Starting license upload...');
      
      // Generate unique filename
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'driver_license_${licenseNumber}_$timestamp.jpg';
      final String filePath = 'driver_licenses/$fileName';

      debugPrint('📁 Upload path: $filePath');

      // Upload to Supabase Storage
      await _supabase.storage
          .from('attachments')
          .upload(
            filePath,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // Get public URL
      final String publicUrl = _supabase.storage
          .from('attachments')
          .getPublicUrl(filePath);

      debugPrint('✅ License uploaded successfully: $publicUrl');
      return publicUrl;
      
    } catch (e) {
      debugPrint('❌ Error uploading license: $e');
      rethrow;
    }
  }

  // Step 2c: Save operator personal info
  void saveOperatorPersonalInfo({
    required String firstName,
    required String lastName,
    required String companyName,
    required String companyAddress,
    required String contactEmail,
  }) {
    _registrationData['first_name'] = firstName;
    _registrationData['last_name'] = lastName;
    _registrationData['company_name'] = companyName;
    _registrationData['company_address'] = companyAddress;
    _registrationData['contact_email'] = contactEmail;
    debugPrint('✅ Operator personal info saved');
    debugPrint('Current data: $_registrationData');
  }

  // Step 3: Save login info
  void saveLoginInfo({required String email, required String password}) {
    _registrationData['email'] = email;
    _registrationData['password'] = password;
    debugPrint('✅ Login info saved');
    debugPrint('Current data: $_registrationData');
  }

  // Send email verification OTP
  Future<Map<String, dynamic>> sendEmailVerificationOTP(String email) async {
    try {
      debugPrint('📧 Sending OTP to: $email');

      await _supabase.auth.signInWithOtp(email: email, emailRedirectTo: null);

      debugPrint('✅ OTP sent successfully');
      return {'success': true};
    } catch (e) {
      debugPrint('❌ Error sending OTP: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Verify OTP and create auth account
  Future<Map<String, dynamic>> verifyOTPAndCreateAccount(
    String email,
    String otp,
  ) async {
    try {
      debugPrint('🔍 Verifying OTP for: $email');

      // Verify OTP
      final authResponse = await _supabase.auth.verifyOTP(
        type: OtpType.email,
        email: email,
        token: otp,
      );

      if (authResponse.user == null) {
        return {'success': false, 'message': 'Invalid verification code'};
      }

      debugPrint('✅ User authenticated: ${authResponse.user!.id}');

      // Set password for the account
      final password = _registrationData['password'] as String?;
      if (password != null) {
        debugPrint('🔐 Setting user password...');
        await _supabase.auth.updateUser(UserAttributes(password: password));
        debugPrint('✅ Password set successfully');
      }

      return {'success': true};
    } catch (e) {
      debugPrint('❌ Error verifying OTP: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Resend OTP
  Future<Map<String, dynamic>> resendOTP(String email) async {
    try {
      debugPrint('🔄 Resending OTP to: $email');

      await _supabase.auth.signInWithOtp(email: email, emailRedirectTo: null);

      debugPrint('✅ OTP resent successfully');
      return {'success': true};
    } catch (e) {
      debugPrint('❌ Error resending OTP: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableRoutes() async {
    try {
      debugPrint('🔍 Fetching available routes...');

      final routes = await _supabase
          .from('routes')
          .select('code, name, description')
          .order('code');

      debugPrint('✅ Fetched ${routes.length} routes');
      return List<Map<String, dynamic>>.from(routes);
    } catch (e) {
      debugPrint('❌ Error fetching routes: $e');
      return [];
    }
  }

  // FIXED: Complete registration after email verification
  Future<Map<String, dynamic>> completeRegistration() async {
  try {
    debugPrint('🔍 Starting completeRegistration');
    debugPrint('📋 Registration data: $_registrationData');

    final user = _supabase.auth.currentUser;
    if (user == null) {
      debugPrint('❌ No authenticated user found');
      return {
        'success': false,
        'message': 'No authenticated user found. Please try logging in again.',
      };
    }

    debugPrint('✅ User authenticated: ${user.id}');

    // Verify role exists
    final role = _registrationData['role'];
    if (role == null) {
      debugPrint('❌ Role is missing from registration data!');
      return {
        'success': false,
        'message': 'Role information is missing. Please restart registration.',
      };
    }

    debugPrint('✅ Role found: $role');

    // Check if profile already exists
    debugPrint('🔍 Checking if profile already exists...');
    final existingProfile = await _supabase
        .from('profiles')
        .select('id, role')
        .eq('user_id', user.id)
        .maybeSingle();

    String profileId;

    if (existingProfile != null) {
      debugPrint('⚠️ Profile already exists for user ${user.id}');
      profileId = existingProfile['id'];
      debugPrint('✅ Using existing profile ID: $profileId');
    } else {
      // Create profile
      debugPrint('💾 Creating new profile...');

      final profileData = <String, dynamic>{
        'user_id': user.id,
        'role': role,
        'first_name': _registrationData['first_name'] ?? '',
        'last_name': _registrationData['last_name'] ?? '',
        'age': _registrationData['age'],
        'sex': _registrationData['sex'],
        'address': _registrationData['address'],
      };

      debugPrint('📤 Profile data to insert: $profileData');

      try {
        final profileResponse = await _supabase
            .from('profiles')
            .insert(profileData)
            .select('id')
            .single();

        profileId = profileResponse['id'];
        debugPrint('✅ Profile created with ID: $profileId');
      } catch (insertError) {
        debugPrint('❌ Error inserting profile: $insertError');

        if (insertError is PostgrestException) {
          debugPrint('❌ PostgrestException code: ${insertError.code}');
          debugPrint('❌ PostgrestException message: ${insertError.message}');
          debugPrint('❌ PostgrestException details: ${insertError.details}');

          return {
            'success': false,
            'message': 'Failed to create profile. Error: ${insertError.message}',
          };
        }
        rethrow;
      }
    }

    // Create wallet if it doesn't exist
    debugPrint('💰 Checking/creating wallet...');
    final existingWallet = await _supabase
        .from('wallets')
        .select('id')
        .eq('owner_profile_id', profileId)
        .maybeSingle();

    if (existingWallet == null) {
      await _supabase.from('wallets').insert({
        'owner_profile_id': profileId,
        'balance': 0,
      });
      debugPrint('✅ Wallet created!');
    } else {
      debugPrint('✅ Wallet already exists');
    }

    // Create role-specific records
    if (role == 'commuter') {
      debugPrint('🚶 Checking/creating commuter record...');
      final existingCommuter = await _supabase
          .from('commuters')
          .select('id')
          .eq('profile_id', profileId)
          .maybeSingle();

      if (existingCommuter == null) {
        await _supabase.from('commuters').insert({
          'profile_id': profileId,
          'category': _registrationData['category'] ?? 'regular',
        });
        debugPrint('✅ Commuter created!');
      } else {
        debugPrint('✅ Commuter already exists');
      }
    } else if (role == 'driver') {
      debugPrint('🚗 Checking/creating driver record...');
      final existingDriver = await _supabase
          .from('drivers')
          .select('id')
          .eq('profile_id', profileId)
          .maybeSingle();

      if (existingDriver == null) {
        // 🔥 UPLOAD LICENSE IMAGE NOW (user is authenticated)
        String? licenseImageUrl;
        final String? localFilePath = _registrationData['driver_license_path'];
        
        if (localFilePath != null) {
          try {
            debugPrint('📤 Uploading driver license image...');
            final file = File(localFilePath);
            licenseImageUrl = await uploadDriverLicense(
              file,
              _registrationData['license_number'],
            );
            debugPrint('✅ License uploaded: $licenseImageUrl');
          } catch (uploadError) {
            debugPrint('⚠️ Failed to upload license: $uploadError');
            // Continue anyway - you can handle this manually later
          }
        }

        // Get route_id from route_code
        String? routeId;
        if (_registrationData['route_code'] != null) {
          debugPrint('🔍 Fetching route_id for code: ${_registrationData['route_code']}');
          final routeResponse = await _supabase
              .from('routes')
              .select('id')
              .eq('code', _registrationData['route_code'])
              .maybeSingle();

          if (routeResponse != null) {
            routeId = routeResponse['id'];
            debugPrint('✅ Found route_id: $routeId');
          } else {
            debugPrint('⚠️ Route not found for code: ${_registrationData['route_code']}');
          }
        }

        // Create driver record with uploaded image URL
        await _supabase.from('drivers').insert({
          'profile_id': profileId,
          'license_number': _registrationData['license_number'] ?? '',
          'license_image_url': licenseImageUrl, // 🔥 Uploaded URL
          'operator_name': _registrationData['assigned_operator'],
          'vehicle_plate': _registrationData['vehicle_plate'] ?? '',
          'route_id': routeId,
          'route_code': _registrationData['route_code'],
          'puv_type': _registrationData['puv_type'], // 🔥 PUV Type
          'status': false,
          'active': true,
        });
        debugPrint('✅ Driver created with license URL and PUV type');
      } else {
        debugPrint('✅ Driver already exists');
      }
    } else if (role == 'operator') {
      debugPrint('🏢 Checking/creating operator record...');
      final existingOperator = await _supabase
          .from('operators')
          .select('id')
          .eq('profile_id', profileId)
          .maybeSingle();

      if (existingOperator == null) {
        await _supabase.from('operators').insert({
          'profile_id': profileId,
          'company_name': _registrationData['company_name'] ?? '',
          'company_address': _registrationData['company_address'] ?? '',
          'contact_email': _registrationData['contact_email'] ?? '',
        });
        debugPrint('✅ Operator created!');
      } else {
        debugPrint('✅ Operator already exists');
      }
    }

    debugPrint('🎉 Registration completed successfully!');
    debugPrint('📤 Returning role: $role');

    return {
      'success': true,
      'role': role,
      'data': {'userId': user.id, 'profileId': profileId, 'role': role},
    };
  } catch (e, stackTrace) {
    if (e is PostgrestException) {
      debugPrint('❌ Supabase Error: ${e.message}');
      debugPrint('❌ Error code: ${e.code}');
      debugPrint('❌ Error details: ${e.details}');
    } else {
      debugPrint('❌ Error completing registration: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
    return {
      'success': false,
      'message': 'Registration failed: ${e.toString()}',
    };
  }
}

  // Clear all registration data
  void clearRegistrationData() {
    _registrationData.clear();
    debugPrint('🗑️ Registration data cleared');
  }
}   