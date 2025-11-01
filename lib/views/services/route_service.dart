import 'package:supabase_flutter/supabase_flutter.dart';

class RouteService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Search routes by place name
  /// This is the core function for your Route Finder feature
  Future<List<RouteSearchResult>> searchRoutesByPlace(String placeName) async {
    try {
      // Search for places that match the query
      final response = await _supabase
          .from('route_stops')
          .select('''
            id,
            name,
            sequence,
            latitude,
            longitude,
            routes:route_id (
              id,
              code,
              name,
              description
            )
          ''')
          .ilike('name', '%$placeName%')
          .order('name', ascending: true);

      // Transform the response into a more usable format
      final results = <RouteSearchResult>[];
      final seenRoutes = <String>{};

      for (var stop in response) {
        final route = stop['routes'];
        if (route != null) {
          final routeCode = route['code'];
          
          // Avoid duplicate routes in results
          if (!seenRoutes.contains(routeCode)) {
            seenRoutes.add(routeCode);
            
            results.add(RouteSearchResult(
              routeId: route['id'],
              routeCode: routeCode,
              routeName: route['name'],
              routeDescription: route['description'],
              matchingStop: stop['name'],
              stopSequence: stop['sequence'],
            ));
          }
        }
      }

      return results;
    } catch (e) {
      throw Exception('Error searching routes: $e');
    }
  }

  /// Get all stops for a specific route
  Future<List<RouteStopDetail>> getRouteStops(String routeId) async {
    try {
      final response = await _supabase
          .from('route_stops')
          .select()
          .eq('route_id', routeId)
          .order('sequence', ascending: true);

      return response.map<RouteStopDetail>((stop) {
        return RouteStopDetail(
          id: stop['id'],
          name: stop['name'],
          sequence: stop['sequence'],
          latitude: stop['latitude'],
          longitude: stop['longitude'],
        );
      }).toList();
    } catch (e) {
      throw Exception('Error fetching route stops: $e');
    }
  }

  /// Get complete route details with stops
  Future<RouteDetail?> getRouteDetail(String routeId) async {
    try {
      final routeResponse = await _supabase
          .from('routes')
          .select()
          .eq('id', routeId)
          .single();

      final stopsResponse = await _supabase
          .from('route_stops')
          .select()
          .eq('route_id', routeId)
          .order('sequence', ascending: true);

      return RouteDetail(
        id: routeResponse['id'],
        code: routeResponse['code'],
        name: routeResponse['name'],
        description: routeResponse['description'],
        startLat: routeResponse['start_lat'],
        startLng: routeResponse['start_lng'],
        endLat: routeResponse['end_lat'],
        endLng: routeResponse['end_lng'],
        stops: stopsResponse.map<RouteStopDetail>((stop) {
          return RouteStopDetail(
            id: stop['id'],
            name: stop['name'],
            sequence: stop['sequence'],
            latitude: stop['latitude'],
            longitude: stop['longitude'],
          );
        }).toList(),
      );
    } catch (e) {
      throw Exception('Error fetching route detail: $e');
    }
  }

  /// Get all available routes
  Future<List<RouteBasic>> getAllRoutes() async {
    try {
      final response = await _supabase
          .from('routes')
          .select()
          .order('code', ascending: true);

      return response.map<RouteBasic>((route) {
        return RouteBasic(
          id: route['id'],
          code: route['code'],
          name: route['name'],
          description: route['description'],
        );
      }).toList();
    } catch (e) {
      throw Exception('Error fetching routes: $e');
    }
  }

  /// Check if a place is served by a specific route
  Future<bool> isPlaceInRoute(String routeId, String placeName) async {
    try {
      final response = await _supabase
          .from('route_stops')
          .select('id')
          .eq('route_id', routeId)
          .ilike('name', '%$placeName%')
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get nearby routes based on coordinates
  /// This uses a simple distance calculation
  /// For production, consider using PostGIS for better performance
  Future<List<RouteSearchResult>> getNearbyRoutes(
    double latitude,
    double longitude, {
    double radiusKm = 1.0,
  }) async {
    try {
      // Fetch all route stops
      final response = await _supabase
          .from('route_stops')
          .select('''
            id,
            name,
            sequence,
            latitude,
            longitude,
            routes:route_id (
              id,
              code,
              name,
              description
            )
          ''');

      final results = <RouteSearchResult>[];
      final seenRoutes = <String>{};

      for (var stop in response) {
        final stopLat = stop['latitude'] as double?;
        final stopLng = stop['longitude'] as double?;

        if (stopLat != null && stopLng != null) {
          final distance = _calculateDistance(
            latitude,
            longitude,
            stopLat,
            stopLng,
          );

          if (distance <= radiusKm) {
            final route = stop['routes'];
            if (route != null) {
              final routeCode = route['code'];

              if (!seenRoutes.contains(routeCode)) {
                seenRoutes.add(routeCode);

                results.add(RouteSearchResult(
                  routeId: route['id'],
                  routeCode: routeCode,
                  routeName: route['name'],
                  routeDescription: route['description'],
                  matchingStop: stop['name'],
                  stopSequence: stop['sequence'],
                  distanceKm: distance,
                ));
              }
            }
          }
        }
      }

      // Sort by distance
      results.sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));

      return results;
    } catch (e) {
      throw Exception('Error finding nearby routes: $e');
    }
  }

  /// Calculate distance between two coordinates using Haversine formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = (dLat / 2).sin() * (dLat / 2).sin() +
        _toRadians(lat1).cos() *
            _toRadians(lat2).cos() *
            (dLon / 2).sin() *
            (dLon / 2).sin();

    final c = 2 * (a.sqrt()).asin();

    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (3.141592653589793 / 180);
  }
}

// Models
class RouteSearchResult {
  final String routeId;
  final String routeCode;
  final String? routeName;
  final String? routeDescription;
  final String matchingStop;
  final int stopSequence;
  final double? distanceKm;

  RouteSearchResult({
    required this.routeId,
    required this.routeCode,
    this.routeName,
    this.routeDescription,
    required this.matchingStop,
    required this.stopSequence,
    this.distanceKm,
  });
}

class RouteStopDetail {
  final String id;
  final String name;
  final int sequence;
  final double latitude;
  final double longitude;

  RouteStopDetail({
    required this.id,
    required this.name,
    required this.sequence,
    required this.latitude,
    required this.longitude,
  });
}

class RouteDetail {
  final String id;
  final String code;
  final String? name;
  final String? description;
  final double? startLat;
  final double? startLng;
  final double? endLat;
  final double? endLng;
  final List<RouteStopDetail> stops;

  RouteDetail({
    required this.id,
    required this.code,
    this.name,
    this.description,
    this.startLat,
    this.startLng,
    this.endLat,
    this.endLng,
    required this.stops,
  });
}

class RouteBasic {
  final String id;
  final String code;
  final String? name;
  final String? description;

  RouteBasic({
    required this.id,
    required this.code,
    this.name,
    this.description,
  });
}