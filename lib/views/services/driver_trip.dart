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

      // Fetch trips with route, stop, and PASSENGER information
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
            created_by_profile_id,
            routes!inner(code),
            origin_stop:route_stops!trips_origin_stop_id_fkey(name),
            destination_stop:route_stops!trips_destination_stop_id_fkey(name),
            creator_profile:profiles!trips_created_by_profile_id_fkey(first_name, last_name)
          ''')
          .eq('driver_id', driverId)
          .order('started_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      
      return data.map((json) {
        // Extract passenger name from the creator_profile
        String? passengerName;
        if (json['creator_profile'] != null && json['creator_profile'] is Map) {
          final profile = json['creator_profile'] as Map;
          final firstName = profile['first_name'] as String?;
          final lastName = profile['last_name'] as String?;
          
          if (firstName != null || lastName != null) {
            passengerName = '${firstName ?? ''} ${lastName ?? ''}'.trim();
          }
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
          'passenger_name': passengerName ?? 'Passenger',
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
            created_by_profile_id,
            routes!inner(code),
            origin_stop:route_stops!trips_origin_stop_id_fkey(name),
            destination_stop:route_stops!trips_destination_stop_id_fkey(name),
            creator_profile:profiles!trips_created_by_profile_id_fkey(first_name, last_name)
          ''')
          .eq('id', tripId)
          .single();

      // Extract passenger name from the creator_profile
      String? passengerName;
      if (response['creator_profile'] != null && response['creator_profile'] is Map) {
        final profile = response['creator_profile'] as Map;
        final firstName = profile['first_name'] as String?;
        final lastName = profile['last_name'] as String?;
        
        if (firstName != null || lastName != null) {
          passengerName = '${firstName ?? ''} ${lastName ?? ''}'.trim();
        }
      }

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
        'passenger_name': passengerName ?? 'Passenger',
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
            created_by_profile_id,
            routes!inner(code),
            origin_stop:route_stops!trips_origin_stop_id_fkey(name),
            destination_stop:route_stops!trips_destination_stop_id_fkey(name),
            creator_profile:profiles!trips_created_by_profile_id_fkey(first_name, last_name)
          ''')
          .eq('driver_id', driverId)
          .eq('status', status)
          .order('started_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      
      return data.map((json) {
        // Extract passenger name from the creator_profile
        String? passengerName;
        if (json['creator_profile'] != null && json['creator_profile'] is Map) {
          final profile = json['creator_profile'] as Map;
          final firstName = profile['first_name'] as String?;
          final lastName = profile['last_name'] as String?;
          
          if (firstName != null || lastName != null) {
            passengerName = '${firstName ?? ''} ${lastName ?? ''}'.trim();
          }
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
          'passenger_name': passengerName ?? 'Passenger',
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