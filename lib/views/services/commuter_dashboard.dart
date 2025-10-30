// lib/services/commuter_dashboard_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommuterDashboardService {
  final _supabase = Supabase.instance.client;

  /// Get commuter's profile information
  Future<Map<String, dynamic>> getCommuterProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user');
      }

      // Get profile with commuter info
      final profileData = await _supabase
          .from('profiles')
          .select('id, first_name, last_name, role, is_verified')
          .eq('user_id', userId)
          .single();

      debugPrint('✅ Profile fetched: ${profileData['first_name']}');
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

      // Get profile_id first
      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .single();

      // Get wallet balance
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

      // Get profile_id first
      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .single();

      // Get commuter details
      final commuterData = await _supabase
          .from('commuters')
          .select('id, category, wheel_tokens, id_verified')
          .eq('profile_id', profile['id'])
          .maybeSingle();

      if (commuterData == null) {
        return {'category': 'regular', 'wheel_tokens': 0, 'id_verified': false};
      }

      debugPrint('✅ Commuter details fetched: ${commuterData['category']}');
      return commuterData;
    } catch (e) {
      debugPrint('❌ Error fetching commuter details: $e');
      return {'category': 'regular', 'wheel_tokens': 0, 'id_verified': false};
    }
  }

  /// Get total points/wheel tokens
  Future<int> getWheelTokens() async {
    try {
      final commuterDetails = await getCommuterDetails();
      final tokens = (commuterDetails['wheel_tokens'] as int?) ?? 0;
      debugPrint('✅ Wheel tokens fetched: $tokens');
      return tokens;
    } catch (e) {
      debugPrint('❌ Error fetching wheel tokens: $e');
      return 0;
    }
  }

  /// Get recent trips (last 10 trips)
  Future<List<Map<String, dynamic>>> getRecentTrips() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // Get profile_id
      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .single();

      // Get recent trips where this profile created them
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

      // Get profile_id
      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .single();

      // Get ongoing trip
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

      // Get profile_id
      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .single();

      // Count unread notifications
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

      // Get profile_id
      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .single();

      // Get wallet_id
      final wallet = await _supabase
          .from('wallets')
          .select('id')
          .eq('owner_profile_id', profile['id'])
          .maybeSingle();

      if (wallet == null) return [];

      // Get recent transactions
      final transactions = await _supabase
          .from('transactions')
          .select('''
            id,
            transaction_number,
            type,
            amount,
            status,
            created_at,
            processed_at
          ''')
          .eq('wallet_id', wallet['id'])
          .order('created_at', ascending: false)
          .limit(10);

      debugPrint('✅ Recent transactions fetched: ${transactions.length}');
      return transactions;
    } catch (e) {
      debugPrint('❌ Error fetching recent transactions: $e');
      return [];
    }
  }

  /// Get total trips count
  Future<int> getTotalTripsCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      // Get profile_id
      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .single();

      // Count all trips
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

      // Get profile_id
      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .single();

      // Get all completed trips and sum fare amounts
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

      final profile = await getCommuterProfile();
      final commuterDetails = await getCommuterDetails();
      final balance = await getWalletBalance();
      final wheelTokens = await getWheelTokens();
      final recentTrips = await getRecentTrips();
      final activeTrip = await getActiveTrip();
      final unreadNotifications = await getUnreadNotificationsCount();
      final totalTripsCount = await getTotalTripsCount();
      final totalSpent = await getTotalSpent();

      debugPrint('✅ All commuter dashboard data fetched successfully');

      return {
        'profile': profile,
        'commuterDetails': commuterDetails,
        'balance': balance,
        'wheelTokens': wheelTokens,
        'recentTrips': recentTrips,
        'activeTrip': activeTrip,
        'unreadNotifications': unreadNotifications,
        'totalTripsCount': totalTripsCount,
        'totalSpent': totalSpent,
      };
    } catch (e) {
      debugPrint('❌ Error fetching dashboard data: $e');
      rethrow;
    }
  }

  Future<Map<String, double>> getFareExpensesWeekly() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};

      final response = await _supabase.rpc('get_weekly_fare_expenses');

      if (response is List) {
        return {
          for (var item in response)
            item['day_name']: (item['total'] as num).toDouble(),
        };
      }
      return {};
    } catch (e) {
      debugPrint('❌ Error fetching weekly fare expenses: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getTokenHistory() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .single();

      final tokenHistory = await _supabase
          .from('token_transactions')
          .select('id, type, amount, created_at')
          .eq('profile_id', profile['id'])
          .order('created_at', ascending: false)
          .limit(10);

      return List<Map<String, dynamic>>.from(tokenHistory);
    } catch (e) {
      debugPrint('❌ Error fetching token history: $e');
      return [];
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
          .select(
            'id, transaction_number, type, amount, status, created_at, processed_at',
          )
          .eq('wallet_id', wallet['id'])
          .order('created_at', ascending: false);

      debugPrint('✅ All transactions fetched: ${transactions.length}');
      return transactions;
    } catch (e) {
      debugPrint('❌ Error fetching all transactions: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllTokenHistory() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .single();

      final tokenHistory = await _supabase
          .from('token_transactions')
          .select('id, type, amount, created_at')
          .eq('profile_id', profile['id'])
          .order('created_at', ascending: false);

      debugPrint('✅ All token history fetched: ${tokenHistory.length}');
      return tokenHistory;
    } catch (e) {
      debugPrint('❌ Error fetching all token history: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> initiateCashInTransaction({
    required double amount,
    required String type, // e.g., 'over_the_counter' or 'digital_wallet'
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
            'metadata': {'channel': type},
          })
          .select()
          .single();

      debugPrint('✅ Cash-in transaction initiated: ${newTransaction['id']}');
      return newTransaction;
    } catch (e) {
      debugPrint('❌ Error initiating cash-in transaction: $e');
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
}
