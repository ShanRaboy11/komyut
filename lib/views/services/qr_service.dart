// lib/services/qr_service.dart - WITH DATABASE INTEGRATION
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class QRService {
  final _supabase = Supabase.instance.client;

  /// Generate a new QR code for the driver
  Future<Map<String, dynamic>> generateQRCode() async {
    try {
      debugPrint('📱 Generating QR code...');

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return {
          'success': false,
          'message': 'No authenticated user found',
        };
      }

      // Get profile
      final profile = await _supabase
          .from('profiles')
          .select('id, first_name, last_name')
          .eq('user_id', userId)
          .maybeSingle();

      if (profile == null) {
        return {
          'success': false,
          'message': 'Profile not found',
        };
      }

      // Get driver info with route details
      final driverData = await _supabase
          .from('drivers')
          .select('''
            id,
            vehicle_plate,
            license_number,
            current_qr,
            routes:route_id (
              code,
              name
            )
          ''')
          .eq('profile_id', profile['id'])
          .maybeSingle();

      if (driverData == null) {
        return {
          'success': false,
          'message': 'Driver record not found',
        };
      }

      // Generate unique QR code data
      final qrData = {
        'driverId': driverData['id'],
        'driverName': '${profile['first_name']} ${profile['last_name']}',
        'plateNumber': driverData['vehicle_plate'] ?? 'N/A',
        'routeNumber': driverData['routes']?['code'] ?? 'N/A',
        'routeName': driverData['routes']?['name'] ?? '',
        'timestamp': DateTime.now().toIso8601String(),
      };

      final qrCodeString = jsonEncode(qrData);

      // Save QR code to driver record
      await _supabase
          .from('drivers')
          .update({'current_qr': qrCodeString})
          .eq('id', driverData['id']);

      debugPrint('✅ QR code generated successfully');
      debugPrint('📊 Driver data: $qrData');

      return {
        'success': true,
        'qrCode': qrCodeString,
        'data': qrData,
      };
    } catch (e) {
      debugPrint('❌ Error generating QR code: $e');
      return {
        'success': false,
        'message': 'Failed to generate QR code: ${e.toString()}',
      };
    }
  }

  /// Get the current QR code if it exists
  Future<Map<String, dynamic>> getCurrentQRCode() async {
    try {
      debugPrint('🔍 Checking for existing QR code...');

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return {
          'success': false,
          'hasQR': false,
          'message': 'No authenticated user',
        };
      }

      // Get profile
      final profile = await _supabase
          .from('profiles')
          .select('id, first_name, last_name')
          .eq('user_id', userId)
          .maybeSingle();

      if (profile == null) {
        return {
          'success': false,
          'hasQR': false,
          'message': 'Profile not found',
        };
      }

      // Get driver info with current QR and route
      final driverData = await _supabase
          .from('drivers')
          .select('''
            id,
            current_qr,
            vehicle_plate,
            routes:route_id (
              code,
              name
            )
          ''')
          .eq('profile_id', profile['id'])
          .maybeSingle();

      if (driverData == null) {
        return {
          'success': false,
          'hasQR': false,
          'message': 'Driver record not found',
        };
      }

      final currentQR = driverData['current_qr'];
      
      if (currentQR == null || currentQR.toString().isEmpty) {
        debugPrint('📭 No existing QR code found');
        return {
          'success': true,
          'hasQR': false,
        };
      }

      // Parse existing QR data
      Map<String, dynamic> qrData;
      try {
        qrData = jsonDecode(currentQR);
        
        // Update with latest driver info
        qrData['driverName'] = '${profile['first_name']} ${profile['last_name']}';
        qrData['plateNumber'] = driverData['vehicle_plate'] ?? 'N/A';
        qrData['routeNumber'] = driverData['routes']?['code'] ?? 'N/A';
        qrData['routeName'] = driverData['routes']?['name'] ?? '';
      } catch (e) {
        debugPrint('⚠️ Invalid QR data format, will regenerate');
        return {
          'success': true,
          'hasQR': false,
        };
      }

      debugPrint('✅ Existing QR code found');
      debugPrint('📊 Driver data: $qrData');

      return {
        'success': true,
        'hasQR': true,
        'qrCode': currentQR,
        'data': qrData,
      };
    } catch (e) {
      debugPrint('❌ Error getting current QR code: $e');
      return {
        'success': false,
        'hasQR': false,
        'message': 'Failed to get QR code: ${e.toString()}',
      };
    }
  }

  /// Refresh QR code data (update plate/route without generating new QR)
  Future<Map<String, dynamic>> refreshQRData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return {
          'success': false,
          'message': 'No authenticated user',
        };
      }

      // Get profile
      final profile = await _supabase
          .from('profiles')
          .select('id, first_name, last_name')
          .eq('user_id', userId)
          .single();

      // Get driver with route
      final driverData = await _supabase
          .from('drivers')
          .select('''
            id,
            current_qr,
            vehicle_plate,
            routes:route_id (
              code,
              name
            )
          ''')
          .eq('profile_id', profile['id'])
          .single();

      if (driverData['current_qr'] == null) {
        return {
          'success': false,
          'message': 'No QR code to refresh',
        };
      }

      // Update QR data with latest info
      final qrData = jsonDecode(driverData['current_qr']);
      qrData['driverName'] = '${profile['first_name']} ${profile['last_name']}';
      qrData['plateNumber'] = driverData['vehicle_plate'] ?? 'N/A';
      qrData['routeNumber'] = driverData['routes']?['code'] ?? 'N/A';
      qrData['routeName'] = driverData['routes']?['name'] ?? '';

      final updatedQRString = jsonEncode(qrData);

      // Update in database
      await _supabase
          .from('drivers')
          .update({'current_qr': updatedQRString})
          .eq('id', driverData['id']);

      debugPrint('✅ QR data refreshed');

      return {
        'success': true,
        'qrCode': updatedQRString,
        'data': qrData,
      };
    } catch (e) {
      debugPrint('❌ Error refreshing QR data: $e');
      return {
        'success': false,
        'message': 'Failed to refresh QR data: ${e.toString()}',
      };
    }
  }

  /// Delete current QR code
  Future<Map<String, dynamic>> deleteQRCode() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return {
          'success': false,
          'message': 'No authenticated user',
        };
      }

      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .single();

      final driver = await _supabase
          .from('drivers')
          .select('id')
          .eq('profile_id', profile['id'])
          .single();

      await _supabase
          .from('drivers')
          .update({'current_qr': null})
          .eq('id', driver['id']);

      debugPrint('✅ QR code deleted');

      return {
        'success': true,
        'message': 'QR code deleted successfully',
      };
    } catch (e) {
      debugPrint('❌ Error deleting QR code: $e');
      return {
        'success': false,
        'message': 'Failed to delete QR code: ${e.toString()}',
      };
    }
  }
}