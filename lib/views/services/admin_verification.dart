import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service class that handles all verification-related API calls
class AdminVerificationService {
  final _supabase = Supabase.instance.client;

  /// Fetch all verification requests with user details
  Future<List<Map<String, dynamic>>> fetchVerifications() async {
    try {
      debugPrint('🔍 Fetching verifications...');
      
      final response = await _supabase
          .from('verifications')
          .select('''
            *,
            profiles!verifications_profile_id_fkey(
              id,
              first_name,
              last_name,
              role,
              age,
              sex,
              address,
              is_verified
            ),
            attachments(
              id,
              url,
              path,
              content_type
            )
          ''')
          .order('created_at', ascending: false);

      debugPrint('✅ Raw response: ${response.length} records');
      debugPrint('📦 First record: ${response.isNotEmpty ? response[0] : "none"}');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching verifications: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Fetch detailed information for a specific verification
  Future<Map<String, dynamic>> fetchVerificationDetail(String verificationId) async {
    try {
      debugPrint('🔍 Fetching verification detail for: $verificationId');
      
      // Fetch base verification data
      final verification = await _supabase
          .from('verifications')
          .select('''
            *,
            import 'package:flutter/material.dart';
            import 'package:supabase_flutter/supabase_flutter.dart';

            /// Service class that handles all verification-related API calls
            class AdminVerificationService {
              final _supabase = Supabase.instance.client;

              /// Fetch all verification requests with user details
              Future<List<Map<String, dynamic>>> fetchVerifications() async {
                try {
                  debugPrint('🔍 Fetching verifications...');

                  final response = await _supabase
                      .from('verifications')
                      .select('''
                        *,
                        profiles!verifications_profile_id_fkey(
                          id,
                          first_name,
                          last_name,
                          role,
                          age,
                          sex,
                          address,
                          is_verified
                        ),
                        attachments(
                          id,
                          url,
                          path,
                          content_type
                        )
                      ''')
                      .order('created_at', ascending: false);

                  return List<Map<String, dynamic>>.from(response);
                } catch (e, stackTrace) {
                  debugPrint('❌ Error fetching verifications: $e');
                  debugPrint('Stack trace: $stackTrace');
                  rethrow;
                }
              }

              /// Fetch detailed information for a specific verification
              Future<Map<String, dynamic>> fetchVerificationDetail(String verificationId) async {
                try {
                  debugPrint('🔍 Fetching verification detail for: $verificationId');

                  final verification = await _supabase
                      .from('verifications')
                      .select('''
                        *,
                        profiles!verifications_profile_id_fkey(
                          id,
                          user_id,
                          first_name,
                          last_name,
                          role,
                          age,
                          sex,
                          address,
                          is_verified
                        ),
                        attachments(
                          id,
                          url,
                          path,
                          content_type
                        )
                      ''')
                      .eq('id', verificationId)
                      .single();

                  final profileId = verification['profile_id'] as String;
                  final role = (verification['profiles'] as Map<String, dynamic>)['role'] as String;

                  Map<String, dynamic>? roleData;
                  if (role == 'driver') {
                    roleData = await _fetchDriverData(profileId);
                  } else if (role == 'commuter') {
                    roleData = await _fetchCommuterData(profileId);
                  } else if (role == 'operator') {
                    roleData = await _fetchOperatorData(profileId);
                  }

                  return {
                    ...Map<String, dynamic>.from(verification),
                    'role_specific_data': roleData,
                  };
                } catch (e, stackTrace) {
                  debugPrint('❌ Error fetching verification detail: $e');
                  debugPrint('Stack trace: $stackTrace');
                  rethrow;
                }
              }

              /// Fetch driver-specific data
              Future<Map<String, dynamic>?> _fetchDriverData(String profileId) async {
                try {
                  final driver = await _supabase
                      .from('drivers')
                      .select('''
                        id,
                        license_number,
                        vehicle_plate,
                        puv_type,
                        operator_id,
                        operators!drivers_operator_id_fkey (
                          id,
                          company_name,
                          profiles!operators_profile_id_fkey (
                            first_name,
                            last_name
                          )
                        )
                      ''')
                      .eq('profile_id', profileId)
                      .maybeSingle();

                  if (driver != null) {
                    String? operatorName;
                    if (driver['operators'] != null) {
                      final operatorProfile = driver['operators']['profiles'];
                      if (operatorProfile != null) {
                        operatorName = '${operatorProfile['first_name']} ${operatorProfile['last_name']}';
                      } else {
                        operatorName = driver['operators']['company_name'];
                      }
                    }

                    // If driver table had a license attachment id stored in metadata or a column,
                    // the caller can add attachment fetching here. For now return structured data.
                    return {
                      'license_number': driver['license_number'],
                      'vehicle_plate': driver['vehicle_plate'],
                      'puv_type': driver['puv_type'],
                      'operator_name': operatorName ?? 'Not assigned',
                    };
                  }
                  return null;
                } catch (e) {
                  debugPrint('❌ Error fetching driver data: $e');
                  return null;
                }
              }

              /// Fetch commuter-specific data
              Future<Map<String, dynamic>?> _fetchCommuterData(String profileId) async {
                try {
                  final commuter = await _supabase
                      .from('commuters')
                      .select('id, category, id_verified')
                      .eq('profile_id', profileId)
                      .maybeSingle();

                  if (commuter != null) {
                    return {
                      'category': commuter['category'],
                      'id_verified': commuter['id_verified'],
                    };
                  }
                  return null;
                } catch (e) {
                  debugPrint('❌ Error fetching commuter data: $e');
                  return null;
                }
              }

              /// Fetch operator-specific data
              Future<Map<String, dynamic>?> _fetchOperatorData(String profileId) async {
                try {
                  final operator = await _supabase
                      .from('operators')
                      .select('id, company_name, company_address, contact_email')
                      .eq('profile_id', profileId)
                      .maybeSingle();

                  return operator;
                } catch (e) {
                  debugPrint('❌ Error fetching operator data: $e');
                  return null;
                }
              }

              /// Get current admin's profile ID
              Future<String?> getAdminProfileId() async {
                try {
                  final userId = _supabase.auth.currentUser?.id;
                  if (userId == null) return null;

                  final response = await _supabase.from('profiles').select('id, role').eq('user_id', userId).single();
                  return response['id'] as String;
                } catch (e) {
                  debugPrint('❌ Error getting admin profile ID: $e');
                  return null;
                }
              }

              /// Approve a verification request
              Future<void> approveVerification(String verificationId, String profileId, String? notes) async {
                try {
                  final adminProfileId = await getAdminProfileId();
                  if (adminProfileId == null) throw Exception('Admin profile not found');

                  final verification = await _supabase.from('verifications').select('profiles!verifications_profile_id_fkey(role)').eq('id', verificationId).single();
                  final role = (verification['profiles'] as Map<String, dynamic>)['role'] as String;

                  await _supabase.from('verifications').update({'status': 'approved', 'reviewer_profile_id': adminProfileId, 'reviewer_notes': notes, 'reviewed_at': DateTime.now().toIso8601String()}).eq('id', verificationId);

                  await _supabase.from('profiles').update({'is_verified': true}).eq('id', profileId);

                  if (role == 'commuter') {
                    await _supabase.from('commuters').update({'id_verified': true}).eq('profile_id', profileId);
                  }
                } catch (e) {
                  debugPrint('❌ Error approving verification: $e');
                  rethrow;
                }
              }

              /// Reject a verification request
              Future<void> rejectVerification(String verificationId, String notes) async {
                try {
                  final adminProfileId = await getAdminProfileId();
                  if (adminProfileId == null) throw Exception('Admin profile not found');

                  await _supabase.from('verifications').update({'status': 'rejected', 'reviewer_profile_id': adminProfileId, 'reviewer_notes': notes, 'reviewed_at': DateTime.now().toIso8601String()}).eq('id', verificationId);
                } catch (e) {
                  debugPrint('❌ Error rejecting verification: $e');
                  rethrow;
                }
              }

              /// Mark verification as lacking documents
              Future<void> markAsLacking(String verificationId, String notes) async {
                try {
                  final adminProfileId = await getAdminProfileId();
                  if (adminProfileId == null) throw Exception('Admin profile not found');

                  await _supabase.from('verifications').update({'status': 'lacking', 'reviewer_profile_id': adminProfileId, 'reviewer_notes': notes, 'reviewed_at': DateTime.now().toIso8601String()}).eq('id', verificationId);
                } catch (e) {
                  debugPrint('❌ Error marking as lacking: $e');
                  rethrow;
                }
              }

              /// Get storage URL for an attachment
              String? getAttachmentUrl(String? path) {
                if (path == null) return null;
                try {
                  return _supabase.storage.from('attachments').getPublicUrl(path);
                } catch (e) {
                  debugPrint('❌ Error getting attachment URL: $e');
                  return null;
                }
              }
            }