// lib/views/services/registration_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/api_config.dart';

class RegistrationService {
  final supabase = Supabase.instance.client;
  
  // Store registration data temporarily
  final Map<String, dynamic> _registrationData = {};

  Map<String, dynamic> getRegistrationData() => Map.from(_registrationData);

  // Step 1: Save role
  void saveRole(String role) {
    _registrationData['role'] = role.toLowerCase();
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
    
    if (category.toLowerCase() == 'regular') {
      _registrationData['category'] = 'regular';
    } else {
      _registrationData['category'] = 'student';
    }
    
    if (idProofPath != null) {
      _registrationData['id_proof_path'] = idProofPath;
    }
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
    _registrationData['driver_license_path'] = driverLicensePath;
    
    if (assignedOperator != null && assignedOperator.isNotEmpty) {
      _registrationData['operator_name'] = assignedOperator;
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
  }

  // Step 3: Save login info
  void saveLoginInfo({
    required String email,
    required String password,
  }) {
    _registrationData['email'] = email;
    _registrationData['password'] = password;
  }

  // NEW: Send OTP for email verification (no account created yet)
  Future<Map<String, dynamic>> sendEmailVerificationOTP(String email) async {
    try {
      debugPrint('📧 Sending verification OTP to: $email (no signup yet)');
      
      // Use signInWithOtp for email verification without creating account
      await supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: null, // We'll use OTP code instead
      );

      debugPrint('✅ OTP sent successfully');
      return {
        'success': true,
        'message': 'Verification code sent to your email',
      };
    } on AuthException catch (e) {
      debugPrint('❌ Auth Exception: ${e.message}');
      return {
        'success': false,
        'message': e.message,
      };
    } catch (e) {
      debugPrint('❌ Error sending OTP: $e');
      return {
        'success': false,
        'message': 'Failed to send verification code: ${e.toString()}',
      };
    }
  }

