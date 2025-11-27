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
      // A. FETCH RAW DATA (FUTURES)
      // ---------------------------------------------------------

      // 1. Trips
      final tripsFuture = _supabase
          .from('trips')
          .select('id, started_at, ended_at, status, passengers_count')
          .or('driver_id.eq.$driverId,created_by_profile_id.eq.$profileId')
          .order('started_at', ascending: false)
          .limit(50);

      // 2. Wallet Transactions
      Future<List<dynamic>> walletTxFuture = Future.value([]);
      if (walletId != null) {
        walletTxFuture = _supabase
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
      }

      // 3. Trip Earnings
      Future<List<dynamic>> earningsFuture = Future.value([]);
      if (driverId.isNotEmpty) {
        earningsFuture = _supabase
            .from('transactions')
            .select('''
              id, created_at, type, amount, status, transaction_number, related_trip_id,
              trip:trips!inner(driver_id)
            ''')
            .eq('trip.driver_id', driverId)
            .eq('type', 'fare_payment')
            .order('created_at', ascending: false)
            .limit(50);
      }

      // 4. Verifications (NEW)
      final verificationsFuture = _supabase
          .from('verifications')
          .select('id, status, reviewer_notes, reviewed_at')
          .eq('profile_id', profileId)
          .neq('status', 'pending')
          .order('reviewed_at', ascending: false)
          .limit(10);

      // 5. Reports (NEW)
      // A. My Reports (Updates)
      final myReportsFuture = _supabase
          .from('reports')
          .select('id, category, status, updated_at, resolution_notes')
          .eq('reporter_profile_id', profileId)
          .neq('status', 'open')
          .order('updated_at', ascending: false)
          .limit(20);

      // B. Reports Against Me (Feedback)
      Future<List<dynamic>> reportsAgainstFuture = Future.value([]);
      if (driverId.isNotEmpty) {
        reportsAgainstFuture = _supabase
            .from('reports')
            .select('id, category, severity, created_at')
            .eq('reported_entity_type', 'driver')
            .eq('reported_entity_id', driverId)
            .order('created_at', ascending: false)
            .limit(20);
      }

      // 6. Notifications Table (Read Status)
      final notifTableFuture = _supabase
          .from('notifications')
          .select('id, read, payload, type')
          .eq('recipient_profile_id', profileId)
          .inFilter('type', ['trip', 'wallet', 'verification', 'report'])
          .limit(300);

      // --- AWAIT ALL ---
      final results = await Future.wait([
        tripsFuture, // 0
        walletTxFuture, // 1
        earningsFuture, // 2
        verificationsFuture, // 3
        myReportsFuture, // 4
        reportsAgainstFuture, // 5
        notifTableFuture, // 6
      ]);

      // Removed explicit casts 'as List<dynamic>' to fix linter warnings
      final tripsData = results[0];
      final walletTxData = results[1];
      final earningsData = results[2];
      final verificationsData = results[3];
      final myReportsData = results[4];
      final reportsAgainstData = results[5];
      final notifData = results[6];

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

        // --- Trip Start ---
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

        // --- Trip End ---
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
      // C. PROCESS TRANSACTIONS (Combined)
      // ---------------------------------------------------------
      final combinedTransactions = [...walletTxData, ...earningsData];

      for (var tx in combinedTransactions) {
        final String txId = tx['id'];
        final String type = tx['type'];
        final double amount = (tx['amount'] as num).toDouble().abs();
        final DateTime createdAt = DateTime.parse(tx['created_at']).toLocal();
        final String txNumber = tx['transaction_number'] ?? '---';
        final String status = tx['status'] ?? 'completed';

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
              'status': status,
            },
          ),
        );
      }

      // ---------------------------------------------------------
      // D. PROCESS VERIFICATIONS (NEW)
      // ---------------------------------------------------------
      for (var verif in verificationsData) {
        if (verif['reviewed_at'] == null) continue;
        final String vId = verif['id'];
        final DateTime reviewedAt = DateTime.parse(
          verif['reviewed_at'],
        ).toLocal();
        final String status = verif['status'];
        final String notes = verif['reviewer_notes'] ?? '';

        final verifRow = notifData
            .where(
              (n) =>
                  n['type'] == 'verification' &&
                  n['payload']?['verification_id'] == vId,
            )
            .firstOrNull;

        String title = "Verification Update";
        if (status == 'approved') {
          title = "You are now a Verified Driver";
        } else if (status == 'rejected') {
          title = "Verification Rejected: $notes";
        } else if (status == 'lacking') {
          title = "Additional Documents Required";
        }

        generatedList.add(
          NotifItem(
            id: verifRow != null ? verifRow['id'] : 'virtual_verif_$vId',
            virtualId: 'verif_$vId',
            tripId: '',
            variant: 'verification',
            title: title,
            timeOrDate: DateFormat('MMM dd').format(reviewedAt),
            isRead: verifRow != null ? (verifRow['read'] ?? false) : false,
            sortDate: reviewedAt,
            payload: {'verification_id': vId, 'status': status, 'notes': notes},
          ),
        );
      }

      // ---------------------------------------------------------
      // E. PROCESS REPORTS (NEW)
      // ---------------------------------------------------------
      // E1. My Reports Resolved
      for (var rep in myReportsData) {
        final String rId = rep['id'];
        final DateTime updatedAt = DateTime.parse(rep['updated_at']).toLocal();
        final String category = rep['category'];
        final String status = rep['status'];
        final String notes = rep['resolution_notes'] ?? '';

        final repRow = notifData
            .where(
              (n) =>
                  n['type'] == 'report' &&
                  n['payload']?['report_id'] == rId &&
                  n['payload']?['action'] == 'resolved',
            )
            .firstOrNull;

        generatedList.add(
          NotifItem(
            id: repRow != null ? repRow['id'] : 'virtual_myreport_$rId',
            virtualId: 'myreport_$rId',
            tripId: '',
            variant: 'report',
            title: "Report Resolved ($category): $notes",
            timeOrDate: DateFormat('MMM dd').format(updatedAt),
            isRead: repRow != null ? (repRow['read'] ?? false) : false,
            sortDate: updatedAt,
            payload: {'report_id': rId, 'action': 'resolved', 'status': status},
          ),
        );
      }

      // E2. Reports Against Me (Feedback)
      for (var rep in reportsAgainstData) {
        final String rId = rep['id'];
        final DateTime createdAt = DateTime.parse(rep['created_at']).toLocal();
        final String category = rep['category'];
        final String severity = rep['severity'];

        final repRow = notifData
            .where(
              (n) =>
                  n['type'] == 'report' &&
                  n['payload']?['report_id'] == rId &&
                  n['payload']?['action'] == 'feedback',
            )
            .firstOrNull;

        String title = "New Feedback Received ($category)";
        if (severity == 'high') {
          title = "High Severity Report Received ($category)";
        }

        generatedList.add(
          NotifItem(
            id: repRow != null ? repRow['id'] : 'virtual_feedback_$rId',
            virtualId: 'feedback_$rId',
            tripId: '',
            variant: 'report',
            title: title,
            timeOrDate: DateFormat('MMM dd').format(createdAt),
            isRead: repRow != null ? (repRow['read'] ?? false) : false,
            sortDate: createdAt,
            payload: {
              'report_id': rId,
              'action': 'feedback',
              'severity': severity,
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

        String type = 'trip';

        // Added curly braces to fix linter errors
        if (item.variant == 'wallet') {
          type = 'wallet';
        } else if (item.variant == 'verification') {
          type = 'verification';
        } else if (item.variant == 'report') {
          type = 'report';
        }

        Map<String, dynamic> payload = Map.from(item.payload ?? {});

        if (item.variant == 'trips') {
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
