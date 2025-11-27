import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommuterDashboardService {
  final _supabase = Supabase.instance.client;

  /// Get commuter's profile information
  Future<Map<String, dynamic>> getCommuterProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      final profileData = await _supabase
          .from('profiles')
          .select('id, user_id, first_name, last_name, role, is_verified')
          .eq('user_id', user.id)
          .single();

      profileData['email'] = user.email;

      debugPrint('✅ Profile fetched for: ${profileData['first_name']}');
      return profileData;
    } catch (e) {
      debugPrint('❌ Error fetching profile: $e');
      rethrow;
    }
  }

  /// Get commuter's wallet balance
  Future<double> getWalletBalance() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0.0;

      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .single();

      final walletData = await _supabase
          .from('wallets')
          .select('balance')
          .eq('owner_profile_id', profile['id'])
          .maybeSingle();

      if (walletData == null) return 0.0;

      final balance = (walletData['balance'] as num?)?.toDouble() ?? 0.0;
      debugPrint('✅ Wallet balance fetched: $balance');
      return balance;
    } catch (e) {
      debugPrint('❌ Error fetching wallet balance: $e');
      return 0.0;
    }
  }

  /// Get commuter's category and details
  Future<Map<String, dynamic>> getCommuterDetails() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user');
      }

      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .single();

      final commuterData = await _supabase
          .from('commuters')
          .select('id, category, wheel_tokens, id_verified')
          .eq('profile_id', profile['id'])
          .maybeSingle();

      if (commuterData == null) {
        return {
          'category': 'regular',
          'wheel_tokens': 0.0,
          'id_verified': false,
        };
      }

      debugPrint('✅ Commuter details fetched: ${commuterData['category']}');
      return commuterData;
    } catch (e) {
      debugPrint('❌ Error fetching commuter details: $e');
      return {'category': 'regular', 'wheel_tokens': 0.0, 'id_verified': false};
    }
  }

  /// Get total points/wheel tokens
  Future<double> getWheelTokens() async {
    try {
      final commuterDetails = await getCommuterDetails();
      final tokens =
          (commuterDetails['wheel_tokens'] as num?)?.toDouble() ?? 0.0;
      debugPrint('✅ Wheel tokens fetched: $tokens');
      return tokens;
    } catch (e) {
      debugPrint('❌ Error fetching wheel tokens: $e');
      return 0.0;
    }
  }

  /// Get recent trips (last 10 trips)
  Future<List<Map<String, dynamic>>> getRecentTrips() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .single();

      final trips = await _supabase
          .from('trips')
          .select('''
            id,
            fare_amount,
            distance_meters,
            status,
            started_at,
            ended_at,
            routes:route_id (
              code,
              name
            ),
            origin_stops:origin_stop_id (
              name
            ),
            destination_stops:destination_stop_id (
              name
            )
          ''')
          .eq('created_by_profile_id', profile['id'])
          .order('started_at', ascending: false)
          .limit(10);

      debugPrint('✅ Recent trips fetched: ${trips.length} trips');
      return trips;
    } catch (e) {
      debugPrint('❌ Error fetching recent trips: $e');
      return [];
    }
  }

  /// Get active/ongoing trip
  Future<Map<String, dynamic>?> getActiveTrip() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .single();

      final trip = await _supabase
          .from('trips')
          .select('''
            id,
            fare_amount,
            distance_meters,
            status,
            started_at,
            routes:route_id (
              code,
              name
            ),
            origin_stops:origin_stop_id (
              name
            ),
            destination_stops:destination_stop_id (
              name
            ),
            drivers:driver_id (
              vehicle_plate,
              profiles:profile_id (
                first_name,
                last_name
              )
            )
          ''')
          .eq('created_by_profile_id', profile['id'])
          .eq('status', 'ongoing')
          .maybeSingle();

      if (trip != null) {
        debugPrint('✅ Active trip found');
      } else {
        debugPrint('ℹ️ No active trip');
      }
      return trip;
    } catch (e) {
      debugPrint('❌ Error fetching active trip: $e');
      return null;
    }
  }

  /// Get unread notifications count
  Future<int> getUnreadNotificationsCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .single();

      final notifications = await _supabase
          .from('notifications')
          .select('id')
          .eq('recipient_profile_id', profile['id'])
          .eq('read', false);

      debugPrint('✅ Unread notifications count: ${notifications.length}');
      return notifications.length;
    } catch (e) {
      debugPrint('❌ Error fetching notifications count: $e');
      return 0;
    }
  }

  /// Get recent transactions (last 10)
  Future<List<Map<String, dynamic>>> getRecentTransactions() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .single();
      final wallet = await _supabase
          .from('wallets')
          .select('id')
          .eq('owner_profile_id', profile['id'])
          .maybeSingle();

      if (wallet == null) return [];

      final transactions = await _supabase
          .from('transactions')
          .select(
            'id, transaction_number, type, amount, status, created_at, processed_at, payment_methods(name)',
          )
          .eq('wallet_id', wallet['id'])
          .order('created_at', ascending: false)
          .limit(5);

      debugPrint('✅ Recent transactions fetched: ${transactions.length}');
      return transactions;
    } catch (e) {
      debugPrint('❌ Error fetching recent transactions: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRecentTokens() async {
    return getAllTokens(limit: 5);
  }

  /// Get total trips count
  Future<int> getTotalTripsCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .single();

      final trips = await _supabase
          .from('trips')
          .select('id')
          .eq('created_by_profile_id', profile['id']);

      debugPrint('✅ Total trips count: ${trips.length}');
      return trips.length;
    } catch (e) {
      debugPrint('❌ Error fetching trips count: $e');
      return 0;
    }
  }

  /// Get total amount spent on trips
  Future<double> getTotalSpent() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0.0;

      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .single();

      final trips = await _supabase
          .from('trips')
          .select('fare_amount')
          .eq('created_by_profile_id', profile['id'])
          .eq('status', 'completed');

      double totalSpent = 0.0;
      for (var trip in trips) {
        totalSpent += (trip['fare_amount'] as num?)?.toDouble() ?? 0.0;
      }

      debugPrint('✅ Total spent fetched: $totalSpent');
      return totalSpent;
    } catch (e) {
      debugPrint('❌ Error fetching total spent: $e');
      return 0.0;
    }
  }

  /// Get all dashboard data at once
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      debugPrint('🔄 Fetching all commuter dashboard data...');

      final results = await Future.wait([
        getWalletBalance(),
        getWheelTokens(),
        getRecentTrips(),
        getActiveTrip(),
        getUnreadNotificationsCount(),
        getTotalTripsCount(),
        getTotalSpent(),
        getCommuterProfile(),
        getCommuterDetails(),
      ]);

      debugPrint('✅ All commuter dashboard data fetched successfully');

      return {
        'balance': results[0] as double,
        'wheelTokens': results[1] as double,
        'recentTrips': results[2] as List<Map<String, dynamic>>,
        'activeTrip': results[3] as Map<String, dynamic>?,
        'unreadNotifications': results[4] as int,
        'totalTripsCount': results[5] as int,
        'totalSpent': results[6] as double,
        'profile': results[7] as Map<String, dynamic>,
        'commuterDetails': results[8] as Map<String, dynamic>,
      };
    } catch (e) {
      debugPrint('❌ Error fetching dashboard data: $e');
      rethrow;
    }
  }

  Future<Map<String, double>> getFareExpensesWeekly({
    int weekOffset = 0,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_weekly_fare_expenses',
        params: {'week_offset': weekOffset},
      );

      if (response is List) {
        final orderedDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final expenseMap = {
          for (var item in response)
            (item['day_name'] as String): (item['total'] as num).toDouble(),
        };

        final weeklyExpenses = {
          for (var day in orderedDays) day: expenseMap[day] ?? 0.0,
        };

        debugPrint(
          '✅ Weekly fare expenses for offset $weekOffset fetched: $weeklyExpenses',
        );
        return weeklyExpenses;
      }
      return {};
    } catch (e) {
      debugPrint(
        '❌ Error fetching weekly fare expenses for offset $weekOffset: $e',
      );
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .single();
      final wallet = await _supabase
          .from('wallets')
          .select('id')
          .eq('owner_profile_id', profile['id'])
          .maybeSingle();
      if (wallet == null) return [];

      final transactions = await _supabase
          .from('transactions')
          .select('''
              id, transaction_number, type, amount, status, created_at, processed_at,
              payment_methods ( name )
            ''')
          .eq('wallet_id', wallet['id'])
          .order('created_at', ascending: false);

      debugPrint('✅ All transactions fetched: ${transactions.length}');
      return transactions;
    } catch (e) {
      debugPrint('❌ Error fetching all transactions: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllTokens({int? limit}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .single();
      final commuter = await _supabase
          .from('commuters')
          .select('id')
          .eq('profile_id', profile['id'])
          .single();
      final commuterId = commuter['id'];

      var query = _supabase
          .from('points_transactions')
          .select('''
              change,
              reason,
              created_at,
              transactions (
                  transaction_number
              )
          ''')
          .eq('commuter_id', commuterId)
          .order('created_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;

      final mappedHistory = response.map((item) {
        final transactionData = item['transactions'] as Map<String, dynamic>?;

        String type =
            item['reason'] as String? ??
            ((item['change'] as num) < 0 ? 'redemption' : 'reward');

        return {
          'amount': item['change'],
          'type': type,
          'created_at': item['created_at'],
          'transaction_number': transactionData?['transaction_number'],
        };
      }).toList();

      debugPrint(
        '✅ Fetched ${mappedHistory.length} token records from points_transactions.',
      );
      return mappedHistory;
    } catch (e) {
      debugPrint('❌ Error fetching token history from points_transactions: $e');
      rethrow;
    }
  }

  Future<void> confirmCashInTransaction({
    required String transactionId,
    required String transactionCode,
  }) async {
    try {
      await _supabase
          .from('transactions')
          .update({'transaction_number': transactionCode})
          .eq('id', transactionId);

      debugPrint(
        '✅ Transaction $transactionId confirmed with code $transactionCode',
      );
    } catch (e) {
      debugPrint('❌ Error confirming cash-in transaction: $e');
      rethrow;
    }
  }

  Future<void> completeCashInTransaction({
    required String transactionId,
  }) async {
    try {
      await _supabase.rpc(
        'complete_otc_cash_in',
        params: {'transaction_id_arg': transactionId},
      );
      debugPrint('✅ Transaction $transactionId completed via RPC.');
    } catch (e) {
      debugPrint('❌ Error completing cash-in transaction via RPC: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createCashInTransaction({
    required double amount,
    required String paymentMethodName,
    required String transactionNumber,
    required String payerName,
    required String payerEmail,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated.');

      final profileData = await _supabase
          .from('profiles')
          .select('id, wallets!inner(id)')
          .eq('user_id', userId)
          .single();

      final profileId = profileData['id'];
      final walletId = profileData['wallets'][0]['id'];

      if (walletId == null) throw Exception('User wallet not found.');

      final newTransaction = await _supabase
          .from('transactions')
          .insert({
            'wallet_id': walletId,
            'initiated_by_profile_id': profileId,
            'amount': amount,
            'type': 'cash_in',
            'status': 'pending',
            'transaction_number': transactionNumber,
            'payment_method_id': (await _supabase
                .from('payment_methods')
                .select('id')
                .eq('name', paymentMethodName)
                .single())['id'],
            'metadata': {'payer_name': payerName, 'payer_email': payerEmail},
          })
          .select('*, payment_methods(name)')
          .single();

      debugPrint(
        '✅ Cash-in transaction CREATED with metadata: ${newTransaction['id']}',
      );
      return newTransaction;
    } catch (e) {
      debugPrint('❌ Error creating cash-in transaction: $e');
      rethrow;
    }
  }

  Future<List<String>> getPaymentSourcesByType(String type) async {
    try {
      final response = await _supabase
          .from('payment_methods')
          .select('name')
          .eq('type', type)
          .eq('is_active', true);

      final sources = response.map((item) => item['name'] as String).toList();
      debugPrint('✅ Fetched ${sources.length} sources for type "$type"');
      return sources;
    } catch (e) {
      debugPrint('❌ Error fetching payment sources: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCommuterName() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user');
      }
      final nameData = await _supabase
          .from('profiles')
          .select('first_name, last_name')
          .eq('user_id', userId)
          .single();

      debugPrint('✅ Commuter name fetched: ${nameData['first_name']}');
      return nameData;
    } catch (e) {
      debugPrint('❌ Error fetching commuter name: $e');
      rethrow;
    }
  }

  Future<void> redeemTokens({
    required double amount,
    required String transactionNumber,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated.');

      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .single();
      final profileId = profile['id'];

      await _supabase.rpc(
        'redeem_wheel_tokens',
        params: {
          'p_amount_to_redeem': amount,
          'p_profile_id': profileId,
          'p_transaction_number': transactionNumber,
        },
      );
      debugPrint('✅ Successfully redeemed $amount tokens via RPC.');
    } catch (e) {
      debugPrint('❌ Error redeeming tokens: $e');
      rethrow;
    }
  }
}
