// lib/services/registration_service.dart
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

  // Step 2b: Save driver personal info
  void saveDriverPersonalInfo({
    required String firstName,
    required String lastName,
    required int age,
    required String sex,
    required String address,
    required String licenseNumber,
    String? assignedOperator,
    required String driverLicensePath,
  }) {
    _registrationData['first_name'] = firstName;
    _registrationData['last_name'] = lastName;
    _registrationData['age'] = age;
    _registrationData['sex'] = sex;
    _registrationData['address'] = address;
    _registrationData['license_number'] = licenseNumber;
    _registrationData['assigned_operator'] = assignedOperator;
    _registrationData['driver_license_path'] = driverLicensePath;
    debugPrint('✅ Driver personal info saved');
    debugPrint('Current data: $_registrationData');
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
  void saveLoginInfo({
    required String email,
    required String password,
  }) {
    _registrationData['email'] = email;
    _registrationData['password'] = password;
    debugPrint('✅ Login info saved');
    debugPrint('Current data: $_registrationData');
  }

  // Send email verification OTP
  Future<Map<String, dynamic>> sendEmailVerificationOTP(String email) async {
    try {
      debugPrint('📧 Sending OTP to: $email');

      await _supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: null,
      );

      debugPrint('✅ OTP sent successfully');
      return {'success': true};
    } catch (e) {
      debugPrint('❌ Error sending OTP: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
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
        return {
          'success': false,
          'message': 'Invalid verification code',
        };
      }

      debugPrint('✅ User authenticated: ${authResponse.user!.id}');

      // Set password for the account
      final password = _registrationData['password'] as String?;
      if (password != null) {
        debugPrint('🔐 Setting user password...');
        await _supabase.auth.updateUser(
          UserAttributes(password: password),
        );
        debugPrint('✅ Password set successfully');
      }

      return {'success': true};
    } catch (e) {
      debugPrint('❌ Error verifying OTP: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Resend OTP
  Future<Map<String, dynamic>> resendOTP(String email) async {
    try {
      debugPrint('🔄 Resending OTP to: $email');

      await _supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: null,
      );

      debugPrint('✅ OTP resent successfully');
      return {'success': true};
    } catch (e) {
      debugPrint('❌ Error resending OTP: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Complete registration after email verification
  Future<Map<String, dynamic>> completeRegistration() async {
    try {
      debugPrint('🔍 Starting completeRegistration');
      
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'No authenticated user found',
        };
      }

      debugPrint('✅ User authenticated: ${user.id}');
      debugPrint('📋 Registration data: $_registrationData');

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

      // Create profile
      debugPrint('💾 Inserting profile...');
      final profileData = {
        'user_id': user.id,
        'role': role,
        'first_name': _registrationData['first_name'],
        'last_name': _registrationData['last_name'],
        'age': _registrationData['age'],
        'sex': _registrationData['sex'],
        'address': _registrationData['address'],
      };

      final profileResponse = await _supabase
          .from('profiles')
          .insert(profileData)
          .select()
          .single();

      final profileId = profileResponse['id'];
      debugPrint('✅ Profile created with ID: $profileId');

      // Create wallet
      debugPrint('💰 Creating wallet...');
      await _supabase.from('wallets').insert({
        'owner_profile_id': profileId,
        'balance': 0,
      });
      debugPrint('✅ Wallet created!');

      // Create role-specific records
      if (role == 'commuter') {
        debugPrint('🚶 Creating commuter record...');
        await _supabase.from('commuters').insert({
          'profile_id': profileId,
          'category': _registrationData['category'] ?? 'regular',
        });
        debugPrint('✅ Commuter created!');
      } else if (role == 'driver') {
        debugPrint('🚗 Creating driver record...');
        await _supabase.from('drivers').insert({
          'profile_id': profileId,
          'license_number': _registrationData['license_number'],
          'operator_name': _registrationData['assigned_operator'],
        });
        debugPrint('✅ Driver created!');
      } else if (role == 'operator') {
        debugPrint('🏢 Creating operator record...');
        await _supabase.from('operators').insert({
          'profile_id': profileId,
          'company_name': _registrationData['company_name'],
          'company_address': _registrationData['company_address'],
          'contact_email': _registrationData['contact_email'],
        });
        debugPrint('✅ Operator created!');
      }

      debugPrint('🎉 Registration completed successfully!');
      debugPrint('📤 Returning role: $role');
      
      // Return role at top level so it can be accessed
      return {
        'success': true,
        'role': role,  // CRITICAL: Role at top level
        'data': {
          'userId': user.id,
          'profileId': profileId,
          'role': role,
        },
      };
    } catch (e) {
      if (e is PostgrestException) {
        debugPrint('❌ Supabase Error: ${e.message}');
        debugPrint('❌ Error code: ${e.code}');
        debugPrint('❌ Error details: ${e.details}');
      } else {
        debugPrint('❌ Error completing registration: $e');
      }
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Clear all registration data
  void clearRegistrationData() {
    _registrationData.clear();
    debugPrint('🗑️ Registration data cleared');
  }
}