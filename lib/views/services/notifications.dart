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

  // --- STATIC ITEMS (Cash-In & Redemption ONLY) ---
  final List<NotifItem> _staticItems = [
    NotifItem(
      id: 'w1',
      virtualId: 'w1',
      variant: 'wallet',
      title: '₱500.00 credited to your wallet.',
      timeOrDate: '10:45 AM',
      isRead: false,
      sortDate: DateTime.now().subtract(const Duration(hours: 2)),
      isLocal: true,
      payload: {
        'type': 'cash_in',
        'data': {
          'title': 'Cash In',
          'amount': 500.00,
          'date': DateTime.now().subtract(const Duration(hours: 2)).toString(),
          'reference': 'STATIC-OTC-001',
          'method': 'Over-the-Counter',
          'status': 'Completed',
        },
      },
    ),
    NotifItem(
      id: 'w3',
      virtualId: 'w3',
      variant: 'wallet',
      title: 'Redeemed 10.00 tokens.',
      timeOrDate: 'Yesterday',
      isRead: true,
      sortDate: DateTime.now().subtract(const Duration(days: 1)),
      isLocal: true,
      payload: {
        'type': 'redemption',
        'data': {
          'title': 'Token Redemption',
          'amount': 10.00,
          'date': DateTime.now().subtract(const Duration(days: 1)).toString(),
          'reference': 'STATIC-RED-999',
          'method': 'Wallet Balance',
          'status': 'Completed',
        },
      },
    ),
  ];

  Future<void> fetchNotifications() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    if (_notifications.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      // 1. Setup IDs
      final profileRes = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .single();
      final profileId = profileRes['id'];

      final commuterRes = await _supabase
          .from('commuters')
          .select('id')
          .eq('profile_id', profileId)
          .maybeSingle();
      final String? commuterId = commuterRes != null ? commuterRes['id'] : null;

      // 2. Fetch Read Statuses
      final notifRes = await _supabase
          .from('notifications')
          .select('id, read, payload, type')
          .eq('recipient_profile_id', profileId)
          .inFilter('type', ['trip', 'wallet', 'rewards']);
      final List<Map<String, dynamic>> notifData =
          List<Map<String, dynamic>>.from(notifRes as List);

      final List<NotifItem> generatedList = [];

      // ---------------------------------------------------------
      // A. REAL TRIPS (Start/End)
      // ---------------------------------------------------------
      final tripsRes = await _supabase
          .from('trips')
          .select('id, started_at, ended_at, status, driver_id')
          .eq('created_by_profile_id', profileId)
          .order('started_at', ascending: false);
      final List<dynamic> tripsData = tripsRes as List<dynamic>;

      // Fetch Drivers for Plates
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

      // ---------------------------------------------------------
      // B. REAL FARE PAYMENTS (Wallet)
      // ---------------------------------------------------------
      final transactionsRes = await _supabase
          .from('transactions')
          .select('id, created_at, amount, related_trip_id')
          .eq('initiated_by_profile_id', profileId)
          .eq('type', 'fare_payment')
          .order('created_at', ascending: false);

      for (var trans in (transactionsRes as List)) {
        final String transId = trans['id'];
        final String? relatedTripId = trans['related_trip_id'];
        final double amount = (trans['amount'] as num).toDouble().abs();
        final DateTime createdAt = DateTime.parse(
          trans['created_at'],
        ).toLocal();

        // Check read status
        final walletRow = notifData
            .where(
              (n) =>
                  n['type'] == 'wallet' &&
                  n['payload'] != null &&
                  n['payload']['transaction_id'] == transId,
            )
            .firstOrNull;

        generatedList.add(
          NotifItem(
            id: walletRow != null ? walletRow['id'] : 'virtual_wallet_$transId',
            virtualId: 'wallet_$transId',
            variant: 'wallet',
            title: "Fare payment of ₱${amount.toStringAsFixed(2)} successful.",
            timeOrDate: DateFormat('MMM dd').format(createdAt),
            isRead: walletRow != null ? (walletRow['read'] ?? false) : false,
            sortDate: createdAt,
            payload: {
              'type': 'fare_payment',
              'trip_id': relatedTripId, // IMPORTANT: Used to fetch Trip Receipt
              'transaction_id': transId,
            },
          ),
        );
      }

      // ---------------------------------------------------------
      // C. REAL REWARDS (Others)
      // ---------------------------------------------------------
      if (commuterId != null) {
        final rewardsRes = await _supabase
            .from('points_transactions')
            .select('id, change, created_at, reason')
            .eq('commuter_id', commuterId)
            .gt('change', 0)
            .order('created_at', ascending: false);

        for (var reward in (rewardsRes as List)) {
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
              variant: 'rewards',
              title: "You earned $amount tokens for your trip!",
              timeOrDate: DateFormat('hh:mm a').format(createdAt),
              isRead: rewardRow != null ? (rewardRow['read'] ?? false) : false,
              sortDate: createdAt,
              payload: {'reward_id': rewardId, 'amount': amount},
            ),
          );
        }
      }

      _notifications = [...generatedList, ..._staticItems];
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      if (_notifications.isEmpty) _notifications = [..._staticItems];
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
        Map<String, dynamic> payload = item.payload ?? {};

        if (item.virtualId.startsWith('reward_'))
          type = 'rewards';
        else if (item.virtualId.startsWith('wallet_'))
          type = 'wallet';
        else {
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
