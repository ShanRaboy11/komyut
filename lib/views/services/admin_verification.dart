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

      debugPrint('✅ Fetched verification detail');

      final profileId = verification['profile_id'] as String;
      final role = (verification['profiles'] as Map<String, dynamic>)['role'] as String;

      // Fetch role-specific data
      Map<String, dynamic>? roleData;
      
      if (role == 'driver') {
        roleData = await _fetchDriverData(profileId);
      } else if (role == 'commuter') {
        roleData = await _fetchCommuterData(profileId);
      } else if (role == 'operator') {
        roleData = await _fetchOperatorData(profileId);
      }

      // Combine all data
      return {
        ...verification,
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
        // Format operator name
        String? operatorName;
        if (driver['operators'] != null) {
          final operatorProfile = driver['operators']['profiles'];
          if (operatorProfile != null) {
            operatorName = '${operatorProfile['first_name']} ${operatorProfile['last_name']}';
          } else {
            operatorName = driver['operators']['company_name'];
          }
        }

        // Try to read license attachment id from driver metadata (if available)
        String? licenseAttachmentId;
        try {
          final metadata = driver['metadata'] as Map<String, dynamic>?;
          licenseAttachmentId = metadata != null ? (metadata['license_attachment_id'] as String?) : null;
        } catch (_) {
          licenseAttachmentId = null;
        }

        String? licenseUrl;
        final List<Map<String, dynamic>> attachments = [];
        if (licenseAttachmentId != null) {
          try {
            final attRow = await _supabase
                .from('attachments')
                .select('id, url, path, content_type')
                .eq('id', licenseAttachmentId)
                .maybeSingle();
            if (attRow != null) {
              licenseUrl = attRow['url'] as String?;
              attachments.add({'type': 'Driver License', 'id': licenseAttachmentId, 'url': licenseUrl});
            }
          } catch (e) {
            debugPrint('❌ Error fetching driver attachment: $e');
          }
        }

        return {
          'license_number': driver['license_number'],
          'vehicle_plate': driver['vehicle_plate'],
          'puv_type': driver['puv_type'],
          'operator_name': operatorName ?? 'Not assigned',
          'license_image_url': licenseUrl,
          'attachments': attachments,
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
          .select('id, company_name, company_address, contact_email, lto_cr_attachment_id, ltfrb_franchise_attachment_id, government_id_attachment_id')
          .eq('profile_id', profileId)
          .maybeSingle();

      if (operator == null) return null;

      // Collect attachment ids
      final List<String> attachmentIds = [];
      final ltoId = operator['lto_cr_attachment_id'] as String?;
      final ltfrbId = operator['ltfrb_franchise_attachment_id'] as String?;
      final govId = operator['government_id_attachment_id'] as String?;
      if (ltoId != null) attachmentIds.add(ltoId);
      if (ltfrbId != null) attachmentIds.add(ltfrbId);
      if (govId != null) attachmentIds.add(govId);

      List<Map<String, dynamic>> attachments = [];
      if (attachmentIds.isNotEmpty) {
        for (final aid in attachmentIds) {
          try {
            final attRow = await _supabase
                .from('attachments')
                .select('id, url, path, content_type')
                .eq('id', aid)
                .maybeSingle();
            if (attRow != null) attachments.add(Map<String, dynamic>.from(attRow));
          } catch (_) {}
        }
      }

      // Build typed attachments list preserving order and type
      final List<Map<String, dynamic>> typed = [];
      if (ltoId != null) {
        final row = attachments.firstWhere((a) => a['id'] == ltoId, orElse: () => {});
        typed.add({'type': 'LTO CR', 'id': ltoId, 'url': row['url']});
      }
      if (ltfrbId != null) {
        final row = attachments.firstWhere((a) => a['id'] == ltfrbId, orElse: () => {});
        typed.add({'type': 'LTFRB Franchise', 'id': ltfrbId, 'url': row['url']});
      }
      if (govId != null) {
        final row = attachments.firstWhere((a) => a['id'] == govId, orElse: () => {});
        // Label government ID attachment clearly for operator UI
        typed.add({'type': 'Government ID', 'id': govId, 'url': row['url']});
      }

      return {
        'id': operator['id'],
        'company_name': operator['company_name'],
        'company_address': operator['company_address'],
        'contact_email': operator['contact_email'],
        'attachments': typed,
      };
    } catch (e) {
      debugPrint('❌ Error fetching operator data: $e');
      return null;
    }
  }

  /// Get current admin's profile ID
  Future<String?> getAdminProfileId() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('❌ No authenticated user');
        return null;
      }

      debugPrint('🔍 Getting admin profile for user: $userId');

      final response = await _supabase
          .from('profiles')
          .select('id, role')
          .eq('user_id', userId)
          .single();

      debugPrint('✅ Admin profile: ${response['id']}, role: ${response['role']}');
      return response['id'] as String;
    } catch (e) {
      debugPrint('❌ Error getting admin profile ID: $e');
      return null;
    }
  }

  /// Approve a verification request
  Future<void> approveVerification(String verificationId, String profileId, String? notes) async {
    try {
      debugPrint('🔍 Approving verification: $verificationId');
      
      final adminProfileId = await getAdminProfileId();
      
      if (adminProfileId == null) {
        throw Exception('Admin profile not found');
      }

      // Get the verification to check the role
      final verification = await _supabase
          .from('verifications')
          .select('profiles!verifications_profile_id_fkey(role)')
          .eq('id', verificationId)
          .single();

      final role = (verification['profiles'] as Map<String, dynamic>)['role'] as String;

      // Update verification status
      await _supabase
          .from('verifications')
          .update({
            'status': 'approved',
            'reviewer_profile_id': adminProfileId,
            'reviewer_notes': notes,
            'reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', verificationId);

      // Update profile verified status
      await _supabase
          .from('profiles')
          .update({'is_verified': true})
          .eq('id', profileId);

      // If commuter, update commuter-specific verification
      if (role == 'commuter') {
        await _supabase
            .from('commuters')
            .update({'id_verified': true})
            .eq('profile_id', profileId);
      }

      debugPrint('✅ Approved verification: $verificationId');
    } catch (e) {
      debugPrint('❌ Error approving verification: $e');
      rethrow;
    }
  }

  /// Update commuter category for a profile (e.g., senior, student, pwd, regular)
  Future<void> updateCommuterCategory(String profileId, String category) async {
    try {
      await _supabase
          .from('commuters')
          .update({'category': category})
          .eq('profile_id', profileId);
      debugPrint('✅ Updated commuter category for $profileId -> $category');
    } catch (e) {
      debugPrint('❌ Error updating commuter category: $e');
      rethrow;
    }
  }

  /// Reject a verification request
  Future<void> rejectVerification(String verificationId, String notes) async {
    try {
      debugPrint('🔍 Rejecting verification: $verificationId');
      
      final adminProfileId = await getAdminProfileId();
      
      if (adminProfileId == null) {
        throw Exception('Admin profile not found');
      }

      await _supabase
          .from('verifications')
          .update({
            'status': 'rejected',
            'reviewer_profile_id': adminProfileId,
            'reviewer_notes': notes,
            'reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', verificationId);

      debugPrint('✅ Rejected verification: $verificationId');
    } catch (e) {
      debugPrint('❌ Error rejecting verification: $e');
      rethrow;
    }
  }

  /// Mark verification as lacking documents
  Future<void> markAsLacking(String verificationId, String notes) async {
    try {
      debugPrint('🔍 Marking verification as lacking: $verificationId');
      
      final adminProfileId = await getAdminProfileId();
      
      if (adminProfileId == null) {
        throw Exception('Admin profile not found');
      }

      await _supabase
          .from('verifications')
          .update({
            'status': 'lacking',
            'reviewer_profile_id': adminProfileId,
            'reviewer_notes': notes,
            'reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', verificationId);

      debugPrint('✅ Marked verification as lacking: $verificationId');
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