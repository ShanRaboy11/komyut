import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/notification.dart';

class NotificationProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<NotifItem> _notifications = [];

  List<NotifItem> get notifications {
    _notifications.sort((a, b) => b.sortDate.compareTo(a.sortDate));
    return _notifications;
  }

  // --- STATIC ITEMS (STRICTLY WALLET ONLY) ---
  final List<NotifItem> _staticItems = [
    NotifItem(
      id: 'w1',
      virtualId: 'w1',
      variant: 'wallet',
      title: '₱50.00 credited to your wallet.',
      timeOrDate: '10:45 AM',
      isRead: false,
      sortDate: DateTime.now().subtract(const Duration(hours: 2)),
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

      // 2. Get Commuter ID (For rewards)
      final commuterRes = await _supabase
          .from('commuters')
          .select('id')
          .eq('profile_id', profileId)
          .maybeSingle();
      final String? commuterId = commuterRes != null ? commuterRes['id'] : null;

      // 3. Fetch Trips
      final tripsRes = await _supabase
          .from('trips')
          .select('id, started_at, ended_at, status, driver_id')
          .eq('created_by_profile_id', profileId)
          .order('started_at', ascending: false);
      final List<dynamic> tripsData = tripsRes as List<dynamic>;

      // 4. Fetch Drivers
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

      // 5. Fetch Rewards (Points Transactions > 0)
      List<dynamic> rewardsData = [];
      if (commuterId != null) {
        final rewardsRes = await _supabase
            .from('points_transactions')
            .select('id, change, created_at, reason')
            .eq('commuter_id', commuterId)
            .gt('change', 0)
            .order('created_at', ascending: false);
        rewardsData = rewardsRes as List<dynamic>;
      }

      // 6. Fetch Read Statuses (For both Trip and Rewards)
      final notifRes = await _supabase
          .from('notifications')
          .select('id, read, payload, type')
          .eq('recipient_profile_id', profileId)
          .inFilter('type', ['trip', 'rewards']);

      final List<Map<String, dynamic>> notifData =
          List<Map<String, dynamic>>.from(notifRes as List);
      final List<NotifItem> generatedList = [];

      // --- PROCESS TRIPS ---
      for (var trip in tripsData) {
        final String tripId = trip['id'];
        final String status = trip['status'] ?? 'ongoing';
        final String driverId = trip['driver_id'] ?? '';
        final String plate = driverPlates[driverId] ?? 'Unknown';
        final DateTime startedAt = DateTime.parse(trip['started_at']).toLocal();

        // Start Notif
        final startRow = notifData
            .where(
              (n) =>
                  n['type'] == 'trip' &&
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
            payload: {
              'status': status,
              'date_str': DateFormat('MMM dd, yyyy').format(startedAt),
              'time_str': DateFormat('hh:mm a').format(startedAt),
            },
          ),
        );

        // End Notif
        if (status == 'completed' && trip['ended_at'] != null) {
          final DateTime endedAt = DateTime.parse(trip['ended_at']).toLocal();
          final endRow = notifData
              .where(
                (n) =>
                    n['type'] == 'trip' &&
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

      // --- PROCESS REWARDS ---
      for (var reward in rewardsData) {
        final String rewardId = reward['id'];
        final double amount = (reward['change'] as num).toDouble();
        final DateTime createdAt = DateTime.parse(
          reward['created_at'],
        ).toLocal();

        final rewardRow = notifData
            .where(
              (n) =>
                  n['type'] == 'rewards' &&
                  n['payload'] != null &&
                  n['payload']['reward_id'] == rewardId,
            )
            .firstOrNull;

        generatedList.add(
          NotifItem(
            id: rewardRow != null
                ? rewardRow['id']
                : 'virtual_reward_$rewardId',
            virtualId: 'reward_$rewardId',
            variant: 'rewards', // Will be mapped to 'Others' tab in UI
            title: "You earned $amount tokens for your trip!",
            timeOrDate: DateFormat('hh:mm a').format(createdAt),
            isRead: rewardRow != null ? (rewardRow['read'] ?? false) : false,
            sortDate: createdAt,
            payload: {'reward_id': rewardId, 'amount': amount},
          ),
        );
      }

      _notifications = [...generatedList, ..._staticItems];
    } catch (e) {
      debugPrint('Error fetching data: $e');
      _notifications = [..._staticItems];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notifId) async {
    final index = _notifications.indexWhere((n) => n.id == notifId);
    if (index == -1) return;

    final item = _notifications[index];
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
        Map<String, dynamic> payload = {};

        if (item.virtualId.startsWith('reward_')) {
          type = 'rewards';
          payload = item.payload ?? {};
        } else {
          String status = item.virtualId.startsWith('end_')
              ? 'completed'
              : 'ongoing';
          payload = {'trip_id': item.tripId, 'status': status};
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
