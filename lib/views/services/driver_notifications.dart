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

      // 2. Get Driver Info (Optional)
      String plate = 'Your Jeepney';
      String driverId = '';
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
      } catch (_) {}

      // ---------------------------------------------------------
      // A. FETCH RAW DATA
      // ---------------------------------------------------------

      // 1. Trips (Created by Profile OR Driver ID)
      final tripsRes = await _supabase
          .from('trips')
          .select('id, started_at, ended_at, status, passengers_count')
          .or('driver_id.eq.$driverId,created_by_profile_id.eq.$profileId')
          .order('started_at', ascending: false)
          .limit(200);
      final List<dynamic> tripsData = tripsRes as List<dynamic>;

      // 2. Transactions (Wallet: Fare Payments, Remittances, Cash Outs)
      // Note: Fare payments are 'incoming' (to driver's wallet), others are outgoing/incoming depending on logic
      // Usually driver wallet owns the transaction.

      // First, get Wallet ID for this profile
      final walletRes = await _supabase
          .from('wallets')
          .select('id')
          .eq('owner_profile_id', profileId)
          .maybeSingle();

      List<dynamic> transactionsData = [];
      if (walletRes != null) {
        final walletId = walletRes['id'];
        final txRes = await _supabase
            .from('transactions')
            .select(
              'id, created_at, type, amount, status, transaction_number, related_trip_id',
            )
            .eq('wallet_id', walletId)
            .inFilter('type', ['fare_payment', 'remittance', 'cash_out'])
            .order('created_at', ascending: false)
            .limit(300);
        transactionsData = txRes as List<dynamic>;
      }

      // 3. Read Statuses (Existing notifications in DB)
      final notifRes = await _supabase
          .from('notifications')
          .select('id, read, payload, type')
          .eq('recipient_profile_id', profileId)
          .inFilter('type', [
            'trip',
            'wallet',
          ]) // Fetch both trip and wallet types
          .limit(500);

      final List<Map<String, dynamic>> notifData =
          List<Map<String, dynamic>>.from(notifRes as List);

      final List<NotifItem> generatedList = [];

      // ---------------------------------------------------------
      // B. PROCESS TRIPS
      // ---------------------------------------------------------
      for (var trip in tripsData) {
        final String tripId = trip['id'];
        final String currentStatus = trip['status'] ?? 'ongoing';
        final int passengerCount = trip['passengers_count'] ?? 0;

        if (trip['started_at'] == null) continue;
        final DateTime startedAt = DateTime.parse(trip['started_at']).toLocal();

        // --- 1. Trip Start ---
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

        // --- 2. Trip End ---
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
      // C. PROCESS WALLET TRANSACTIONS
      // ---------------------------------------------------------
      for (var tx in transactionsData) {
        final String txId = tx['id'];
        final String type = tx['type'];
        final double amount = (tx['amount'] as num).toDouble().abs();
        final DateTime createdAt = DateTime.parse(tx['created_at']).toLocal();
        final String txNumber = tx['transaction_number'] ?? '---';

        // Find existing notification record
        final txRow = notifData
            .where(
              (n) =>
                  n['type'] == 'wallet' &&
                  n['payload'] != null &&
                  n['payload']['transaction_id'] == txId,
            )
            .firstOrNull;

        String title = "Transaction processed.";

        if (type == 'fare_payment') {
          // Group fare payments? Or show individually? Usually drivers get individual pings.
          // "Received ₱20.00 fare payment."
          title = "Received ₱${amount.toStringAsFixed(2)} fare payment.";
        } else if (type == 'remittance') {
          title = "Remitted ₱${amount.toStringAsFixed(2)} to operator.";
        } else if (type == 'cash_out') {
          title = "Cash out of ₱${amount.toStringAsFixed(2)} processed.";
        }

        generatedList.add(
          NotifItem(
            id: txRow != null ? txRow['id'] : 'virtual_wallet_$txId',
            virtualId: 'wallet_$txId',
            tripId: tx['related_trip_id'] ?? '', // Optional link
            variant: 'wallet',
            title: title,
            timeOrDate: DateFormat('hh:mm a').format(createdAt),
            isRead: txRow != null ? (txRow['read'] ?? false) : false,
            sortDate: createdAt,
            payload: {
              'type': type,
              'transaction_id': txId,
              'amount': amount,
              'transaction_number': txNumber,
              // Pass status if relevant (e.g. pending vs completed)
              'status': tx['status'] ?? 'completed',
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

        String type = 'trip'; // Default
        Map<String, dynamic> payload = Map.from(item.payload ?? {});

        // Check variant to determine DB 'type'
        if (item.variant == 'wallet') {
          type = 'wallet';
          // Clean up virtual ID for storage if needed, but payload usually has the real ID
        } else {
          // Trip Logic
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
