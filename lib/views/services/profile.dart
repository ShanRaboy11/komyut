import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get current user's profile data
  Future<Map<String, dynamic>> getCurrentUserProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Get profile with role
      final profileResponse = await _supabase
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .single();

      final role = profileResponse['role'] as String;
      final profileId = profileResponse['id'];

      // Get role-specific data
      Map<String, dynamic> roleData = {};
      
      switch (role) {
        case 'commuter':
          final commuterData = await _supabase
              .from('commuters')
              .select()
              .eq('profile_id', profileId)
              .single();
          roleData = commuterData;
          break;
          
        case 'driver':
          final driverData = await _supabase
              .from('drivers')
              .select('*, operators(*)')
              .eq('profile_id', profileId)
              .single();
          roleData = driverData;
          break;
          
        case 'operator':
          final operatorData = await _supabase
              .from('operators')
              .select()
              .eq('profile_id', profileId)
              .single();
          roleData = operatorData;
          break;
      }

      return {
        ...profileResponse,
        'role_data': roleData,
      };
    } catch (e) {
      throw Exception('Error fetching profile: $e');
    }
  }

  /// Update profile information
  Future<void> updateProfile({
    required String profileId,
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
    int? age,
    String? sex,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (firstName != null) updates['first_name'] = firstName;
      if (lastName != null) updates['last_name'] = lastName;
      if (phone != null) updates['phone'] = phone;
      if (address != null) updates['address'] = address;
      if (age != null) updates['age'] = age;
      if (sex != null) updates['sex'] = sex;

      await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', profileId);
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  /// Update operator-specific info
  Future<void> updateOperatorInfo({
    required String operatorId,
    String? companyName,
    String? companyAddress,
    String? contactEmail,
    String? contactPhone,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (companyName != null) updates['company_name'] = companyName;
      if (companyAddress != null) updates['company_address'] = companyAddress;
      if (contactEmail != null) updates['contact_email'] = contactEmail;
      if (contactPhone != null) updates['contact_phone'] = contactPhone;

      await _supabase
          .from('operators')
          .update(updates)
          .eq('id', operatorId);
    } catch (e) {
      throw Exception('Error updating operator info: $e');
    }
  }

  /// Get user's email from auth
  String? getCurrentUserEmail() {
    return _supabase.auth.currentUser?.email;
  }

  /// Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}