  // NEW: Verify OTP and create account
  Future<Map<String, dynamic>> verifyOTPAndCreateAccount(
    String email,
    String otp,
  ) async {
    try {
      debugPrint('🔍 Verifying OTP: $otp for email: $email');
      
      // Step 1: Verify OTP
      final verifyResponse = await supabase.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );

      if (verifyResponse.session == null) {
        debugPrint('❌ OTP verification failed - no session');
        return {
          'success': false,
          'message': 'Invalid verification code',
        };
      }

      debugPrint('✅ OTP verified successfully');
      
      // Step 2: Get the user ID from the session
      final userId = verifyResponse.user?.id;
      if (userId == null) {
        debugPrint('❌ No user ID after OTP verification');
        return {
          'success': false,
          'message': 'Verification failed',
        };
      }

      debugPrint('✅ User authenticated: $userId');

      // Step 3: Update the user's password (since we used OTP login, not signup)
      final password = _registrationData['password'];
      if (password != null) {
        debugPrint('🔐 Setting user password...');
        await supabase.auth.updateUser(
          UserAttributes(password: password),
        );
        debugPrint('✅ Password set successfully');
      }

      return {
        'success': true,
        'message': 'Email verified successfully',
        'userId': userId,
      };
    } on AuthException catch (e) {
      debugPrint('❌ Auth Exception: ${e.message}');
      
      String errorMessage = 'Invalid code. Please try again.';
      if (e.message.contains('expired')) {
        errorMessage = 'Code expired. Please request a new one.';
      } else if (e.message.contains('invalid')) {
        errorMessage = 'Invalid code. Please check and try again.';
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      debugPrint('❌ General Exception: $e');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // Step 4: Complete registration - Create profile and role-specific data
  Future<Map<String, dynamic>> completeRegistration() async {
    try {
      debugPrint('🔍 Starting completeRegistration');
      
      // Get the current authenticated user
      final user = supabase.auth.currentUser;
      
      if (user == null) {
        debugPrint('❌ No authenticated user found');
        return {
          'success': false,
          'message': 'User not authenticated. Please verify your email first.',
        };
      }

      debugPrint('✅ User authenticated: ${user.id}');
      debugPrint('📋 Registration data: $_registrationData');

      final role = _registrationData['role'];
      
      // Step 1: Create profile
      final profileData = {
        'user_id': user.id,
        'role': role,
        'first_name': _registrationData['first_name'],
        'last_name': _registrationData['last_name'],
        'age': _registrationData['age'],
        'sex': _registrationData['sex'],
        'address': _registrationData['address'],
        'is_verified': false,
      };

      debugPrint('💾 Inserting profile...');
      final profileResponse = await supabase
          .from('profiles')
          .insert(profileData)
          .select()
          .single();
      
      final profileId = profileResponse['id'];
      debugPrint('✅ Profile created with ID: $profileId');

      // Step 2: Create role-specific records
      if (role == 'commuter') {
        debugPrint('👤 Creating commuter record...');
        await supabase.from('commuters').insert({
          'profile_id': profileId,
          'category': _registrationData['category'],
          'id_verified': false,
          'wheel_tokens': 0,
        });
        
        debugPrint('💰 Creating wallet for commuter...');
        await supabase.from('wallets').insert({
          'owner_profile_id': profileId,
          'balance': 0.0,
          'locked': false,
        });
        
        debugPrint('✅ Commuter and wallet created!');
        
      } else if (role == 'driver') {
        debugPrint('🚗 Creating driver record...');
        await supabase.from('drivers').insert({
          'profile_id': profileId,
          'license_number': _registrationData['license_number'],
          'operator_name': _registrationData['operator_name'],
          'status': false,
          'active': true,
        });
        
        debugPrint('✅ Driver created!');
        
      } else if (role == 'operator') {
        debugPrint('🏢 Creating operator record...');
        await supabase.from('operators').insert({
          'profile_id': profileId,
          'company_name': _registrationData['company_name'],
          'company_address': _registrationData['company_address'],
          'contact_email': _registrationData['contact_email'],
        });
        
        debugPrint('✅ Operator created!');
      }

      clearRegistrationData();
      
      debugPrint('🎉 Registration completed successfully!');
      return {
        'success': true,
        'message': 'Registration completed successfully',
        'data': {
          'userId': user.id,
          'profileId': profileId,
          'role': role,
        },
      };

    } on PostgrestException catch (e) {
      debugPrint('❌ Supabase Error: ${e.message}');
      debugPrint('❌ Error code: ${e.code}');
      debugPrint('❌ Error details: ${e.details}');
      
      String userMessage = 'Database error occurred';
      if (e.code == '23505') {
        userMessage = 'This account already exists';
      } else if (e.code == '23503') {
        userMessage = 'Invalid data provided';
      }
      
      return {
        'success': false,
        'message': userMessage,
      };
    } catch (e) {
      debugPrint('❌ General Exception: $e');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // Resend OTP
  Future<Map<String, dynamic>> resendOTP(String email) async {
    try {
      debugPrint('🔄 Resending OTP to: $email');
      
      await supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: null,
      );

      debugPrint('✅ OTP resent successfully');
      return {
        'success': true,
        'message': 'New code sent to your email',
      };
    } on AuthException catch (e) {
      debugPrint('❌ Auth Exception: ${e.message}');
      return {
        'success': false,
        'message': e.message,
      };
    } catch (e) {
      debugPrint('❌ Error resending OTP: $e');
      return {
        'success': false,
        'message': 'Failed to resend code: ${e.toString()}',
      };
    }
  }

  // Upload file to Supabase Storage
  Future<String?> uploadFile(File file, String bucket, String path) async {
    try {
      final fileName = path.split('/').last;
      final filePath = '$path/$fileName';
      
      await supabase.storage.from(bucket).upload(
        filePath,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      final url = supabase.storage.from(bucket).getPublicUrl(filePath);
      return url;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }
  }

  // Clear all registration data
  void clearRegistrationData() {
    _registrationData.clear();
  }
}