import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/notification.dart';

class NotificationProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<NotifItem> _notifications = [];

  // Sort: Newest First
  List<NotifItem> get notifications {
    _notifications.sort((a, b) => b.sortDate.compareTo(a.sortDate));
    return _notifications;
  }

  // --- STATIC ITEMS ---
  final List<NotifItem> _staticItems = [
    NotifItem(
      id: 'w1',
      virtualId: 'w1',
      variant: 'wallet',
      title: '₱50 credited to your wallet.',
      timeOrDate: '10:45 AM',
      isRead: false,
      sortDate: DateTime.now(),
      isLocal: true,
    ),
    NotifItem(
      id: 'w2',
      virtualId: 'w2',
      variant: 'wallet',
      title: 'Payment successful for trip ABC-123.',
      timeOrDate: 'Oct 12, 2025',
      isRead: true,
      sortDate: DateTime.now().subtract(const Duration(days: 5)),
      isLocal: true,
    ),
    NotifItem(
      id: 'o1',
      virtualId: 'o1',
      variant: 'rewards',
      title: 'You earned 10 reward points!',
      timeOrDate: 'Oct 06, 2025',
      isRead: true,
      sortDate: DateTime.now().subtract(const Duration(days: 10)),
      isLocal: true,
    ),
    NotifItem(
      id: 'o2',
      virtualId: 'o2',
      variant: 'alert',
      title: 'Service update scheduled tomorrow.',
      timeOrDate: 'Oct 08, 2025',
      isRead: false,
      sortDate: DateTime.now().subtract(const Duration(days: 8)),
      isLocal: true,
    ),
    NotifItem(
      id: 'o3',
      virtualId: 'o3',
      variant: 'general',
      title: 'New terms & conditions posted.',
      timeOrDate: 'Oct 05, 2025',
      isRead: true,
      sortDate: DateTime.now().subtract(const Duration(days: 15)),
      isLocal: true,
    ),
  ];

  Future<void> fetchNotifications() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Get Profile ID
      final profileRes = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .single();
      final profileId = profileRes['id'];

      // 2. Fetch Trips
      final tripsRes = await _supabase
          .from('trips')
          .select('id, started_at, ended_at, status, driver_id')
          .eq('created_by_profile_id', profileId)
          .order('started_at', ascending: false);

      final List<dynamic> tripsData = tripsRes as List<dynamic>;

      // 3. Fetch Drivers
      final driverIds = tripsData
          .map((t) => t['driver_id'])
          .where((id) => id != null)
          .toSet()
          .toList();
      Map<String, String> driverPlates = {};

      if (driverIds.isNotEmpty) {
        final driversRes = await _supabase
            .from('drivers')
            .select('id, vehicle_plate')
            .inFilter('id', driverIds);
        for (var d in (driversRes as List)) {
          driverPlates[d['id']] = d['vehicle_plate'] ?? 'Unknown';
        }
      }

      // 4. Fetch Read Statuses
      final notifRes = await _supabase
          .from('notifications')
          .select('id, read, payload')
          .eq('recipient_profile_id', profileId)
          .eq('type', 'trip');

      final List<Map<String, dynamic>> notifData =
          List<Map<String, dynamic>>.from(notifRes as List);

      final List<NotifItem> generatedList = [];

      for (var trip in tripsData) {
        final String tripId = trip['id'];
        final String currentRealStatus =
            trip['status'] ?? 'ongoing'; // Real-time status
        final String driverId = trip['driver_id'] ?? '';
        final String plate = driverPlates[driverId] ?? 'Unknown Plate';

        final DateTime startedAt = DateTime.parse(trip['started_at']).toLocal();

        // --- NOTIFICATION 1: STARTED ---
        // We look for a DB row specifically for 'ongoing' to track read status
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
            title: "Jeepney $plate has started its trip.",
            timeOrDate: DateFormat('hh:mm a').format(startedAt),
            isRead: startRow != null ? (startRow['read'] ?? false) : false,
            sortDate: startedAt,
            // PAYLOAD: We pass 'currentRealStatus' so navigation shows the ACTUAL status (e.g. Completed)
            // even though this is the "Started" notification.
            payload: {
              'status': currentRealStatus,
              'date_str': DateFormat('MMM dd, yyyy').format(startedAt),
              'time_str': DateFormat('hh:mm a').format(startedAt),
            },
          ),
        );

        // --- NOTIFICATION 2: ENDED ---
        if (currentRealStatus == 'completed' && trip['ended_at'] != null) {
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
              title: "Jeepney $plate has ended its trip. Thank you!",
              timeOrDate: DateFormat('hh:mm a').format(endedAt),
              isRead: endRow != null ? (endRow['read'] ?? false) : false,
              sortDate: endedAt,
              payload: {
                'status': 'completed',
                'date_str': DateFormat('MMM dd, yyyy').format(endedAt),
                'time_str': DateFormat('hh:mm a').format(endedAt),
              },
            ),
          );
        }
      }

      _notifications = [...generatedList, ..._staticItems];
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      _notifications = [..._staticItems];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark Read
  Future<void> markAsRead(String notifId) async {
    final index = _notifications.indexWhere((n) => n.id == notifId);
    if (index == -1) return;

    final item = _notifications[index];

    // Optimistic Update
    _notifications[index].isRead = true;
    notifyListeners();

    if (item.isLocal) return;

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // IF VIRTUAL: Create row in DB
      if (notifId.startsWith('virtual_')) {
        final profileRes = await _supabase
            .from('profiles')
            .select('id')
            .eq('user_id', user.id)
            .single();
        final profileId = profileRes['id'];

        // IMPORTANT: Determine the EVENT type for the DB ('ongoing' or 'completed')
        // We cannot rely on payload['status'] because that might be 'completed' even for the Start notification.
        String dbStatus = 'ongoing';
        if (item.virtualId.startsWith('end_')) {
          dbStatus = 'completed';
        }

        final tripId = item.tripId;
        final timestamp = item.sortDate.toIso8601String();

        await _supabase.from('notifications').insert({
          'recipient_profile_id': profileId,
          'type': 'trip',
          'title': 'Trip Notification',
          'message': item.title,
          // We store the STRICT status ('ongoing' or 'completed') in DB to ensure fetching logic works next time
          'payload': {'trip_id': tripId, 'status': dbStatus},
          'read': true,
          'created_at': timestamp,
        });
      }
      // IF REAL: Update existing
      else {
        await _supabase
            .from('notifications')
            .update({'read': true})
            .eq('id', notifId);
      }
    } catch (e) {
      debugPrint("Error syncing read status: $e");
    }
  }

  // Mark All Read
  Future<void> markAllAsRead(List<NotifItem> targets) async {
    for (var t in targets) {
      if (!t.isRead) {
        await markAsRead(t.id);
      }
    }
  }
}
