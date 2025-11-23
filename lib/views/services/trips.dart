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
      final now = DateTime.now().toUtc();
      DateTime start;
      DateTime end;

      switch (timeRange.toLowerCase()) {
        case 'weekly':
          // Calculate the start of the target week
          // rangeOffset 0 = current week, -1 = last week, etc.
          final targetDate = now.add(Duration(days: rangeOffset * 7));
          // Get the Monday of that week (weekday 1 = Monday)
          final daysFromMonday = (targetDate.weekday - 1) % 7;
          start = DateTime(targetDate.year, targetDate.month, targetDate.day)
              .subtract(Duration(days: daysFromMonday));
          end = start.add(Duration(days: 7)).subtract(Duration(seconds: 1));
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
          
        default: // 'all trips'
          start = DateTime.fromMillisecondsSinceEpoch(0).toUtc();
          end = now.add(Duration(days: 1));
      }

      developer.log('Fetching analytics from $start to $end', name: 'TripsService');

      // Build and execute query inside the retry lambda to avoid assigning
      // a transform builder back to a filter builder variable (type mismatch).
      final res = await _withRetries(() {
        var q = _supabase.from('trips').select('id,started_at,fare_amount,distance_meters');
        if (timeRange.toLowerCase() != 'all trips') {
          q = q.gte('started_at', start.toIso8601String()).lte('started_at', end.toIso8601String());
        }
        return q.order('started_at', ascending: false).limit(1000);
      });

      final rows = res as List;

      final totalTrips = rows.length;
      final totalDistance = rows.fold<double>(
          0.0, 
          (acc, r) => acc + ((r['distance_meters'] ?? 0) as num).toDouble() / 1000.0
      );
      final totalSpent = rows.fold<double>(
          0.0, 
          (acc, r) => acc + ((r['fare_amount'] ?? 0) as num).toDouble()
      );

      // Generate period label
      String periodLabel;
      if (timeRange.toLowerCase() == 'weekly') {
        final weekStart = start.toLocal();
        final weekEnd = end.toLocal();
        periodLabel = '${weekStart.month}/${weekStart.day} - ${weekEnd.month}/${weekEnd.day}';
      } else if (timeRange.toLowerCase() == 'monthly') {
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        periodLabel = '${months[start.month - 1]} ${start.year}';
      } else if (timeRange.toLowerCase() == 'yearly') {
        periodLabel = '${start.year}';
      } else {
        periodLabel = 'All Time';
      }

      developer.log('Analytics: $totalTrips trips, $totalDistance km, ₱$totalSpent', 
          name: 'TripsService');

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
      final now = DateTime.now();
      DateTime start;
      DateTime end;

      switch (timeRange.toLowerCase()) {
        case 'weekly':
          // Calculate the start of the target week
          final targetDate = now.add(Duration(days: rangeOffset * 7));
          final daysFromMonday = (targetDate.weekday - 1) % 7;
          start = DateTime(targetDate.year, targetDate.month, targetDate.day)
              .subtract(Duration(days: daysFromMonday));
          end = start.add(Duration(days: 7)).subtract(Duration(seconds: 1));
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
          start = DateTime.fromMillisecondsSinceEpoch(0);
          end = now.add(Duration(days: 1));
      }

      // Query with date filters
      final res = await _withRetries(() {
        var q = _supabase.from('trips').select('id,started_at');
        if (timeRange.toLowerCase() != 'all trips') {
          q = q.gte('started_at', start.toUtc().toIso8601String()).lte('started_at', end.toUtc().toIso8601String());
        }
        return q.order('started_at', ascending: true).limit(1000);
      });

      final rows = (res as List)
          .map((r) => DateTime.parse(r['started_at']).toLocal())
          .toList();

      List<ChartDataPoint> points = [];

      if (timeRange.toLowerCase() == 'weekly') {
        // Generate 7 days from start
        for (int i = 0; i < 7; i++) {
          final day = start.add(Duration(days: i));
          final count = rows.where((d) => 
              d.year == day.year && 
              d.month == day.month && 
              d.day == day.day
          ).length;
          
          final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
          points.add(ChartDataPoint(
              label: weekdays[i], 
              count: count
          ));
        }
      } else if (timeRange.toLowerCase() == 'monthly') {
        // Show last 30 days of the month or full month
        final daysInRange = end.difference(start).inDays + 1;
        final daysToShow = daysInRange > 30 ? 30 : daysInRange;
        
        for (int i = 0; i < daysToShow; i++) {
          final day = end.subtract(Duration(days: daysToShow - 1 - i));
          final count = rows.where((d) => 
              d.year == day.year && 
              d.month == day.month && 
              d.day == day.day
          ).length;
          
          points.add(ChartDataPoint(
              label: '${day.day}', 
              count: count
          ));
        }
      } else if (timeRange.toLowerCase() == 'yearly') {
        // Show all 12 months
        for (int m = 0; m < 12; m++) {
          final month = DateTime(start.year, m + 1, 1);
          final count = rows.where((d) => 
              d.year == month.year && 
              d.month == month.month
          ).length;
          
          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                         'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          points.add(ChartDataPoint(
              label: months[m], 
              count: count
          ));
        }
      } else {
        // All trips - show last 12 months
        for (int m = 11; m >= 0; m--) {
          final month = DateTime(now.year, now.month - m, 1);
          final count = rows.where((d) => 
              d.year == month.year && 
              d.month == month.month
          ).length;
          
          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                         'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          points.add(ChartDataPoint(
              label: months[month.month - 1], 
              count: count
          ));
        }
      }

      developer.log('Chart data: ${points.length} points', name: 'TripsService');
      return points;
    } catch (e) {
      developer.log('Error fetching chart data: $e', name: 'TripsService');
      rethrow;
    }
  }

  // Helper to resolve driver information
  Future<Map<String, String?>> _resolveDriverInfo(String driverId) async {
    try {
      final dRes = await _withRetries(() => _supabase
          .from('drivers')
          .select('profile_id,vehicle_plate,operator_name')
          .eq('id', driverId)
          .maybeSingle());

      if (dRes == null) {
        return {'driverName': null, 'vehiclePlate': null};
      }

      String? driverName;
      final vehiclePlate = dRes['vehicle_plate'] as String?;
      final profileId = dRes['profile_id'];

      if (profileId != null) {
        try {
          final pRes = await _withRetries(() => _supabase
              .from('profiles')
              .select('first_name,last_name')
              .eq('id', profileId)
              .maybeSingle());
          
          if (pRes != null) {
            final firstName = (pRes['first_name'] as String? ?? '').trim();
            final lastName = (pRes['last_name'] as String? ?? '').trim();
            
            if (firstName.isNotEmpty || lastName.isNotEmpty) {
              driverName = '$firstName $lastName'.trim();
            }
          }
        } catch (e) {
          developer.log('Error fetching profile: $e', name: 'TripsService');
        }
      }

      // Fallback to operator name
      driverName ??= (dRes['operator_name'] as String?)?.trim();
      
      // Validate driver name
      if (driverName != null && (driverName.isEmpty || driverName.toLowerCase() == 'null')) {
        driverName = null;
      }

      return {
        'driverName': driverName,
        'vehiclePlate': vehiclePlate,
      };
    } catch (e) {
      developer.log('Error resolving driver info: $e', name: 'TripsService');
      return {'driverName': null, 'vehiclePlate': null};
    }
  }

  // Helper to fetch route stops for a route
  Future<List<Map<String, dynamic>>> _fetchRouteStops(String routeId) async {
    try {
      final res = await _withRetries(() => _supabase
          .from('route_stops')
          .select('id,name,sequence,latitude,longitude')
          .eq('route_id', routeId)
          .order('sequence', ascending: true));

      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      developer.log('Error fetching route stops: $e', name: 'TripsService');
      return [];
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

        String routeCode = '';
        String originName = '';
        String destName = '';

        // Resolve route code
        if (r['route_id'] != null) {
          try {
            final routeRes = await _supabase
                .from('routes')
                .select('code')
                .eq('id', r['route_id'])
                .maybeSingle();
            if (routeRes != null) {
              routeCode = routeRes['code'] ?? '';
            }
          } catch (_) {}
        }

        // Resolve stop names
        if (r['origin_stop_id'] != null) {
          try {
            final oRes = await _supabase
                .from('route_stops')
                .select('name')
                .eq('id', r['origin_stop_id'])
                .maybeSingle();
            if (oRes != null) {
              originName = oRes['name'] ?? '';
            }
          } catch (_) {}
        }
        if (r['destination_stop_id'] != null) {
          try {
            final dRes = await _supabase
                .from('route_stops')
                .select('name')
                .eq('id', r['destination_stop_id'])
                .maybeSingle();
            if (dRes != null) {
              destName = dRes['name'] ?? '';
            }
          } catch (_) {}
        }

        // Resolve driver info
        String? driverName;
        String? vehiclePlate;
        if (r['driver_id'] != null) {
          final driverInfo = await _resolveDriverInfo(r['driver_id']);
          driverName = driverInfo['driverName'];
          vehiclePlate = driverInfo['vehiclePlate'];
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
      var query = _supabase
          .from('trips')
          .select('id,started_at,fare_amount,distance_meters,route_id,origin_stop_id,destination_stop_id,status,driver_id');

      if (statusFilter != null && statusFilter.isNotEmpty) {
        query = query.eq('status', statusFilter);
      }
      if (dateFrom != null) {
        query = query.gte('started_at', dateFrom.toIso8601String());
      }
      if (dateTo != null) {
        query = query.lte('started_at', dateTo.toIso8601String());
      }

      final res = await _withRetries(() => query
          .order('started_at', ascending: false)
          .limit(1000));
      final rows = res as List;

      List<TripItem> items = [];
      for (var r in rows) {
        final started = DateTime.parse(r['started_at']).toLocal();
        final dateStr = '${started.month}/${started.day}/${started.year}';
        final timeStr = '${started.hour.toString().padLeft(2, '0')}:${started.minute.toString().padLeft(2, '0')}';

        String routeCode = '';
        String originName = '';
        String destName = '';

        if (r['route_id'] != null) {
          try {
            final routeRes = await _supabase
                .from('routes')
                .select('code')
                .eq('id', r['route_id'])
                .maybeSingle();
            if (routeRes != null) {
              routeCode = routeRes['code'] ?? '';
            }
          } catch (_) {}
        }
        if (r['origin_stop_id'] != null) {
          try {
            final oRes = await _supabase
                .from('route_stops')
                .select('name')
                .eq('id', r['origin_stop_id'])
                .maybeSingle();
            if (oRes != null) {
              originName = oRes['name'] ?? '';
            }
          } catch (_) {}
        }
        if (r['destination_stop_id'] != null) {
          try {
            final dRes = await _supabase
                .from('route_stops')
                .select('name')
                .eq('id', r['destination_stop_id'])
                .maybeSingle();
            if (dRes != null) {
              destName = dRes['name'] ?? '';
            }
          } catch (_) {}
        }

        String? driverName;
        String? vehiclePlate;
        if (r['driver_id'] != null) {
          final driverInfo = await _resolveDriverInfo(r['driver_id']);
          driverName = driverInfo['driverName'];
          vehiclePlate = driverInfo['vehiclePlate'];
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

  // Get detailed trip by id with dynamic route stops
  Future<TripDetails?> getTripDetails(String tripId) async {
    try {
      final res = await _withRetries(() => _supabase
          .from('trips')
          .select('''
            id,
            started_at,
            ended_at,
            fare_amount,
            distance_meters,
            route_id,
            origin_stop_id,
            destination_stop_id,
            status,
            driver_id,
            passengers_count,
            creator_profile:profiles!trips_created_by_profile_id_fkey(first_name,last_name)
          ''')
          .eq('id', tripId)
          .single());

      final started = DateTime.parse(res['started_at']).toLocal();
      DateTime? ended;
      if (res['ended_at'] != null) {
        ended = DateTime.parse(res['ended_at']).toLocal();
      }

      // Fetch route stops dynamically from route_stops table
      List<Map<String, dynamic>>? routeStops;
      if (res['route_id'] != null) {
        routeStops = await _fetchRouteStops(res['route_id']);
      }

      // Resolve driver info
      String? driverName;
      String? vehiclePlate;
      if (res['driver_id'] != null) {
        final driverInfo = await _resolveDriverInfo(res['driver_id']);
        driverName = driverInfo['driverName'];
        vehiclePlate = driverInfo['vehiclePlate'];
      }

      // Resolve route code and stop names
      String routeCode = '';
      String originName = '';
      String destName = '';
      
      if (res['route_id'] != null) {
        try {
          final rRes = await _supabase
              .from('routes')
              .select('code')
              .eq('id', res['route_id'])
              .maybeSingle();
          if (rRes != null) routeCode = rRes['code'] ?? '';
        } catch (_) {}
      }
      
      if (res['origin_stop_id'] != null) {
        try {
          final oRes = await _supabase
              .from('route_stops')
              .select('name')
              .eq('id', res['origin_stop_id'])
              .maybeSingle();
          if (oRes != null) originName = oRes['name'] ?? '';
        } catch (_) {}
      }
      
      if (res['destination_stop_id'] != null) {
        try {
          final dRes = await _supabase
              .from('route_stops')
              .select('name')
              .eq('id', res['destination_stop_id'])
              .maybeSingle();
          if (dRes != null) destName = dRes['name'] ?? '';
        } catch (_) {}
      }

      // Resolve transaction number for this trip (if any)
      String? transactionNumber;
      try {
        final tRes = await _withRetries(() => _supabase
            .from('transactions')
            .select('transaction_number')
            .eq('related_trip_id', res['id'])
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle());

        if (tRes != null) {
          transactionNumber = tRes['transaction_number'] as String?;
        }
      } catch (_) {
        transactionNumber = null;
      }

      // Extract passenger name from joined creator_profile (if present)
      String? passengerName;
      try {
        if (res['creator_profile'] != null && res['creator_profile'] is Map) {
          final cp = res['creator_profile'] as Map;
          final fn = (cp['first_name'] as String?)?.trim() ?? '';
          final ln = (cp['last_name'] as String?)?.trim() ?? '';
          final combined = ('$fn $ln').trim();
          if (combined.isNotEmpty) passengerName = combined;
        }
      } catch (_) {
        passengerName = null;
      }

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
        driverName: driverName ?? 'Unknown Driver',
        vehiclePlate: vehiclePlate ?? 'N/A',
        startedAt: started,
        endedAt: ended,
        passengerCount: (res['passengers_count'] ?? 1) as int,
        originStopId: res['origin_stop_id']?.toString(),
        destinationStopId: res['destination_stop_id']?.toString(),
        routeStops: routeStops,
        originLat: null,
        originLng: null,
        destLat: null,
        destLng: null,
        transactionNumber: transactionNumber,
        passengerName: passengerName,
      );
    } catch (e) {
      developer.log('Error fetching trip details: $e', name: 'TripsService');
      rethrow;
    }
  }

  // Helper to retry transient network errors
  Future<T> _withRetries<T>(Future<T> Function() fn, {int maxAttempts = 3}) async {
    int attempt = 0;
    while (true) {
      attempt++;
      try {
        return await fn();
      } catch (e) {
        final isSocket = e is SocketException || 
                         (e.toString().toLowerCase().contains('connection reset') || 
                          e.toString().toLowerCase().contains('socketexception'));
        if (!isSocket || attempt >= maxAttempts) rethrow;
        final waitMs = 200 * attempt;
        await Future.delayed(Duration(milliseconds: waitMs));
      }
    }
  }
}