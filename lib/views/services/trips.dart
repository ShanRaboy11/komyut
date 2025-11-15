import 'package:supabase_flutter/supabase_flutter.dart';

class TripsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get analytics data for different time ranges
  Future<Map<String, dynamic>> getAnalytics({
    required String timeRange,
    required int rangeOffset,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_trip_analytics',
        params: {
          'time_range': timeRange.toLowerCase().replaceAll(' ', '_'),
          'range_offset': rangeOffset,
        },
      );

      if (response == null || (response as List).isEmpty) {
        return {
          'period': '',
          'total_trips': 0,
          'total_distance': 0.0,
          'total_spent': 0.0,
        };
      }

      final data = response[0];
      return {
        'period': data['period'] ?? '',
        'total_trips': data['total_trips'] ?? 0,
        'total_distance': (data['total_distance'] ?? 0.0).toDouble(),
        'total_spent': (data['total_spent'] ?? 0.0).toDouble(),
      };
    } catch (e) {
      print('Error fetching analytics: $e');
      rethrow;
    }
  }

  // Get chart data for line graph
  Future<List<ChartDataPoint>> getChartData({
    required String timeRange,
    required int rangeOffset,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_trip_chart_data',
        params: {
          'time_range': timeRange.toLowerCase().replaceAll(' ', '_'),
          'range_offset': rangeOffset,
        },
      );

      if (response == null) return [];

      return (response as List).map((item) {
        return ChartDataPoint(
          label: item['x_label'] ?? '',
          count: (item['trip_count'] ?? 0).toInt(),
        );
      }).toList();
    } catch (e) {
      print('Error fetching chart data: $e');
      rethrow;
    }
  }

  // Get recent trips
  Future<List<TripItem>> getRecentTrips({int limit = 10}) async {
    try {
      final response = await _supabase.rpc(
        'get_recent_trips',
        params: {'limit_count': limit},
      );

      if (response == null) return [];

      return (response as List).map((item) {
        return TripItem(
          tripId: item['trip_id'] ?? '',
          date: item['trip_date'] ?? '',
          time: item['trip_time'] ?? '',
          from: item['origin_name'] ?? '',
          to: item['destination_name'] ?? '',
          tripCode: item['route_code'] ?? '',
          status: item['trip_status'] ?? 'completed',
          fareAmount: (item['fare_amount'] ?? 0.0).toDouble(),
          distanceKm: (item['distance_km'] ?? 0.0).toDouble(),
        );
      }).toList();
    } catch (e) {
      print('Error fetching recent trips: $e');
      rethrow;
    }
  }

  // Get all trips with optional filters
  Future<List<TripItem>> getAllTrips({
    String? statusFilter,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_all_trips',
        params: {
          'status_filter': statusFilter,
          'date_from': dateFrom?.toIso8601String(),
          'date_to': dateTo?.toIso8601String(),
        },
      );

      if (response == null) return [];

      return (response as List).map((item) {
        return TripItem(
          tripId: item['trip_id'] ?? '',
          date: item['trip_date'] ?? '',
          time: item['trip_time'] ?? '',
          from: item['origin_name'] ?? '',
          to: item['destination_name'] ?? '',
          tripCode: item['route_code'] ?? '',
          status: item['trip_status'] ?? 'completed',
          fareAmount: (item['fare_amount'] ?? 0.0).toDouble(),
          distanceKm: (item['distance_km'] ?? 0.0).toDouble(),
          driverName: item['driver_name'],
          vehiclePlate: item['vehicle_plate'],
        );
      }).toList();
    } catch (e) {
      print('Error fetching all trips: $e');
      rethrow;
    }
  }
}