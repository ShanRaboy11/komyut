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
    // Sort by Date Descending
    _notifications.sort((a, b) => b.sortDate.compareTo(a.sortDate));
    return _notifications;
  }

  // --- STATIC ITEMS (Fallback) ---
  final List<NotifItem> _staticItems = [];

  Future<void> fetchNotifications() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    if (_notifications.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      // 1. IDs
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

      // ---------------------------------------------------------
      // A. FETCH RAW DATA
      // ---------------------------------------------------------

      // 1. Trips
      final tripsRes = await _supabase
          .from('trips')
          .select('id, started_at, ended_at, status, driver_id')
          .eq('created_by_profile_id', profileId)
          .order('started_at', ascending: false)
          .limit(500);
      final List<dynamic> tripsData = tripsRes as List<dynamic>;

      // 2. Fare Transactions
      final transactionsRes = await _supabase
          .from('transactions')
          .select('id, created_at, amount, related_trip_id')
          .eq('initiated_by_profile_id', profileId)
          .eq('type', 'fare_payment')
          .order('created_at', ascending: false)
          .limit(1000);
      final List<dynamic> fareData = transactionsRes as List<dynamic>;

      // 3. Rewards & Redemptions
      List<dynamic> rewardsData = [];
      List<dynamic> redemptionData = [];

      if (commuterId != null) {
        // Fetch Rewards (Incoming)
        final rewardsRes = await _supabase
            .from('points_transactions')
            .select('id, change, created_at, reason')
            .eq('commuter_id', commuterId)
            .gt('change', 0)
            .order('created_at', ascending: false)
            .limit(500);
        rewardsData = rewardsRes as List<dynamic>;

        // Fetch Redemptions (Outgoing)
        try {
          final redemptionRes = await _supabase
              .from('points_transactions')
              .select('''
                id,
                change,
                created_at,
                related_transaction_id,
                transactions!related_transaction_id (
                  transaction_number
                )
              ''')
              .eq('commuter_id', commuterId)
              .lt('change', 0)
              .order('created_at', ascending: false)
              .limit(500);
          redemptionData = redemptionRes as List<dynamic>;
        } catch (e) {
          debugPrint("Error fetching redemptions: $e");
        }
      }

      // 4. Cash In (Incoming Wallet)
      List<dynamic> cashInData = [];
      try {
        // Added updated_at to the select query to track status changes
        final cashInRes = await _supabase
            .from('transactions')
            .select(
              'id, created_at, updated_at, amount, payment_methods(name), transaction_number, status',
            )
            .eq('initiated_by_profile_id', profileId)
            .eq('type', 'cash_in')
            .order('created_at', ascending: false)
            .limit(500);
        cashInData = cashInRes as List<dynamic>;
      } catch (e) {
        debugPrint("Error fetching cash_in: $e");
      }

      // 5. Drivers
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

      // 6. Read Statuses
      final notifRes = await _supabase
          .from('notifications')
          .select('id, read, payload, type')
          .eq('recipient_profile_id', profileId)
          .inFilter('type', ['trip', 'wallet', 'rewards'])
          .limit(1000);
      final List<Map<String, dynamic>> notifData =
          List<Map<String, dynamic>>.from(notifRes as List);

      final List<NotifItem> generatedList = [];

      // ---------------------------------------------------------
      // B. PROCESS TRIPS
      // ---------------------------------------------------------
      for (var trip in tripsData) {
        final String tripId = trip['id'];
        final String status = trip['status'] ?? 'ongoing';
        final String driverId = trip['driver_id'] ?? '';
        final String plate = driverPlates[driverId] ?? 'Unknown';
        final DateTime startedAt = DateTime.parse(trip['started_at']).toLocal();

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
              payload: {'status': 'completed'},
            ),
          );
        }
      }

      // ---------------------------------------------------------
      // C. PROCESS FARE PAYMENTS
      // ---------------------------------------------------------
      Map<String, List<dynamic>> paymentsByTrip = {};
      for (var t in fareData) {
        final String? relatedTripId = t['related_trip_id'];
        if (relatedTripId != null) {
          paymentsByTrip.putIfAbsent(relatedTripId, () => []).add(t);
        }
      }

      paymentsByTrip.forEach((tripId, transactions) {
        double totalAmount = 0.0;
        for (var t in transactions) {
          totalAmount += (t['amount'] as num).toDouble().abs();
        }

        final latestTransaction = transactions.first;
        final DateTime latestDate = DateTime.parse(
          latestTransaction['created_at'],
        ).toLocal();
        final String latestTransId = latestTransaction['id'];

        final walletRow = notifData
            .where(
              (n) =>
                  n['type'] == 'wallet' &&
                  n['payload'] != null &&
                  n['payload']['trip_id'] == tripId,
            )
            .firstOrNull;

        generatedList.add(
          NotifItem(
            id: walletRow != null
                ? walletRow['id']
                : 'virtual_wallet_trip_$tripId',
            virtualId: 'wallet_trip_$tripId',
            variant: 'wallet',
            title:
                "Fare payment of ₱${totalAmount.toStringAsFixed(2)} successful.",
            timeOrDate: DateFormat('MMM dd').format(latestDate),
            isRead: walletRow != null ? (walletRow['read'] ?? false) : false,
            sortDate: latestDate,
            payload: {
              'type': 'fare_payment',
              'trip_id': tripId,
              'latest_transaction_id': latestTransId,
            },
          ),
        );
      });

      // ---------------------------------------------------------
      // D. PROCESS REWARDS
      // ---------------------------------------------------------
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
            variant: 'rewards',
            title: "You earned $amount tokens for your trip!",
            timeOrDate: DateFormat('hh:mm a').format(createdAt),
            isRead: rewardRow != null ? (rewardRow['read'] ?? false) : false,
            sortDate: createdAt,
            payload: {'reward_id': rewardId, 'amount': amount},
          ),
        );
      }

      // ---------------------------------------------------------
      // E. PROCESS REDEMPTIONS (Real DB)
      // ---------------------------------------------------------
      for (var red in redemptionData) {
        final String redId = red['id'];
        final double amount = (red['change'] as num).toDouble().abs();
        final DateTime createdAt = DateTime.parse(red['created_at']).toLocal();

        // Get transaction_number from the joined transactions table
        String txCode = redId; // fallback to points_transaction id

        if (red['transactions'] != null) {
          final transactionData = red['transactions'];
          if (transactionData is Map<String, dynamic> &&
              transactionData['transaction_number'] != null) {
            txCode = transactionData['transaction_number'];
          }
        }

        final redRow = notifData
            .where(
              (n) =>
                  n['type'] == 'wallet' &&
                  n['payload'] != null &&
                  n['payload']['transaction_id'] == redId,
            )
            .firstOrNull;

        generatedList.add(
          NotifItem(
            id: redRow != null ? redRow['id'] : 'virtual_red_$redId',
            virtualId: 'red_$redId',
            variant: 'wallet',
            title: "You redeemed $amount tokens.",
            timeOrDate: DateFormat('MMM dd').format(createdAt),
            isRead: redRow != null ? (redRow['read'] ?? false) : false,
            sortDate: createdAt,
            payload: {
              'type': 'redemption',
              'transaction_id': redId,
              'amount': amount,
              'transaction_number': txCode,
            },
          ),
        );
      }

      // ---------------------------------------------------------
      // F. PROCESS CASH IN (Real DB)
      // ---------------------------------------------------------
      for (var ci in cashInData) {
        final String id = ci['id'];
        final double amount = (ci['amount'] as num).toDouble().abs();
        final DateTime createdAt = DateTime.parse(ci['created_at']).toLocal();
        final String status = ci['status'] ?? 'pending';

        DateTime? updatedAt;
        if (ci['updated_at'] != null) {
          updatedAt = DateTime.parse(ci['updated_at']).toLocal();
        }

        final String txCode = ci['transaction_number'] ?? id;

        String method = "Counter";
        if (ci['payment_methods'] != null &&
            ci['payment_methods']['name'] != null) {
          method = ci['payment_methods']['name'];
        }

        // --- Notification 1: Pending/Initiated ---
        final ciPendingRow = notifData
            .where(
              (n) =>
                  n['type'] == 'wallet' &&
                  n['payload'] != null &&
                  n['payload']['transaction_id'] == id &&
                  n['payload']['status'] == 'pending',
            )
            .firstOrNull;

        generatedList.add(
          NotifItem(
            id: ciPendingRow != null
                ? ciPendingRow['id']
                : 'virtual_ci_pending_$id',
            virtualId: 'ci_pending_$id',
            variant: 'wallet',
            title:
                "Cash in of ₱${amount.toStringAsFixed(2)} initiated via $method.",
            timeOrDate: DateFormat('MMM dd').format(createdAt),
            isRead: ciPendingRow != null
                ? (ciPendingRow['read'] ?? false)
                : false,
            sortDate: createdAt,
            payload: {
              'type': 'cash_in',
              'transaction_id': id,
              'amount': amount,
              'method': method,
              'transaction_number': txCode,
              'status': 'pending',
            },
          ),
        );

        // --- Notification 2: Completed/Success (NEW) ---
        if (status == 'completed' || status == 'success' || status == 'paid') {
          final ciCompleteRow = notifData
              .where(
                (n) =>
                    n['type'] == 'wallet' &&
                    n['payload'] != null &&
                    n['payload']['transaction_id'] == id &&
                    (n['payload']['status'] == 'completed' ||
                        n['payload']['status'] == null),
                // Note: 'status' == null check handles legacy notifications created before this change
              )
              .firstOrNull;

          generatedList.add(
            NotifItem(
              id: ciCompleteRow != null
                  ? ciCompleteRow['id']
                  : 'virtual_ci_complete_$id',
              virtualId: 'ci_complete_$id',
              variant: 'wallet',
              title: "₱${amount.toStringAsFixed(2)} credited via $method.",
              timeOrDate: DateFormat('MMM dd').format(updatedAt ?? createdAt),
              isRead: ciCompleteRow != null
                  ? (ciCompleteRow['read'] ?? false)
                  : false,
              sortDate: updatedAt ?? createdAt,
              payload: {
                'type': 'cash_in',
                'transaction_id': id,
                'amount': amount,
                'method': method,
                'transaction_number': txCode,
                'status': 'completed',
              },
            ),
          );
        }
      }

      _notifications = [...generatedList, ..._staticItems];
    } catch (e) {
      debugPrint('Error fetching data: $e');
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

        if (item.virtualId.startsWith('reward_')) {
          type = 'rewards';
        } else if (item.virtualId.startsWith('wallet_trip_')) {
          type = 'wallet';
        } else if (item.virtualId.startsWith('ci_') ||
            item.virtualId.startsWith('red_')) {
          type = 'wallet';

          String cleanId = item.virtualId;

          if (cleanId.startsWith('ci_pending_')) {
            cleanId = cleanId.replaceAll('ci_pending_', '');
            payload['status'] = 'pending';
          } else if (cleanId.startsWith('ci_complete_')) {
            cleanId = cleanId.replaceAll('ci_complete_', '');
            payload['status'] = 'completed';
          } else if (cleanId.startsWith('ci_')) {
            // Fallback for any legacy IDs
            cleanId = cleanId.replaceAll('ci_', '');
            payload['status'] = 'completed';
          } else if (cleanId.startsWith('red_')) {
            cleanId = cleanId.replaceAll('red_', '');
          }

          if (!payload.containsKey('transaction_id')) {
            payload['transaction_id'] = cleanId;
          }
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

class NotificationDriverProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<NotifItem> _notifications = [];

  List<NotifItem> get notifications {
    // Sort by Date Descending
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

      // 2. Get Driver ID
      final driverRes = await _supabase
          .from('drivers')
          .select('id, vehicle_plate')
          .eq('profile_id', profileId)
          .maybeSingle();
      
      // If user is not a driver, stop here
      if (driverRes == null) {
        _notifications = [];
        return;
      }
      
      final String driverId = driverRes['id'];
      final String plate = driverRes['vehicle_plate'] ?? 'Vehicle';

      // ---------------------------------------------------------
      // A. FETCH RAW DATA
      // ---------------------------------------------------------

      // 1. Trips (Where driver_id matches the current user)
      final tripsRes = await _supabase
          .from('trips')
          .select('id, started_at, ended_at, status, passengers_count')
          .eq('driver_id', driverId)
          .order('started_at', ascending: false)
          .limit(200);
      final List<dynamic> tripsData = tripsRes as List<dynamic>;

      // 2. Read Statuses (from notifications table)
      final notifRes = await _supabase
          .from('notifications')
          .select('id, read, payload, type')
          .eq('recipient_profile_id', profileId)
          .eq('type', 'trip') // Only trips for now
          .limit(500);
      final List<Map<String, dynamic>> notifData =
          List<Map<String, dynamic>>.from(notifRes as List);

      final List<NotifItem> generatedList = [];

      // ---------------------------------------------------------
      // B. PROCESS TRIPS
      // ---------------------------------------------------------
      for (var trip in tripsData) {
        final String tripId = trip['id'];
        final String status = trip['status'] ?? 'ongoing';
        final int passengerCount = trip['passengers_count'] ?? 0;
        final DateTime startedAt = DateTime.parse(trip['started_at']).toLocal();

        // --- Trip Start Notification ---
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
            title: "Trip Started: $plate is now active on route.",
            timeOrDate: DateFormat('hh:mm a').format(startedAt),
            isRead: startRow != null ? (startRow['read'] ?? false) : false,
            sortDate: startedAt,
            payload: {
              'status': 'ongoing',
              'date_str': DateFormat('MMM dd, yyyy').format(startedAt),
              'time_str': DateFormat('hh:mm a').format(startedAt),
            },
          ),
        );

        // --- Trip End Notification ---
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
              title: "Trip Ended. Total passengers served: $passengerCount",
              timeOrDate: DateFormat('hh:mm a').format(endedAt),
              isRead: endRow != null ? (endRow['read'] ?? false) : false,
              sortDate: endedAt,
              payload: {'status': 'completed'},
            ),
          );
        }
      }

      _notifications = generatedList;
    } catch (e) {
      debugPrint('Error fetching driver notifications: $e');
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

        // Populate status based on virtual ID for consistency with DB
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
      debugPrint("DB Sync Error: $e");
    }
  }

  Future<void> markAllAsRead(List<NotifItem> targets) async {
    for (var t in targets) {
      if (!t.isRead) await markAsRead(t.id);
    }
  }
}