import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/operator_drivers.dart';

class OperatorService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get the current operator's information
  Future<OperatorInfo?> getCurrentOperatorInfo() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Resolve the current user's profile id first, then find the operator
      final profileResp = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (profileResp == null) return null;
      final profileId = profileResp['id'] as String;

      // Select only the columns that exist in your database
      final response = await _supabase
          .from('operators')
          .select('''
            id,
            profile_id,
            company_name,
            company_address,
            contact_email
          ''')
          .eq('profile_id', profileId)
          .maybeSingle();

      if (response == null) return null;

      // Get driver count (use a lightweight select and count locally)
      final driverCountResponse = await _supabase
          .from('drivers')
          .select('id')
          .eq('operator_id', response['id']);

      final driverCount = (driverCountResponse as List).length;

      return OperatorInfo.fromJson({
        ...response,
        'driver_count': driverCount,
        // Add default values for missing fields
        'contact_phone': null,
      });
    } catch (e) {
      throw Exception('Failed to get operator info: $e');
    }
  }

  /// Get all drivers for the current operator
  Future<List<OperatorDriver>> getOperatorDrivers() async {
    try {
      final operatorInfo = await getCurrentOperatorInfo();
      if (operatorInfo == null) {
        throw Exception('Operator not found');
      }

      final response = await _supabase
          .from('drivers')
          .select('''
            id,
            profile_id,
            license_number,
            license_image_url,
            status,
            vehicle_plate,
            route_id,
            puv_type,
            active,
            created_at,
            profiles!inner(
              first_name,
              last_name
            ),
            routes(
              name,
              code
            )
          ''')
          .eq('operator_id', operatorInfo.id)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => OperatorDriver.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch drivers: $e');
    }
  }

  /// Get drivers with route information
  Future<List<OperatorDriver>> getOperatorDriversWithRoutes() async {
    try {
      final operatorInfo = await getCurrentOperatorInfo();
      if (operatorInfo == null) {
        throw Exception('Operator not found');
      }

      final response = await _supabase
          .from('drivers')
          .select('''
            id,
            profile_id,
            license_number,
            license_image_url,
            status,
            vehicle_plate,
            route_id,
            puv_type,
            active,
            created_at,
            profiles!inner(
              first_name,
              last_name
            ),
            routes(
              id,
              name,
              code,
              start_lat,
              start_lng,
              end_lat,
              end_lng
            )
          ''')
          .eq('operator_id', operatorInfo.id)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => OperatorDriver.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch drivers with routes: $e');
    }
  }

  /// Search drivers by name, license, or vehicle plate
  Future<List<OperatorDriver>> searchDrivers(String query) async {
    try {
      final operatorInfo = await getCurrentOperatorInfo();
      if (operatorInfo == null) {
        throw Exception('Operator not found');
      }

      final response = await _supabase
          .from('drivers')
          .select('''
            id,
            profile_id,
            license_number,
            license_image_url,
            status,
            vehicle_plate,
            route_id,
            puv_type,
            active,
            created_at,
            profiles!inner(
              first_name,
              last_name
            ),
            routes(
              name,
              code
            )
          ''')
          .eq('operator_id', operatorInfo.id)
          .or('license_number.ilike.%$query%,vehicle_plate.ilike.%$query%,routes.code.ilike.%$query%')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => OperatorDriver.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search drivers: $e');
    }
  }

  /// Get active drivers count
  Future<int> getActiveDriversCount() async {
    try {
      final operatorInfo = await getCurrentOperatorInfo();
      if (operatorInfo == null) return 0;

        final response = await _supabase
          .from('drivers')
          .select('id')
          .eq('operator_id', operatorInfo.id)
          .eq('status', true)
          .eq('active', true);

        return (response as List).length;
    } catch (e) {
      throw Exception('Failed to get active drivers count: $e');
    }
  }
}