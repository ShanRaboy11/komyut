import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/notification.dart';

class NotificationDriverProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<NotifItem> _notifications = [];

  List<NotifItem> get notifications {
    // Ensure they are sorted by date (newest first)
    _notifications.sort((a, b) => b.sortDate.compareTo(a.sortDate));
    return _notifications;
  }

  Future<void> fetchNotifications() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      debugPrint("DriverNotif: No logged in user found.");
      return;
    }

    debugPrint("DriverNotif: Starting fetch for User ID: ${user.id}");

    if (_notifications.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      // 1. Get Profile ID
      final profileRes = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .single();
      final profileId = profileRes['id'];
      debugPrint("DriverNotif: Profile ID fetched: $profileId");

      // 2. Get Driver ID and Vehicle Plate
      debugPrint(
        "DriverNotif: Querying drivers table for profile_id: $profileId",
      );
      final driverRes = await _supabase
          .from('drivers')
          .select('id, vehicle_plate')
          .eq('profile_id', profileId)
          .maybeSingle();

      debugPrint("DriverNotif: Driver query result: $driverRes");

      if (driverRes == null) {
        debugPrint(
          "DriverNotif: ❌ User is not a driver - no driver record found.",
        );
        _notifications = [];
        return;
      }

      final String driverId = driverRes['id'];
      final String plate = driverRes['vehicle_plate'] ?? 'Your Jeepney';
      debugPrint("DriverNotif: ✅ Driver ID: $driverId, Vehicle plate: $plate");

      // ---------------------------------------------------------
      // A. FETCH RAW DATA
      // ---------------------------------------------------------

      // 1. Trips (Using driver_id instead of created_by_profile_id)
      debugPrint("DriverNotif: Querying trips for driver_id: $driverId");

      final tripsRes = await _supabase
          .from('trips')
          .select('id, started_at, ended_at, status, passengers_count')
          .eq('driver_id', driverId) // KEY CHANGE: Use driver_id
          .order('started_at', ascending: false)
          .limit(200);

      final List<dynamic> tripsData = tripsRes as List<dynamic>;
      debugPrint("DriverNotif: Trips found count: ${tripsData.length}");

      // 2. Read Statuses
      debugPrint("DriverNotif: Querying existing notifications table...");
      final notifRes = await _supabase
          .from('notifications')
          .select('id, read, payload, type')
          .eq('recipient_profile_id', profileId)
          .eq('type', 'trip')
          .limit(500);

      final List<Map<String, dynamic>> notifData =
          List<Map<String, dynamic>>.from(notifRes as List);
      debugPrint(
        "DriverNotif: Existing DB notifications found: ${notifData.length}",
      );

      final List<NotifItem> generatedList = [];

      // ---------------------------------------------------------
      // B. PROCESS TRIPS
      // ---------------------------------------------------------
      debugPrint("DriverNotif: ========== PROCESSING TRIPS ==========");
      int processedCount = 0;
      int skippedCount = 0;

      for (var trip in tripsData) {
        debugPrint(
          "DriverNotif: --- Processing trip ${processedCount + 1}/${tripsData.length} ---",
        );

        final String tripId = trip['id'];
        final String status = trip['status'] ?? 'ongoing';
        final int passengerCount = trip['passengers_count'] ?? 0;

        debugPrint("DriverNotif:   Trip ID: $tripId");
        debugPrint("DriverNotif:   Status: $status");
        debugPrint("DriverNotif:   Passengers: $passengerCount");
        debugPrint("DriverNotif:   started_at: ${trip['started_at']}");

        if (trip['started_at'] == null) {
          skippedCount++;
          debugPrint("DriverNotif:   ⚠️ SKIPPED - No started_at timestamp");
          continue;
        }

        final DateTime startedAt = DateTime.parse(trip['started_at']).toLocal();
        debugPrint("DriverNotif:   Parsed startedAt: $startedAt");

        // --- 1. Trip Start Notification ---
        final startRow = notifData
            .where(
              (n) =>
                  n['payload'] != null &&
                  n['payload']['trip_id'] == tripId &&
                  n['payload']['status'] == 'ongoing',
            )
            .firstOrNull;

        debugPrint(
          "DriverNotif:   Start notification in DB: ${startRow != null ? 'YES (${startRow['id']})' : 'NO (creating virtual)'}",
        );

        generatedList.add(
          NotifItem(
            id: startRow != null ? startRow['id'] : 'virtual_start_$tripId',
            virtualId: 'start_$tripId',
            tripId: tripId,
            variant: 'trips',
            title: "Trip Started: Jeepney $plate is now active.",
            timeOrDate: DateFormat('hh:mm a').format(startedAt),
            isRead: startRow != null ? (startRow['read'] ?? false) : false,
            sortDate: startedAt,
            isLocal: false,
            payload: {
              'status': 'ongoing',
              'trip_id': tripId,
              'date_str': DateFormat('MMM dd, yyyy').format(startedAt),
              'time_str': DateFormat('hh:mm a').format(startedAt),
            },
          ),
        );
        debugPrint("DriverNotif:   ✅ Added START notification");

        // --- 2. Trip End Notification ---
        if (status == 'completed' && trip['ended_at'] != null) {
          final DateTime endedAt = DateTime.parse(trip['ended_at']).toLocal();
          debugPrint("DriverNotif:   Parsed endedAt: $endedAt");

          final endRow = notifData
              .where(
                (n) =>
                    n['payload'] != null &&
                    n['payload']['trip_id'] == tripId &&
                    n['payload']['status'] == 'completed',
              )
              .firstOrNull;

          debugPrint(
            "DriverNotif:   End notification in DB: ${endRow != null ? 'YES (${endRow['id']})' : 'NO (creating virtual)'}",
          );

          generatedList.add(
            NotifItem(
              id: endRow != null ? endRow['id'] : 'virtual_end_$tripId',
              virtualId: 'end_$tripId',
              tripId: tripId,
              variant: 'trips',
              title: "Trip Ended: $passengerCount passengers served.",
              timeOrDate: DateFormat('hh:mm a').format(endedAt),
              isRead: endRow != null ? (endRow['read'] ?? false) : false,
              sortDate: endedAt,
              isLocal: false,
              payload: {'status': 'completed', 'trip_id': tripId},
            ),
          );
          debugPrint("DriverNotif:   ✅ Added END notification");
        } else {
          debugPrint(
            "DriverNotif:   ℹ️ Trip not completed or no ended_at - skipping END notification",
          );
        }
        processedCount++;
      }

      debugPrint("DriverNotif: ========== PROCESSING COMPLETE ==========");
      debugPrint("DriverNotif: Processed: $processedCount trips");
      debugPrint("DriverNotif: Skipped: $skippedCount trips");
      debugPrint(
        "DriverNotif: Total notifications generated: ${generatedList.length}",
      );

      _notifications = generatedList;
      debugPrint(
        "DriverNotif: ✅ Final _notifications list has ${_notifications.length} items",
      );
    } catch (e, stackTrace) {
      debugPrint('DriverNotif: ❌ FATAL ERROR during fetch: $e');
      debugPrint('DriverNotif: Stack trace: $stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notifId) async {
    final index = _notifications.indexWhere((n) => n.id == notifId);
    if (index == -1) return;

    final item = _notifications[index];
    if (item.isRead) return;

    _notifications[index].isRead = true;
    notifyListeners();

    if (item.isLocal) return;

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      if (notifId.startsWith('virtual_')) {
        final profileRes = await _supabase
            .from('profiles')
            .select('id')
            .eq('user_id', user.id)
            .single();
        final profileId = profileRes['id'];

        String type = 'trip';
        Map<String, dynamic> payload = item.payload ?? {};

        if (item.virtualId.startsWith('start_')) {
          payload = {'trip_id': item.tripId, 'status': 'ongoing'};
        } else if (item.virtualId.startsWith('end_')) {
          payload = {'trip_id': item.tripId, 'status': 'completed'};
        }

        await _supabase.from('notifications').insert({
          'recipient_profile_id': profileId,
          'type': type,
          'title': item.title,
          'message': item.title,
          'payload': payload,
          'read': true,
          'created_at': item.sortDate.toIso8601String(),
        });
      } else {
        await _supabase
            .from('notifications')
            .update({'read': true})
            .eq('id', notifId);
      }
    } catch (e) {
      debugPrint("DriverNotif: DB Sync Error: $e");
    }
  }

  Future<void> markAllAsRead(List<NotifItem> targets) async {
    for (var t in targets) {
      if (!t.isRead) await markAsRead(t.id);
    }
  }
}
