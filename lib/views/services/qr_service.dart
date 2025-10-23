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

      // Get driver record
      final driverResponse = await _supabase
          .from('drivers')
          .select('id, license_number, vehicle_plate, route_code, current_qr')
          .eq('profile_id', profileId)
          .single();

      final driverId = driverResponse['id'];
      final licenseNumber = driverResponse['license_number'];
      final vehiclePlate = driverResponse['vehicle_plate'] ?? 'N/A';
      final routeCode = driverResponse['route_code'] ?? 'N/A';
      final existingQR = driverResponse['current_qr'];

      debugPrint('✅ Driver found: $driverId');

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

      return {
        'success': true,
        'qrCode': qrCode,
        'data': {
          'driverId': driverId,
          'profileId': profileId,
          'driverName': '${profileResponse['first_name']} ${profileResponse['last_name']}',
          'licenseNumber': licenseNumber,
          'vehiclePlate': vehiclePlate,
          'routeCode': routeCode,
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

      // Get driver record
      final driverResponse = await _supabase
          .from('drivers')
          .select('id, license_number, vehicle_plate, route_code, current_qr, updated_at')
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

      return {
        'success': true,
        'hasQR': true,
        'qrCode': qrCode,
        'data': {
          'driverId': driverResponse['id'],
          'driverName': '${profileResponse['first_name']} ${profileResponse['last_name']}',
          'licenseNumber': driverResponse['license_number'],
          'vehiclePlate': driverResponse['vehicle_plate'] ?? 'N/A',
          'routeCode': driverResponse['route_code'] ?? 'N/A',
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
      // Find driver with this QR code
      final response = await _supabase
          .from('drivers')
          .select('''
            id,
            license_number,
            vehicle_plate,
            route_code,
            active,
            status,
            profile_id,
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

      return {
        'success': true,
        'valid': true,
        'isActive': isActive,
        'isOnline': status,
        'data': {
          'driverId': response['id'],
          'driverName': '${response['profiles']['first_name']} ${response['profiles']['last_name']}',
          'licenseNumber': response['license_number'],
          'vehiclePlate': response['vehicle_plate'] ?? 'N/A',
          'routeCode': response['route_code'] ?? 'N/A',
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