import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/driver_trip.dart';

class DriverTripService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get trip history for the currently authenticated driver
  Future<List<DriverTrip>> getDriverTripHistory() async {
    try {
      // Get the current user
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get driver ID from profile
      final profileResponse = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .single();

      final profileId = profileResponse['id'] as String;

      final driverResponse = await _supabase
          .from('drivers')
          .select('id')
          .eq('profile_id', profileId)
          .single();

      final driverId = driverResponse['id'] as String;

      // Fetch trips with route and stop information
      final response = await _supabase
          .from('trips')
          .select('''
            id,
            status,
            started_at,
            ended_at,
            fare_amount,
            passengers_count,
            distance_meters,
            routes!inner(code),
            origin_stop:route_stops!trips_origin_stop_id_fkey(name),
            destination_stop:route_stops!trips_destination_stop_id_fkey(name)
          ''')
          .eq('driver_id', driverId)
          .order('started_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      
      return data.map((json) {
        // Transform the nested JSON structure
        String? _passengerName;
        try {
          if (json['passenger_name'] != null) {
            _passengerName = json['passenger_name'] as String?;
          } else if (json['passenger'] != null && json['passenger'] is Map) {
            _passengerName = (json['passenger'] as Map)['name'] as String?;
          } else if (json['passengers'] != null && json['passengers'] is List && (json['passengers'] as List).isNotEmpty) {
            final first = (json['passengers'] as List).first;
            if (first != null && first is Map && first['name'] != null) {
              _passengerName = first['name'] as String?;
            }
          }
        } catch (_) {
          _passengerName = null;
        }

        final transformedJson = {
          'id': json['id'],
          'status': json['status'],
          'started_at': json['started_at'],
          'ended_at': json['ended_at'],
          'fare_amount': json['fare_amount'],
          'passengers_count': json['passengers_count'],
          'distance_meters': json['distance_meters'],
          'route_code': json['routes']?['code'] ?? 'N/A',
          'origin_name': json['origin_stop']?['name'] ?? 'Unknown',
          'destination_name': json['destination_stop']?['name'] ?? 'Unknown',
          'passenger_name': _passengerName,
        };
        
        return DriverTrip.fromJson(transformedJson);
      }).toList();
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load trip history: $e');
    }
  }

  /// Get a single trip by ID
  Future<DriverTrip?> getTripById(String tripId) async {
    try {
      final response = await _supabase
          .from('trips')
          .select('''
            id,
            status,
            started_at,
            ended_at,
            fare_amount,
            passengers_count,
            distance_meters,
            routes!inner(code),
            origin_stop:route_stops!trips_origin_stop_id_fkey(name),
            destination_stop:route_stops!trips_destination_stop_id_fkey(name)
          ''')
          .eq('id', tripId)
          .single();

      final transformedJson = {
        'id': response['id'],
        'status': response['status'],
        'started_at': response['started_at'],
        'ended_at': response['ended_at'],
        'fare_amount': response['fare_amount'],
        'passengers_count': response['passengers_count'],
        'distance_meters': response['distance_meters'],
        'route_code': response['routes']?['code'] ?? 'N/A',
        'origin_name': response['origin_stop']?['name'] ?? 'Unknown',
        'destination_name': response['destination_stop']?['name'] ?? 'Unknown',
        'passenger_name': response['passenger_name'] as String? ?? response['passenger']?['name'] as String?,
      };

      return DriverTrip.fromJson(transformedJson);
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      return null;
    }
  }

  /// Get trips filtered by status
  Future<List<DriverTrip>> getTripsByStatus(String status) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final profileResponse = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .single();

      final profileId = profileResponse['id'] as String;

      final driverResponse = await _supabase
          .from('drivers')
          .select('id')
          .eq('profile_id', profileId)
          .single();

      final driverId = driverResponse['id'] as String;

      final response = await _supabase
          .from('trips')
          .select('''
            id,
            status,
            started_at,
            ended_at,
            fare_amount,
            passengers_count,
            distance_meters,
            routes!inner(code),
            origin_stop:route_stops!trips_origin_stop_id_fkey(name),
            destination_stop:route_stops!trips_destination_stop_id_fkey(name)
          ''')
          .eq('driver_id', driverId)
          .eq('status', status)
          .order('started_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      
      return data.map((json) {
        String? _passengerName;
        try {
          if (json['passenger_name'] != null) {
            _passengerName = json['passenger_name'] as String?;
          } else if (json['passenger'] != null && json['passenger'] is Map) {
            _passengerName = (json['passenger'] as Map)['name'] as String?;
          } else if (json['passengers'] != null && json['passengers'] is List && (json['passengers'] as List).isNotEmpty) {
            final first = (json['passengers'] as List).first;
            if (first != null && first is Map && first['name'] != null) {
              _passengerName = first['name'] as String?;
            }
          }
        } catch (_) {
          _passengerName = null;
        }

        final transformedJson = {
          'id': json['id'],
          'status': json['status'],
          'started_at': json['started_at'],
          'ended_at': json['ended_at'],
          'fare_amount': json['fare_amount'],
          'passengers_count': json['passengers_count'],
          'distance_meters': json['distance_meters'],
          'route_code': json['routes']?['code'] ?? 'N/A',
          'origin_name': json['origin_stop']?['name'] ?? 'Unknown',
          'destination_name': json['destination_stop']?['name'] ?? 'Unknown',
          'passenger_name': _passengerName,
        };
        
        return DriverTrip.fromJson(transformedJson);
      }).toList();
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load trips: $e');
    }
  }
}