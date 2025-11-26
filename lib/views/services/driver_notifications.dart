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
    if (user == null) return;

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

      // 2. Get Driver ID and Vehicle Plate
      final driverRes = await _supabase
          .from('drivers')
          .select('id, vehicle_plate')
          .eq('profile_id', profileId)
          .maybeSingle();

      if (driverRes == null) {
        _notifications = [];
        return;
      }

      final String driverId = driverRes['id'];
      final String plate = driverRes['vehicle_plate'] ?? 'Your Jeepney';

      // ---------------------------------------------------------
      // A. FETCH RAW DATA
      // ---------------------------------------------------------

      // 1. Trips
      // FIX: We use .or() to check if the trip is linked via driver_id OR created_by_profile_id.
      // This ensures new trips (created by profile) show up immediately, even if driver_id isn't set yet.
      final tripsRes = await _supabase
          .from('trips')
          .select('id, started_at, ended_at, status, passengers_count')
          .or('driver_id.eq.$driverId,created_by_profile_id.eq.$profileId')
          .order('started_at', ascending: false)
          .limit(200);

      final List<dynamic> tripsData = tripsRes as List<dynamic>;

      // 2. Read Statuses
      final notifRes = await _supabase
          .from('notifications')
          .select('id, read, payload, type')
          .eq('recipient_profile_id', profileId)
          .eq('type', 'trip')
          .limit(500);

      final List<Map<String, dynamic>> notifData =
          List<Map<String, dynamic>>.from(notifRes as List);

      final List<NotifItem> generatedList = [];

      // ---------------------------------------------------------
      // B. PROCESS TRIPS
      // ---------------------------------------------------------
      for (var trip in tripsData) {
        final String tripId = trip['id'];
        // Get REAL status from DB row
        final String status = trip['status'] ?? 'ongoing';
        final int passengerCount = trip['passengers_count'] ?? 0;

        if (trip['started_at'] == null) continue;

        final DateTime startedAt = DateTime.parse(trip['started_at']).toLocal();

        // --- 1. Trip Start Notification ---
        final startRow = notifData
            .where(
              (n) =>
                  n['payload'] != null &&
                  n['payload']['trip_id'] == tripId &&
                  n['payload']['status'] == 'ongoing',
            )
            .firstOrNull;

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
              'status':
                  status, // Uses the real status from DB (ongoing/completed)
              'trip_id': tripId,
              'date_str': DateFormat('MMM dd, yyyy').format(startedAt),
              'time_str': DateFormat('hh:mm a').format(startedAt),
            },
          ),
        );

        // --- 2. Trip End Notification ---
        if (status == 'completed' && trip['ended_at'] != null) {
          final DateTime endedAt = DateTime.parse(trip['ended_at']).toLocal();

          final endRow = notifData
              .where(
                (n) =>
                    n['payload'] != null &&
                    n['payload']['trip_id'] == tripId &&
                    n['payload']['status'] == 'completed',
              )
              .firstOrNull;

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
        }
      }

      _notifications = generatedList;
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
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

        // EXACT STATUS LOGIC PRESERVED
        if (item.virtualId.startsWith('start_')) {
          payload = {
            'trip_id': item.tripId,
            'status': item.payload?['status'] ?? 'ongoing',
          };
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
      debugPrint("DB Sync Error: $e");
    }
  }

  Future<void> markAllAsRead(List<NotifItem> targets) async {
    for (var t in targets) {
      if (!t.isRead) await markAsRead(t.id);
    }
  }
}
