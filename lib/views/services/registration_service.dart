// lib/views/services/registration_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class RegistrationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Store registration data temporarily during the flow
  Map<String, dynamic> registrationData = {};

  // Step 1: Save role selection
  void saveRole(String role) {
    // Convert to lowercase to match enum in database
    registrationData['role'] = role.toLowerCase();
  }

  // Step 2: Save personal information
  void savePersonalInfo({
    required String firstName,
    required String lastName,
    required int age,
    required String sex,
    required String address,
    required String category,
    String? idProofPath,
  }) {
    registrationData['first_name'] = firstName;
    registrationData['last_name'] = lastName;
    registrationData['age'] = age;
    registrationData['sex'] = sex;
    registrationData['address'] = address;
    registrationData['category'] = category.toLowerCase();
    
    if (idProofPath != null) {
      registrationData['id_proof_path'] = idProofPath;
    }
  }

  // Step 3: Save login credentials
  void saveLoginInfo({
    required String email,
    required String password,
  }) {
    registrationData['email'] = email;
    registrationData['password'] = password;
  }

  // Upload ID proof to Supabase Storage
  Future<String?> uploadIdProof(File file, String userId) async {
    try {
      final String fileName = 'id_proof_${userId}_${DateTime.now().millisecondsSinceEpoch}.${file.path.split('.').last}';
      final String filePath = 'id-proofs/$userId/$fileName';

      await _supabase.storage.from('komyut-attachments').upload(
        filePath,
        file,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: false,
        ),
      );

      final String publicUrl = _supabase.storage
          .from('komyut-attachments')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('Error uploading ID proof: $e');
      return null;
    }
  }

  // Create attachment record in database
  Future<String?> createAttachmentRecord({
    required String ownerProfileId,
    required String url,
    required String path,
    required File file,
  }) async {
    try {
      final response = await _supabase.from('attachments').insert({
        'owner_profile_id': ownerProfileId,
        'bucket': 'komyut-attachments',
        'path': path,
        'url': url,
        'content_type': 'image/${file.path.split('.').last}',
        'size_bytes': await file.length(),
        'metadata': {},
      }).select().single();

      return response['id'] as String;
    } catch (e) {
      print('Error creating attachment record: $e');
      return null;
    }
  }

  // Map category to commuter_category enum
  String _mapToCommuterCategory(String category) {
    if (category.toLowerCase() == 'discounted') {
      return 'student';
    }
    return 'regular';
  }

  // Final registration - create user account and profile
  Future<Map<String, dynamic>> completeRegistration() async {
    try {
      // Get current authenticated user (should be authenticated via OTP)
      final currentUser = _supabase.auth.currentUser;
      
      if (currentUser == null) {
        return {
          'success': false,
          'message': 'No authenticated user found. Please verify your email first.',
        };
      }

      final String authUserId = currentUser.id;

      // Step 1: Create profile record
      final profileResponse = await _supabase.from('profiles').insert({
        'user_id': authUserId,
        'role': registrationData['role'],
        'first_name': registrationData['first_name'],
        'last_name': registrationData['last_name'],
        'age': registrationData['age'],
        'sex': registrationData['sex'],
        'address': registrationData['address'],
        'is_verified': false,
        'metadata': {},
      }).select().single();

      final String profileId = profileResponse['id'] as String;

      // Step 2: Upload ID proof if exists
      String? attachmentId;
      if (registrationData['id_proof_path'] != null) {
        final file = File(registrationData['id_proof_path']);
        final filePath = 'id-proofs/$profileId/${DateTime.now().millisecondsSinceEpoch}.${file.path.split('.').last}';
        
        final idProofUrl = await uploadIdProof(file, profileId);
        
        if (idProofUrl != null) {
          attachmentId = await createAttachmentRecord(
            ownerProfileId: profileId,
            url: idProofUrl,
            path: filePath,
            file: file,
          );
        }
      }

      // Step 3: Create role-specific record
      final String role = registrationData['role'];
      
      if (role == 'commuter') {
        await _supabase.from('commuters').insert({
          'profile_id': profileId,
          'category': _mapToCommuterCategory(registrationData['category']),
          'attachment_id': attachmentId,
          'id_verified': attachmentId != null ? false : null,
          'wheel_tokens': 0,
        });
      } else if (role == 'driver') {
        await _supabase.from('drivers').insert({
          'profile_id': profileId,
          'license_number': registrationData['license_number'] ?? '',
          'status': false,
          'active': true,
          'metadata': {},
        });
      } else if (role == 'operator') {
        await _supabase.from('operators').insert({
          'profile_id': profileId,
          'company_name': registrationData['company_name'] ?? '',
          'company_address': registrationData['company_address'] ?? '',
          'contact_email': registrationData['email'],
          'metadata': {},
        });
      }

      // Step 4: Create wallet
      await _supabase.from('wallets').insert({
        'owner_profile_id': profileId,
        'balance': 0,
        'locked': false,
        'metadata': {},
      });

      registrationData.clear();

      return {
        'success': true,
        'message': 'Registration successful',
        'user': currentUser,
        'profile_id': profileId,
      };
    } catch (e) {
      print('Registration error: $e');
      return {
        'success': false,
        'message': 'Registration failed: ${e.toString()}',
      };
    }
  }

  // Clear registration data
  void clearRegistrationData() {
    registrationData.clear();
  }

  // Get current registration data
  Map<String, dynamic> getRegistrationData() {
    return Map.from(registrationData);
  }
}