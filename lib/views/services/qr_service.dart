// lib/services/qr_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

class QRService {
  final _supabase = Supabase.instance.client;

  /// Generate a unique QR code for a driver
  /// Format: KOMYUT-[DRIVER_ID]-[TIMESTAMP]-[RANDOM]
  Future<Map<String, dynamic>> generateQRCode() async {
    try {
      debugPrint('🔄 Starting QR code generation...');

      // Get current user
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'No authenticated user found',
        };
      }

      debugPrint('✅ User authenticated: ${user.id}');

      // Get driver's profile
      final profileResponse = await _supabase
          .from('profiles')
          .select('id, first_name, last_name, role')
          .eq('user_id', user.id)
          .single();

      final profileId = profileResponse['id'];
      final role = profileResponse['role'];

      if (role != 'driver') {
        return {
          'success': false,
          'message': 'Only drivers can generate QR codes',
        };
      }

      debugPrint('✅ Profile found: $profileId');

      // ✅ UPDATED: Get driver record with route details using FK
      final driverResponse = await _supabase
          .from('drivers')
          .select('''
            id, 
            license_number, 
            vehicle_plate, 
            current_qr,
            routes:route_id (
              code,
              name
            )
          ''')
          .eq('profile_id', profileId)
          .single();

      final driverId = driverResponse['id'];
      final licenseNumber = driverResponse['license_number'];
      final vehiclePlate = driverResponse['vehicle_plate'] ?? 'N/A';
      
      // ✅ UPDATED: Get route info from nested query
      final routeData = driverResponse['routes'];
      final routeCode = routeData?['code'] ?? 'N/A';
      final routeName = routeData?['name'] ?? 'N/A';
      final existingQR = driverResponse['current_qr'];

      debugPrint('✅ Driver found: $driverId');
      debugPrint('✅ Route: $routeCode - $routeName');
      debugPrint('✅ Vehicle Plate: $vehiclePlate');

      // Generate unique QR code
      final qrCode = _generateUniqueQRCode(driverId);
      debugPrint('✅ Generated QR code: $qrCode');

      // Update driver's current_qr
      await _supabase
          .from('drivers')
          .update({
            'current_qr': qrCode,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', driverId);

      debugPrint('✅ QR code saved to database');

      // ✅ UPDATED: Return data with proper field names for UI
      return {
        'success': true,
        'qrCode': qrCode,
        'data': {
          'driverId': driverId,
          'profileId': profileId,
          'driverName': '${profileResponse['first_name']} ${profileResponse['last_name']}',
          'licenseNumber': licenseNumber,
          'plateNumber': vehiclePlate,      // ✅ Changed to plateNumber
          'routeNumber': routeCode,         // ✅ Changed to routeNumber
          'routeName': routeName,           // ✅ Added routeName
          'generatedAt': DateTime.now().toIso8601String(),
          'previousQR': existingQR,
        },
      };
    } catch (e) {
      debugPrint('❌ Error generating QR code: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Get current QR code for driver
  Future<Map<String, dynamic>> getCurrentQRCode() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'No authenticated user found',
        };
      }

      // Get driver's profile
      final profileResponse = await _supabase
          .from('profiles')
          .select('id, first_name, last_name')
          .eq('user_id', user.id)
          .single();

      final profileId = profileResponse['id'];

      // ✅ UPDATED: Get driver record with route details using FK
      final driverResponse = await _supabase
          .from('drivers')
          .select('''
            id, 
            license_number, 
            vehicle_plate, 
            current_qr, 
            updated_at,
            routes:route_id (
              code,
              name
            )
          ''')
          .eq('profile_id', profileId)
          .single();

      final qrCode = driverResponse['current_qr'];

      if (qrCode == null || qrCode.isEmpty) {
        return {
          'success': false,
          'hasQR': false,
          'message': 'No QR code generated yet',
        };
      }

      // ✅ UPDATED: Get route info from nested query
      final routeData = driverResponse['routes'];
      final routeCode = routeData?['code'] ?? 'N/A';
      final routeName = routeData?['name'] ?? 'N/A';

      debugPrint('✅ Current QR found');
      debugPrint('✅ Route: $routeCode - $routeName');
      debugPrint('✅ Vehicle Plate: ${driverResponse['vehicle_plate']}');

      // ✅ UPDATED: Return data with proper field names for UI
      return {
        'success': true,
        'hasQR': true,
        'qrCode': qrCode,
        'data': {
          'driverId': driverResponse['id'],
          'driverName': '${profileResponse['first_name']} ${profileResponse['last_name']}',
          'licenseNumber': driverResponse['license_number'],
          'plateNumber': driverResponse['vehicle_plate'] ?? 'N/A',  // ✅ Changed to plateNumber
          'routeNumber': routeCode,                                   // ✅ Changed to routeNumber
          'routeName': routeName,                                     // ✅ Added routeName
          'lastGenerated': driverResponse['updated_at'],
        },
      };
    } catch (e) {
      debugPrint('❌ Error getting current QR code: $e');
      return {
        'success': false,
        'hasQR': false,
        'message': e.toString(),
      };
    }
  }

  /// Generate unique QR code string
  String _generateUniqueQRCode(String driverId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999).toString().padLeft(4, '0');
    
    // Format: KOMYUT-DRIVER-[SHORT_ID]-[TIMESTAMP]-[RANDOM]
    final shortId = driverId.substring(0, 8).toUpperCase();
    return 'KOMYUT-DRIVER-$shortId-$timestamp-$random';
  }

  /// Validate QR code format
  bool validateQRCode(String qrCode) {
    // Check if QR code matches expected format
    final pattern = RegExp(r'^KOMYUT-DRIVER-[A-Z0-9]{8}-\d+-\d{4}$');
    return pattern.hasMatch(qrCode);
  }

  /// Verify QR code belongs to active driver
  Future<Map<String, dynamic>> verifyQRCode(String qrCode) async {
    try {
      // ✅ UPDATED: Find driver with route details using FK
      final response = await _supabase
          .from('drivers')
          .select('''
            id,
            license_number,
            vehicle_plate,
            active,
            status,
            profile_id,
            routes:route_id (
              code,
              name
            ),
            profiles!inner(
              id,
              first_name,
              last_name,
              role
            )
          ''')
          .eq('current_qr', qrCode)
          .maybeSingle();

      if (response == null) {
        return {
          'success': false,
          'valid': false,
          'message': 'Invalid QR code',
        };
      }

      final isActive = response['active'] ?? false;
      final status = response['status'] ?? false;
      
      // ✅ UPDATED: Get route info
      final routeData = response['routes'];
      final routeCode = routeData?['code'] ?? 'N/A';
      final routeName = routeData?['name'] ?? 'N/A';

      return {
        'success': true,
        'valid': true,
        'isActive': isActive,
        'isOnline': status,
        'data': {
          'driverId': response['id'],
          'driverName': '${response['profiles']['first_name']} ${response['profiles']['last_name']}',
          'licenseNumber': response['license_number'],
          'plateNumber': response['vehicle_plate'] ?? 'N/A',  
          'routeNumber': routeCode,                            
          'routeName': routeName,                              
        },
      };
    } catch (e) {
      debugPrint('❌ Error verifying QR code: $e');
      return {
        'success': false,
        'valid': false,
        'message': e.toString(),
      };
    }
  }
}