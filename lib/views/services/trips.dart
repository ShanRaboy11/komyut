import 'dart:io';
import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/trips.dart';

class TripsService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Get analytics data for different time ranges
  Future<Map<String, dynamic>> getAnalytics({
    required String timeRange,
    required int rangeOffset,
  }) async {
    try {
      // Determine date range based on timeRange and rangeOffset
      final now = DateTime.now().toUtc();
      DateTime start;
      DateTime end = now;

      switch (timeRange.toLowerCase()) {
        case 'weekly':
          // start of the week (7 days) shifted by rangeOffset
          final base = now.subtract(Duration(days: rangeOffset * 7));
          start = DateTime(base.year, base.month, base.day).subtract(Duration(days: 6));
          break;
        case 'monthly':
          final monthBase = DateTime(now.year, now.month - rangeOffset, 1);
          start = DateTime(monthBase.year, monthBase.month, 1);
          end = DateTime(monthBase.year, monthBase.month + 1, 1).subtract(Duration(seconds: 1));
          break;
        case 'yearly':
          final yearBase = DateTime(now.year - rangeOffset, 1, 1);
          start = DateTime(yearBase.year, 1, 1);
          end = DateTime(yearBase.year + 1, 1, 1).subtract(Duration(seconds: 1));
          break;
        default:
          // All trips
          start = DateTime.fromMillisecondsSinceEpoch(0).toUtc();
      }

      // Query trips within range
      final res = await _withRetries(() => _supabase.from('trips').select('id,started_at,fare_amount,distance_meters').order('started_at', ascending: false).limit(1000));

      final rows = (res as List).where((r) {
        if (start.isAtSameMomentAs(DateTime.fromMillisecondsSinceEpoch(0).toUtc())) return true;
        final started = DateTime.parse(r['started_at']).toUtc();
        return !started.isBefore(start) && !started.isAfter(end);
      }).toList();

      final totalTrips = rows.length;
      final totalDistance = rows.fold<double>(0.0, (acc, r) => acc + ((r['distance_meters'] ?? 0) as num).toDouble() / 1000.0);
      final totalSpent = rows.fold<double>(0.0, (acc, r) => acc + ((r['fare_amount'] ?? 0) as num).toDouble());

      String periodLabel;
      if (timeRange.toLowerCase() == 'weekly') {
        final weekStart = start.toLocal();
        final weekEnd = end.toLocal();
        periodLabel = '${weekStart.month}/${weekStart.day} - ${weekEnd.month}/${weekEnd.day}';
      } else if (timeRange.toLowerCase() == 'monthly') {
        periodLabel = '${start.month}/${start.year}';
      } else if (timeRange.toLowerCase() == 'yearly') {
        periodLabel = '${start.year}';
      } else {
        periodLabel = 'All Trips';
      }

      return {
        'period': periodLabel,
        'total_trips': totalTrips,
        'total_distance': totalDistance,
        'total_spent': totalSpent,
      };
    } catch (e) {
      developer.log('Error fetching analytics: $e', name: 'TripsService');
      rethrow;
    }
  }

  // Get chart data for line graph
  Future<List<ChartDataPoint>> getChartData({
    required String timeRange,
    required int rangeOffset,
  }) async {
    try {
      // Fetch recent trips and aggregate on client side
      final res = await _withRetries(() => _supabase.from('trips').select('id,started_at').order('started_at', ascending: true).limit(1000));

      final rows = (res as List).map((r) => DateTime.parse(r['started_at']).toLocal()).toList();

      List<ChartDataPoint> points = [];
      if (timeRange.toLowerCase() == 'weekly') {
        // last 7 days
        final now = DateTime.now();
        for (int i = 6; i >= 0; i--) {
          final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
          final count = rows.where((d) => d.year == day.year && d.month == day.month && d.day == day.day).length;
          points.add(ChartDataPoint(label: '${day.month}/${day.day}', count: count));
        }
      } else if (timeRange.toLowerCase() == 'monthly') {
        final now = DateTime.now();
        for (int i = 29; i >= 0; i--) {
          final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
          final count = rows.where((d) => d.year == day.year && d.month == day.month && d.day == day.day).length;
          points.add(ChartDataPoint(label: '${day.month}/${day.day}', count: count));
        }
      } else if (timeRange.toLowerCase() == 'yearly') {
        final now = DateTime.now();
        for (int m = 11; m >= 0; m--) {
          final month = DateTime(now.year, now.month - m, 1);
          final count = rows.where((d) => d.year == month.year && d.month == month.month).length;
          points.add(ChartDataPoint(label: '${month.month}/${month.year}', count: count));
        }
      } else {
        // All trips grouped by month (last 12 months)
        final now = DateTime.now();
        for (int m = 11; m >= 0; m--) {
          final month = DateTime(now.year, now.month - m, 1);
          final count = rows.where((d) => d.year == month.year && d.month == month.month).length;
          points.add(ChartDataPoint(label: '${month.month}/${month.year}', count: count));
        }
      }

      return points;
    } catch (e) {
      developer.log('Error fetching chart data: $e', name: 'TripsService');
      rethrow;
    }
  }

  // Get recent trips
  Future<List<TripItem>> getRecentTrips({int limit = 10}) async {
    try {
        final res = await _withRetries(() => _supabase
          .from('trips')
          .select('id,started_at,fare_amount,distance_meters,route_id,origin_stop_id,destination_stop_id,status,driver_id')
          .order('started_at', ascending: false)
          .limit(limit));

        final rows = res as List;
      List<TripItem> items = [];
      for (var r in rows) {
        final started = DateTime.parse(r['started_at']).toLocal();
        final dateStr = '${started.month}/${started.day}/${started.year}';
        final timeStr = '${started.hour.toString().padLeft(2, '0')}:${started.minute.toString().padLeft(2, '0')}';

        // Try to resolve route code and stop names if available
        String routeCode = '';
        String originName = '';
        String destName = '';
        String? driverName;
        String? vehiclePlate;
        if (r['route_id'] != null) {
          final routeRes = await _supabase.from('routes').select('code,name').eq('id', r['route_id']).single();
          routeCode = routeRes['code'] ?? '';
        }
        if (r['origin_stop_id'] != null) {
          final oRes = await _supabase.from('route_stops').select('name').eq('id', r['origin_stop_id']).single();
          originName = oRes['name'] ?? '';
        }
        if (r['destination_stop_id'] != null) {
          final dRes = await _supabase.from('route_stops').select('name').eq('id', r['destination_stop_id']).single();
          destName = dRes['name'] ?? '';
        }
        if (r['driver_id'] != null) {
          try {
            final dRes = await _withRetries(() => _supabase.from('drivers').select('profile_id,vehicle_plate,operator_name').eq('id', r['driver_id']).single());
            vehiclePlate = dRes['vehicle_plate'];
            final profileId = dRes['profile_id'];
            if (profileId != null) {
              final pRes = await _withRetries(() => _supabase.from('profiles').select('first_name,last_name').eq('id', profileId).single());
              driverName = '${pRes['first_name'] ?? ''} ${pRes['last_name'] ?? ''}'.trim();
              if (driverName.isEmpty) driverName = null;
            }
            driverName ??= dRes['operator_name'];
          } catch (_) {
            // ignore
          }
        }

        items.add(TripItem(
          tripId: r['id'] ?? '',
          date: dateStr,
          time: timeStr,
          from: originName,
          to: destName,
          tripCode: routeCode,
          status: (r['status'] ?? 'completed').toString(),
          fareAmount: ((r['fare_amount'] ?? 0) as num).toDouble(),
          distanceKm: (((r['distance_meters'] ?? 0) as num).toDouble() / 1000.0),
          driverName: driverName,
          vehiclePlate: vehiclePlate,
        ));
      }

      return items;
    } catch (e) {
      developer.log('Error fetching recent trips: $e', name: 'TripsService');
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
      final query = _supabase.from('trips').select('id,started_at,fare_amount,distance_meters,route_id,origin_stop_id,destination_stop_id,status,driver_id');

      if (statusFilter != null && statusFilter.isNotEmpty) {
        query.eq('status', statusFilter);
      }
      if (dateFrom != null) {
        query.gte('started_at', dateFrom.toIso8601String());
      }
      if (dateTo != null) {
        query.lte('started_at', dateTo.toIso8601String());
      }

      final res = await _withRetries(() => query.order('started_at', ascending: false).limit(1000));
      final rows = res as List;

      List<TripItem> items = [];
      for (var r in rows) {
        final started = DateTime.parse(r['started_at']).toLocal();
        final dateStr = '${started.month}/${started.day}/${started.year}';
        final timeStr = '${started.hour.toString().padLeft(2, '0')}:${started.minute.toString().padLeft(2, '0')}';

        String routeCode = '';
        String originName = '';
        String destName = '';
        String? driverName;
        String? vehiclePlate;

        if (r['route_id'] != null) {
          try {
            final routeRes = await _supabase.from('routes').select('code').eq('id', r['route_id']).single();
            routeCode = routeRes['code'] ?? '';
          } catch (_) {}
        }
        if (r['origin_stop_id'] != null) {
          try {
            final oRes = await _supabase.from('route_stops').select('name').eq('id', r['origin_stop_id']).single();
            originName = oRes['name'] ?? '';
          } catch (_) {}
        }
        if (r['destination_stop_id'] != null) {
          try {
            final dRes = await _supabase.from('route_stops').select('name').eq('id', r['destination_stop_id']).single();
            destName = dRes['name'] ?? '';
          } catch (_) {}
        }

        if (r['driver_id'] != null) {
          try {
            final dRes = await _withRetries(() => _supabase.from('drivers').select('profile_id,vehicle_plate,operator_name').eq('id', r['driver_id']).single());
            vehiclePlate = dRes['vehicle_plate'];
            final profileId = dRes['profile_id'];
            if (profileId != null) {
              try {
                final pRes = await _withRetries(() => _supabase.from('profiles').select('first_name,last_name').eq('id', profileId).single());
                driverName = '${pRes['first_name'] ?? ''} ${pRes['last_name'] ?? ''}'.trim();
                if (driverName.isEmpty) driverName = null;
              } catch (_) {}
            }
            driverName ??= dRes['operator_name'];
          } catch (_) {
            // ignore driver resolution errors
          }
        }

        items.add(TripItem(
          tripId: r['id'] ?? '',
          date: dateStr,
          time: timeStr,
          from: originName,
          to: destName,
          tripCode: routeCode,
          status: (r['status'] ?? 'completed').toString(),
          fareAmount: ((r['fare_amount'] ?? 0) as num).toDouble(),
          distanceKm: (((r['distance_meters'] ?? 0) as num).toDouble() / 1000.0),
          driverName: driverName,
          vehiclePlate: vehiclePlate,
        ));
      }

      return items;
    } catch (e) {
      developer.log('Error fetching all trips: $e', name: 'TripsService');
      rethrow;
    }
  }

  // Get detailed trip by id
  Future<TripDetails?> getTripDetails(String tripId) async {
    try {
        final res = await _withRetries(() => _supabase
          .from('trips')
          .select('id,started_at,ended_at,fare_amount,distance_meters,route_id,origin_stop_id,destination_stop_id,status,driver_id,route_stops,passenger_count')
          .eq('id', tripId)
          .single());

      final started = DateTime.parse(res['started_at']).toLocal();
      DateTime? ended;
      if (res['ended_at'] != null) {
        ended = DateTime.parse(res['ended_at']).toLocal();
      }

      List<Map<String, dynamic>>? routeStops;
      if (res['route_stops'] != null) {
        try {
          routeStops = List<Map<String, dynamic>>.from(res['route_stops']);
        } catch (_) {
          routeStops = null;
        }
      }

      // Resolve driver name if present
      String? driverName;
      String? vehiclePlate;
      if (res['driver_id'] != null) {
        try {
          final dRes = await _withRetries(() => _supabase.from('drivers').select('profile_id,vehicle_plate,operator_name,name,display_name').eq('id', res['driver_id']).single());
          vehiclePlate = dRes['vehicle_plate'];
          // prefer profile name if available
          final profileId = dRes['profile_id'];
          if (profileId != null) {
            try {
              final pRes = await _withRetries(() => _supabase.from('profiles').select('first_name,last_name').eq('id', profileId).single());
              driverName = '${pRes['first_name'] ?? ''} ${pRes['last_name'] ?? ''}'.trim();
              if (driverName.isEmpty) driverName = null;
            } catch (_) {
              // ignore
            }
          }

          // Fallbacks: driver.name, driver.display_name, operator_name
          driverName ??= (dRes['name'] as String?)?.trim();
          driverName ??= (dRes['display_name'] as String?)?.trim();
          driverName ??= (dRes['operator_name'] as String?)?.trim();
          if (driverName != null && driverName.isEmpty) driverName = null;
        } catch (_) {
          // ignore and leave driverName null
        }
      }

      // Resolve route code and stop names
      String routeCode = '';
      String originName = '';
      String destName = '';
      try {
        if (res['route_id'] != null) {
          final rRes = await _supabase.from('routes').select('code').eq('id', res['route_id']).maybeSingle();
          if (rRes != null) routeCode = rRes['code'] ?? '';
        }
      } catch (_) {}
      try {
        if (res['origin_stop_id'] != null) {
          final oRes = await _supabase.from('route_stops').select('name').eq('id', res['origin_stop_id']).maybeSingle();
          if (oRes != null) originName = oRes['name'] ?? '';
        }
      } catch (_) {}
      try {
        if (res['destination_stop_id'] != null) {
          final dRes = await _supabase.from('route_stops').select('name').eq('id', res['destination_stop_id']).maybeSingle();
          if (dRes != null) destName = dRes['name'] ?? '';
        }
      } catch (_) {}

      return TripDetails(
        tripId: res['id'] ?? '',
        date: '${started.month}/${started.day}/${started.year}',
        time: '${started.hour.toString().padLeft(2, '0')}:${started.minute.toString().padLeft(2, '0')}',
        from: originName,
        to: destName,
        tripCode: routeCode,
        status: (res['status'] ?? 'completed').toString(),
        fareAmount: ((res['fare_amount'] ?? 0) as num).toDouble(),
        distanceKm: (((res['distance_meters'] ?? 0) as num).toDouble() / 1000.0),
        driverName: driverName,
        vehiclePlate: vehiclePlate,
        startedAt: started,
        endedAt: ended,
        passengerCount: (res['passenger_count'] ?? 0) as int,
        originStopId: res['origin_stop_id']?.toString(),
        destinationStopId: res['destination_stop_id']?.toString(),
        routeStops: routeStops,
        originLat: null,
        originLng: null,
        destLat: null,
        destLng: null,
      );
    } catch (e) {
      developer.log('Error fetching trip details: $e', name: 'TripsService');
      rethrow;
    }
  }

  // helper to retry transient network errors
  Future<T> _withRetries<T>(Future<T> Function() fn, {int maxAttempts = 3}) async {
    int attempt = 0;
    while (true) {
      attempt++;
      try {
        return await fn();
      } catch (e) {
        final isSocket = e is SocketException || (e.toString().toLowerCase().contains('connection reset') || e.toString().toLowerCase().contains('socketexception'));
        if (!isSocket || attempt >= maxAttempts) rethrow;
        final waitMs = 200 * attempt;
        await Future.delayed(Duration(milliseconds: waitMs));
      }
    }
  }
}