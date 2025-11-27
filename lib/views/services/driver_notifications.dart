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

      // 2. Get Driver Info & Wallet Info
      String plate = 'Your Jeepney';
      String driverId = '';
      String? walletId;

      try {
        final driverRes = await _supabase
            .from('drivers')
            .select('id, vehicle_plate')
            .eq('profile_id', profileId)
            .maybeSingle();

        if (driverRes != null) {
          driverId = driverRes['id'];
          if (driverRes['vehicle_plate'] != null) {
            plate = driverRes['vehicle_plate'];
          }
        }

        final walletRes = await _supabase
            .from('wallets')
            .select('id')
            .eq('owner_profile_id', profileId)
            .maybeSingle();

        if (walletRes != null) {
          walletId = walletRes['id'];
        }
      } catch (_) {}

      // ---------------------------------------------------------
      // A. FETCH RAW DATA
      // ---------------------------------------------------------

      // 1. Trips (For "Trip Started" / "Trip Ended" notifications)
      final tripsRes = await _supabase
          .from('trips')
          .select('id, started_at, ended_at, status, passengers_count')
          .or('driver_id.eq.$driverId,created_by_profile_id.eq.$profileId')
          .order('started_at', ascending: false)
          .limit(50); // Limit trip notifications
      final List<dynamic> tripsData = tripsRes as List<dynamic>;

      // 2. Transactions (Wallet & Earnings)
      List<dynamic> combinedTransactions = [];

      if (walletId != null) {
        // 2a. Fetch General Wallet Transactions (Cash Out, Remittance, Payouts)
        // These are linked directly to the wallet_id
        final walletTxRes = await _supabase
            .from('transactions')
            .select(
              'id, created_at, type, amount, status, transaction_number, related_trip_id',
            )
            .eq('wallet_id', walletId)
            .inFilter('type', [
              'operator_payout',
              'driver_payout',
              'remittance',
              'cash_out',
            ])
            .order('created_at', ascending: false)
            .limit(50);

        combinedTransactions.addAll(walletTxRes as List<dynamic>);
      }

      if (driverId.isNotEmpty) {
        // 2b. Fetch Trip Earnings (Fare Payments)
        // These are linked to the TRIP, which is linked to the DRIVER
        final tripEarningsRes = await _supabase
            .from('transactions')
            .select('''
              id, created_at, type, amount, status, transaction_number, related_trip_id,
              trip:trips!inner(driver_id)
            ''')
            .eq('trip.driver_id', driverId)
            .eq('type', 'fare_payment')
            .order('created_at', ascending: false)
            .limit(50);

        combinedTransactions.addAll(tripEarningsRes as List<dynamic>);
      }

      // 3. Get "Read" Statuses from DB
      final notifRes = await _supabase
          .from('notifications')
          .select('id, read, payload, type')
          .eq('recipient_profile_id', profileId)
          .inFilter('type', ['trip', 'wallet'])
          .limit(200);

      final List<Map<String, dynamic>> notifData =
          List<Map<String, dynamic>>.from(notifRes as List);

      final List<NotifItem> generatedList = [];

      // ---------------------------------------------------------
      // B. PROCESS TRIPS (Start/End Events)
      // ---------------------------------------------------------
      for (var trip in tripsData) {
        final String tripId = trip['id'];
        final String currentStatus = trip['status'] ?? 'ongoing';
        final int passengerCount = trip['passengers_count'] ?? 0;

        if (trip['started_at'] == null) continue;
        final DateTime startedAt = DateTime.parse(trip['started_at']).toLocal();

        // --- Trip Start Notification ---
        final startRow = notifData
            .where(
              (n) =>
                  n['payload'] != null &&
                  n['payload']['trip_id'] == tripId &&
                  (n['payload']['status'] == 'ongoing' ||
                      n['payload']['event'] == 'start'),
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
            payload: {
              'status': currentStatus,
              'trip_id': tripId,
              'event': 'start',
              'date_str': DateFormat('MMM dd, yyyy').format(startedAt),
              'time_str': DateFormat('hh:mm a').format(startedAt),
            },
          ),
        );

        // --- Trip End Notification ---
        if (currentStatus == 'completed' && trip['ended_at'] != null) {
          final DateTime endedAt = DateTime.parse(trip['ended_at']).toLocal();
          final endRow = notifData
              .where(
                (n) =>
                    n['payload'] != null &&
                    n['payload']['trip_id'] == tripId &&
                    (n['payload']['status'] == 'completed' ||
                        n['payload']['event'] == 'end'),
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
              payload: {
                'status': 'completed',
                'trip_id': tripId,
                'event': 'end',
              },
            ),
          );
        }
      }

      // ---------------------------------------------------------
      // C. PROCESS TRANSACTIONS (Wallet + Earnings)
      // ---------------------------------------------------------
      for (var tx in combinedTransactions) {
        final String txId = tx['id'];
        final String type = tx['type'];
        final double amount = (tx['amount'] as num).toDouble().abs();
        final DateTime createdAt = DateTime.parse(tx['created_at']).toLocal();
        final String txNumber = tx['transaction_number'] ?? '---';
        final String status = tx['status'] ?? 'completed';

        // Check if DB has a record for this transaction notification
        final txRow = notifData
            .where(
              (n) =>
                  n['type'] == 'wallet' &&
                  n['payload'] != null &&
                  n['payload']['transaction_id'] == txId,
            )
            .firstOrNull;

        String title = "Transaction processed.";

        switch (type) {
          case 'fare_payment':
            // THIS IS THE TRIP EARNING
            title = "You earned ₱${amount.toStringAsFixed(2)} from your trip.";
            break;
          case 'remittance':
            title = "Remitted ₱${amount.toStringAsFixed(2)} to operator.";
            break;
          case 'cash_out':
            title = "Cash out of ₱${amount.toStringAsFixed(2)} processed.";
            break;
          case 'operator_payout':
            title =
                "Operator Payout of ₱${amount.toStringAsFixed(2)} received.";
            break;
          case 'driver_payout':
            title = "Payout of ₱${amount.toStringAsFixed(2)} received.";
            break;
          default:
            title =
                "${type.replaceAll('_', ' ').toUpperCase()} of ₱${amount.toStringAsFixed(2)}";
        }

        generatedList.add(
          NotifItem(
            id: txRow != null ? txRow['id'] : 'virtual_wallet_$txId',
            virtualId: 'wallet_$txId',
            tripId: tx['related_trip_id'] ?? '',
            variant:
                'wallet', // Keeping this as wallet so clicking it goes to wallet page
            title: title,
            timeOrDate: DateFormat('hh:mm a').format(createdAt),
            isRead: txRow != null ? (txRow['read'] ?? false) : false,
            sortDate: createdAt,
            payload: {
              'type': type,
              'transaction_id': txId,
              'amount': amount,
              'transaction_number': txNumber,
              'status': status,
            },
          ),
        );
      }

      _notifications = generatedList;
    } catch (e) {
      debugPrint('Error fetching driver notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Marks a notification as read (syncs with DB if it's virtual)
  Future<void> markAsRead(String notifId) async {
    final index = _notifications.indexWhere((n) => n.id == notifId);
    if (index == -1) return;

    final item = _notifications[index];
    if (item.isRead) return;

    // Optimistic UI update
    _notifications[index].isRead = true;
    notifyListeners();

    if (item.isLocal) return;

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      if (notifId.startsWith('virtual_')) {
        // Create new record in notifications table
        final profileRes = await _supabase
            .from('profiles')
            .select('id')
            .eq('user_id', user.id)
            .single();
        final profileId = profileRes['id'];

        String type = 'trip'; // Default
        Map<String, dynamic> payload = Map.from(item.payload ?? {});

        if (item.variant == 'wallet') {
          type = 'wallet';
        } else {
          // Trip logic
          if (item.virtualId.startsWith('start_')) {
            payload['status'] = 'ongoing';
            payload['event'] = 'start';
          } else if (item.virtualId.startsWith('end_')) {
            payload['status'] = 'completed';
            payload['event'] = 'end';
          }
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
        // Update existing record
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
