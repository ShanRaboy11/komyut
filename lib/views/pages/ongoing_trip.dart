import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// 'dart:convert' removed: notifications are now created in the DB trigger
import './qr_scan.dart';

class OngoingTripScreen extends StatefulWidget {
  final String tripId;
  final String driverName;
  final String routeCode;
  final String originStopName;
  final LatLng? currentLocation;
  final List<Map<String, dynamic>> routeStops;
  final String? originStopId;
  final double initialPayment;
  final String? destinationStopName;

  const OngoingTripScreen({
    super.key,
    required this.tripId,
    required this.driverName,
    required this.routeCode,
    required this.originStopName,
    this.currentLocation,
    required this.routeStops,
    this.originStopId,
    this.initialPayment = 10.0,
    this.destinationStopName,
  });

  @override
  State<OngoingTripScreen> createState() => _OngoingTripScreenState();
}

class _OngoingTripScreenState extends State<OngoingTripScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  int _passengerCount = 1;
  bool _isLoadingLocation = false;
  bool _hasConfirmed = false;
  double _swipeProgress = 0.0;
  Map<String, dynamic>? _tripDetails;
  double _walletBalance = 0.0;
  double? _driverRating;
  bool _isLoadingRating = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadTripDetails();
    _loadWalletBalance();
    _loadDriverRating();
  }

  Future<void> _loadTripDetails() async {
    try {
      final supabase = Supabase.instance.client;
      
      final tripResponse = await supabase
          .from('trips')
          .select('''
            *,
            drivers:driver_id (
              id,
              vehicle_plate,
              operator_name,
              puv_type,
              profiles:profile_id (
                first_name,
                last_name
              )
            ),
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
          .eq('id', widget.tripId)
          .single();

      setState(() {
        _tripDetails = tripResponse;
      });

      // After loading trip details, attempt to recover any failed payout
      _attemptPayoutRetryIfNeeded();

      debugPrint('✅ Trip details loaded: $_tripDetails');
    } catch (e) {
      debugPrint('❌ Error loading trip details: $e');
    }
  }

  Future<void> _loadWalletBalance() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) return;

      final profileResponse = await supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .single();

      final walletResponse = await supabase
          .from('wallets')
          .select('balance')
          .eq('owner_profile_id', profileResponse['id'])
          .single();

      setState(() {
        _walletBalance = (walletResponse['balance'] as num).toDouble();
      });
    } catch (e) {
      debugPrint('❌ Error loading wallet balance: $e');
    }
  }

  Future<void> _loadDriverRating() async {
    setState(() => _isLoadingRating = true);
    
    try {
      final supabase = Supabase.instance.client;
      
      // Get driver_id from the trip
      final tripResponse = await supabase
          .from('trips')
          .select('driver_id')
          .eq('id', widget.tripId)
          .single();
      
      final driverId = tripResponse['driver_id'] as String?;

      if (driverId != null) {
        // Calculate average rating for this driver
        final ratingsResponse = await supabase
            .from('ratings')
            .select('overall')
            .eq('driver_id', driverId);

        if (ratingsResponse.isNotEmpty) {
          double totalRating = 0;
          int count = 0;

          for (var rating in ratingsResponse) {
            final overall = rating['overall'] as int?;
            if (overall != null) {
              totalRating += overall;
              count++;
            }
          }

          if (count > 0) {
            setState(() {
              _driverRating = totalRating / count;
              _isLoadingRating = false;
            });
            debugPrint('✅ Driver rating loaded: $_driverRating');
          } else {
            setState(() {
              _driverRating = null;
              _isLoadingRating = false;
            });
          }
        } else {
          setState(() {
            _driverRating = null;
            _isLoadingRating = false;
          });
        }
      } else {
        setState(() {
          _driverRating = null;
          _isLoadingRating = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading driver rating: $e');
      setState(() {
        _driverRating = null;
        _isLoadingRating = false;
      });
    }
  }

  String _getDriverName() {
    if (_tripDetails != null) {
      final driver = _tripDetails!['drivers'];
      if (driver != null && driver['profiles'] != null) {
        final profile = driver['profiles'];
        return '${profile['first_name']} ${profile['last_name']}';
      }
    }
    return widget.driverName;
  }

  Future<void> _getCurrentLocation() async {
    if (widget.currentLocation != null) {
      setState(() {
        _currentPosition = Position(
          latitude: widget.currentLocation!.latitude,
          longitude: widget.currentLocation!.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      });
      return;
    }

    setState(() => _isLoadingLocation = true);

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      _mapController.move(
        LatLng(position.latitude, position.longitude),
        15.0,
      );
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      debugPrint('Error getting location: $e');
    }
  }

  /// If the trip metadata indicates a payout previously failed, attempt RPC retry.
  Future<void> _attemptPayoutRetryIfNeeded() async {
    try {
      if (_tripDetails == null) return;
      final metadata = _tripDetails!['metadata'] as Map<String, dynamic>?;
      if (metadata == null) return;

      final bool payoutFailed = metadata['payout_failed'] == true;
      if (!payoutFailed) return;

      debugPrint('ℹ️ Detected payout_failed for trip ${_tripDetails!['id']}. Attempting retry...');

      final supabase = Supabase.instance.client;

      // Ensure current user is the commuter who created the trip
      final createdBy = _tripDetails!['created_by_profile_id'] as String?;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('⚠️ No authenticated user for payout retry');
        return;
      }

      final profileRes = await supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      if (profileRes == null) return;
      final myProfileId = profileRes['id'] as String;

      if (createdBy != myProfileId) {
        debugPrint('⚠️ Current user is not the trip owner; skipping payout retry');
        return;
      }

      // Determine driver profile id and amount from metadata/trip
      String? driverProfileId;
      try {
        final drivers = _tripDetails!['drivers'];
        if (drivers != null) driverProfileId = drivers['profile_id'] as String?;
      } catch (_) {}

      final num? payoutAmountNum = metadata['payout_amount'] as num?;
      final double payoutAmount = payoutAmountNum != null
          ? payoutAmountNum.toDouble()
          : (_tripDetails!['fare_amount'] as num?)?.toDouble() ?? 0.0;

      if (driverProfileId == null || payoutAmount <= 0) {
        debugPrint('⚠️ Missing driver profile or payout amount; cannot retry payout');
        return;
      }

      final rpcParams = {
        'p_trip_id': _tripDetails!['id'] as String,
        'p_driver_profile_id': driverProfileId,
        'p_amount': payoutAmount,
        'p_commuter_profile_id': myProfileId,
      };

      try {
        await supabase.rpc('transfer_trip_fare', params: rpcParams);

        debugPrint('✅ Payout retry succeeded for trip ${_tripDetails!['id']}');

        // Clear metadata flags
        await supabase
            .from('trips')
            .update({
              'metadata': {
                ..._tripDetails!['metadata'],
                'payout_failed': false,
                'payout_error': null,
              }
            })
            .eq('id', _tripDetails!['id']);

        // Reload trip details to reflect changes
        await _loadTripDetails();
      } catch (e) {
        debugPrint('❌ Payout retry failed: $e');
      }
    } catch (e) {
      debugPrint('❌ Error in payout retry check: $e');
    }
  }

  List<Marker> _buildMarkers() {
    List<Marker> markers = [];

    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          width: 50,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withAlpha(128),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.person_pin,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      );
    }

    for (int i = 0; i < widget.routeStops.length; i++) {
      final stop = widget.routeStops[i];
      final stopId = stop['id'];
      final isOrigin = stopId == widget.originStopId;

      markers.add(
        Marker(
          point: LatLng(stop['latitude'], stop['longitude']),
          width: isOrigin ? 60 : 40,
          height: isOrigin ? 80 : 60,
          child: Column(
            children: [
              if (isOrigin)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    stop['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 2),
              Icon(
                isOrigin ? Icons.location_on : Icons.location_on_outlined,
                color: isOrigin ? Colors.green : const Color(0xFF8E4CB6),
                size: isOrigin ? 40 : 30,
              ),
            ],
          ),
        ),
      );
    }

    return markers;
  }

  List<Polyline> _buildPolylines() {
    if (widget.routeStops.length < 2) return [];

    final allStopPoints = widget.routeStops
        .map((stop) => LatLng(stop['latitude'], stop['longitude']))
        .toList();

    return [
      Polyline(
        points: allStopPoints,
        color: Colors.grey.shade400,
        strokeWidth: 3.0,
        isDotted: true,
      ),
    ];
  }

  Future<void> _updatePassengerCount() async {
    try {
      final supabase = Supabase.instance.client;
      
      // Calculate total initial payment based on passenger count
      final totalInitialPayment = widget.initialPayment * _passengerCount;
      
      await supabase.from('trips').update({
        'passengers_count': _passengerCount,
        'fare_amount': totalInitialPayment,
      }).eq('id', widget.tripId);

      debugPrint('✅ Updated passenger count to: $_passengerCount');
      debugPrint('✅ Updated initial fare to: ₱$totalInitialPayment');
    } catch (e) {
      debugPrint('❌ Error updating passenger count: $e');
    }
  }

  void _showConfirmationModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                          color: Colors.black.withAlpha((0.1 * 255).round()),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Animation Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF8E4CB6),
                        Color(0xFFB945AA),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8E4CB6).withAlpha((0.3 * 255).round()),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Title
                const Text(
                  'Trip Confirmed!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Passenger count badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF8E4CB6).withAlpha((0.1 * 255).round()),
                        const Color(0xFFB945AA).withAlpha((0.1 * 255).round()),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF8E4CB6).withAlpha((0.3 * 255).round()),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.people_rounded,
                        color: Color(0xFF8E4CB6),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_passengerCount ${_passengerCount == 1 ? 'Passenger' : 'Passengers'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8E4CB6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Description
                Text(
                  'Your trip has been confirmed. Please scan the QR code again when you reach your destination to complete the trip.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Continue Button
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xFF8E4CB6),
                          Color(0xFFB945AA),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8E4CB6).withAlpha((0.4 * 255).round()),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        // Show loading overlay
                        final nav = Navigator.of(context);
                        showDialog(
                          context: nav.context,
                          barrierDismissible: false,
                          builder: (_) => Container(
                            color: Colors.black.withAlpha((0.5 * 255).round()),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      width: 50,
                                      height: 50,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 4,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFF8E4CB6),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'Processing payment...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );

                        final ok = await _processInitialPayment();

                        // Dismiss loading using captured navigator
                        if (mounted) nav.pop();

                        if (ok) {
                          if (!mounted) return;
                          nav.pop();
                          setState(() {
                            _hasConfirmed = true;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSwipeButton() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B53C2), Color(0xFFB945AA)],
        ),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B53C2).withAlpha(102),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              'Swipe to Proceed',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white.withAlpha(204),
              ),
            ),
          ),
          Positioned(
            left: 4,
            top: 4,
            bottom: 4,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _swipeProgress += details.delta.dx;
                  if (_swipeProgress < 0) _swipeProgress = 0;
                  if (_swipeProgress > MediaQuery.of(context).size.width - 110) {
                    _swipeProgress = MediaQuery.of(context).size.width - 110;
                  }
                });
              },
              onHorizontalDragEnd: (details) {
                if (_swipeProgress > MediaQuery.of(context).size.width - 150) {
                  _updatePassengerCount();
                  _showConfirmationModal();
                  setState(() {
                    _swipeProgress = 0;
                  });
                } else {
                  setState(() {
                    _swipeProgress = 0;
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(left: _swipeProgress),
                width: 62,
                height: 62,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF8E4CB6),
                  size: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Process the initial payment when commuter confirms passenger count.
  /// Deducts from commuter wallet and creates a pending transaction linked to the trip.
  Future<bool> _processInitialPayment() async {
    try {
      final supabase = Supabase.instance.client;

      // Find current user profile
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        _showSimpleError('Please log in to continue');
        return false;
      }

      final profileRes = await supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (profileRes == null) {
        _showSimpleError('User profile not found');
        return false;
      }

      final profileId = profileRes['id'] as String;

      // Get wallet
      final walletRes = await supabase
          .from('wallets')
          .select('id, balance, owner_profile_id')
          .eq('owner_profile_id', profileId)
          .maybeSingle();

      String walletId;
      double balance;

      if (walletRes == null) {
        debugPrint('ℹ️ Wallet not found for profile $profileId; creating one');
        // Create wallet with zero balance; user must top-up to proceed
        try {
          final created = await supabase.from('wallets').insert({
            'owner_profile_id': profileId,
            'balance': 0,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          }).select().maybeSingle();

          if (created == null) {
            _showSimpleError('Failed to create wallet. Please contact support.');
            return false;
          }

          walletId = created['id'] as String;
          balance = (created['balance'] as num).toDouble();
        } catch (e) {
          debugPrint('❌ Error creating wallet for profile $profileId: $e');
          _showSimpleError('Failed to access wallet. Please contact support.');
          return false;
        }
      } else {
        walletId = walletRes['id'] as String;
        balance = (walletRes['balance'] as num).toDouble();
      }

      debugPrint('👜 Commuter wallet: id=$walletId balance=₱${balance.toStringAsFixed(2)}');

      // Calculate total initial payment based on passenger count
      final totalInitialPayment = widget.initialPayment * _passengerCount;

      if (balance < totalInitialPayment) {
        _showSimpleError('Insufficient balance. Please top up your wallet.');
        return false;
      }

      // Deduct from commuter wallet. Use owner_profile_id filter to align with RLS.
      // Perform update first, then insert pending transaction. If transaction insert fails,
      // attempt to revert the wallet update so user funds are not lost.
      final updatedWallet = await supabase
          .from('wallets')
          .update({'balance': balance - totalInitialPayment, 'updated_at': DateTime.now().toIso8601String()})
          .eq('owner_profile_id', profileId)
          .select()
          .maybeSingle();

      if (updatedWallet == null) {
        debugPrint('❌ Failed to update commuter wallet for profile $profileId');
        _showSimpleError('Failed to deduct payment from wallet.');
        return false;
      }

      final newBalance = (updatedWallet['balance'] as num).toDouble();
      debugPrint('✅ Deducted ₱${totalInitialPayment.toStringAsFixed(2)} from commuter wallet. New balance: ₱${newBalance.toStringAsFixed(2)}');

      // Create pending transaction linked to the trip
      final transactionNumber = 'KOMYUT-${DateTime.now().millisecondsSinceEpoch}';

      try {
        final insertedTxn = await supabase.from('transactions').insert({
          'transaction_number': transactionNumber,
          'wallet_id': walletId,
          'initiated_by_profile_id': profileId,
          'type': 'fare_payment',
          'amount': totalInitialPayment,
          'status': 'pending',
          'related_trip_id': widget.tripId,
          'processed_at': DateTime.now().toIso8601String(),
          'metadata': {
            'payment_type': 'initial_boarding',
            'initial_payment_per_person': widget.initialPayment,
            'passengers': _passengerCount,
          },
        }).select().maybeSingle();

        debugPrint('🧾 Inserted pending transaction id=${insertedTxn?["id"]} amount=₱${totalInitialPayment.toStringAsFixed(2)}');

        // Notifications are created server-side by a DB trigger on `transactions` inserts.
        debugPrint('ℹ️ Notification creation delegated to DB trigger for commuter debit');

        // Immediately attempt to transfer the initial payment to the driver via RPC
        try {
          // Determine driver_profile_id from trip details (drivers nested or metadata)
          String? driverProfileId;
          if (_tripDetails != null) {
            try {
              final drivers = _tripDetails!['drivers'];
              if (drivers != null) driverProfileId = drivers['profile_id'] as String?;
            } catch (_) {}
            if (driverProfileId == null) {
              try {
                final meta = _tripDetails!['metadata'] as Map<String, dynamic>?;
                if (meta != null) driverProfileId = meta['driver_profile_id'] as String?;
              } catch (_) {}
            }
          }

          if (driverProfileId != null) {
            final rpcParams = {
              'p_trip_id': widget.tripId,
              'p_driver_profile_id': driverProfileId,
              'p_amount': totalInitialPayment,
              'p_commuter_profile_id': profileId,
            };

            await supabase.rpc('transfer_trip_fare', params: rpcParams);
            debugPrint('✅ Initial payout RPC succeeded for trip ${widget.tripId} (₱${totalInitialPayment.toStringAsFixed(2)})');
              // Notifications are created server-side by a DB trigger on `transactions` inserts.
              debugPrint('ℹ️ Notification creation delegated to DB trigger for driver credit');
          } else {
            debugPrint('⚠️ Could not determine driver_profile_id to perform initial payout RPC');
          }
        } catch (e) {
          debugPrint('⚠️ Initial payout RPC failed: $e');
          try {
            // Annotate trip metadata so it can be retried later
            await supabase.from('trips').update({
              'metadata': {
                ...?(_tripDetails?['metadata'] as Map<String, dynamic>?),
                'payout_failed': true,
                'payout_error': e.toString(),
                'payout_amount': totalInitialPayment,
              }
            }).eq('id', widget.tripId);
          } catch (e2) {
            debugPrint('❌ Failed to annotate trip with payout failure: $e2');
          }
        }
      } catch (e) {
        // Transaction insert failed: attempt to rollback the wallet update
        debugPrint('❌ Failed to create pending transaction after wallet deduction: $e');
        try {
          await supabase
              .from('wallets')
              .update({'balance': balance, 'updated_at': DateTime.now().toIso8601String()})
              .eq('owner_profile_id', profileId);
          debugPrint('🔄 Rolled back commuter wallet update for profile $profileId');
        } catch (e2) {
          debugPrint('❌ Failed to rollback wallet update: $e2');
        }

        _showSimpleError('Failed to record payment; no funds were deducted.');
        return false;
      }

      // Update trip passengers_count and fare_amount
      try {
        await supabase.from('trips').update({
          'passengers_count': _passengerCount,
          'fare_amount': totalInitialPayment,
        }).eq('id', widget.tripId);
      } catch (e) {
        debugPrint('⚠️ Failed to update trip after initial payment: $e');
      }

      // Show success to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('₱${totalInitialPayment.toStringAsFixed(2)} charged for boarding.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      debugPrint('✅ Initial payment processed: ₱$totalInitialPayment');
      return true;
    } catch (e) {
      debugPrint('❌ Error processing initial payment: $e');
      _showSimpleError('Failed to process payment: $e');
      return false;
    }
  }

  void _showSimpleError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openQRScanner() async {
    await _updatePassengerCount();

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(
          onScanComplete: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : widget.currentLocation ?? const LatLng(10.3157, 123.8854);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 15.0,
              minZoom: 5.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.app',
                maxZoom: 19,
                retinaMode: RetinaMode.isHighDensity(context),
              ),
              PolylineLayer(polylines: _buildPolylines()),
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),

          Positioned(
            top: 50,
            left: 16,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (_hasConfirmed) {
                    Navigator.pushReplacementNamed(context, '/home_commuter');
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
            ),
          ),

          Positioned(
            top: 50,
            right: 16,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: _isLoadingLocation
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.my_location),
                      color: const Color(0xFF8E4CB6),
                      onPressed: _getCurrentLocation,
                    ),
            ),
          ),

          if (!_hasConfirmed)
            _buildTripDetailsSheet()
          else
            _buildScanForDepartureButton(),
        ],
      ),
    );
  }

  Widget _buildTripDetailsSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.6,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 15,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Driver info
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF8E4CB6),
                                Color(0xFFB945AA),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getDriverName(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              _isLoadingRating
                                  ? Row(
                                      children: [
                                        SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Loading rating...',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    )
                                  : _driverRating != null
                                      ? Row(
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _driverRating!.toStringAsFixed(1),
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            Icon(
                                              Icons.star_border,
                                              color: Colors.grey.shade400,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'No ratings yet',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Passenger count selector
                    const Text(
                      'How many are you?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            onPressed: _passengerCount > 1
                                ? () {
                                    setState(() {
                                      _passengerCount--;
                                    });
                                  }
                                : null,
                            icon: Icon(
                              Icons.remove,
                              color: _passengerCount > 1
                                  ? Colors.black
                                  : Colors.grey.shade400,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        Container(
                          width: 100,
                          alignment: Alignment.center,
                          child: Text(
                            '$_passengerCount',
                            style: const TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            onPressed: _passengerCount < 10
                                ? () {
                                    setState(() {
                                      _passengerCount++;
                                    });
                                  }
                                : null,
                            icon: Icon(
                              Icons.add,
                              color: _passengerCount < 10
                                  ? Colors.black
                                  : Colors.grey.shade400,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Trip Details Section
                    const Text(
                      'Trip Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Route stops
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF8E4CB6),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.originStopName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 5),
                            child: Row(
                              children: [
                                Container(
                                  width: 2,
                                  height: 30,
                                  color: Colors.grey.shade300,
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.destinationStopName ?? 'Destination',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Wallet and Payment Details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.account_balance_wallet,
                              size: 20,
                              color: Color(0xFF8E4CB6),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'My Wallet',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'PHP ${_walletBalance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8E4CB6),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Payment Detail',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildPaymentRow('Base Fare', 'PHP ${widget.initialPayment.toStringAsFixed(2)}'),
                    _buildPaymentRow('Passengers', '$_passengerCount'),
                    _buildPaymentRow('Subtotal', 'PHP ${(widget.initialPayment * _passengerCount).toStringAsFixed(2)}'),
                    const Divider(height: 20),
                    _buildPaymentRow(
                      'Total Initial Payment',
                      'PHP ${(widget.initialPayment * _passengerCount).toStringAsFixed(2)}',
                      isTotal: true,
                    ),

                    const SizedBox(height: 24),

                    // Swipe to Proceed
                    _buildSwipeButton(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentRow(String label, String amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black : Colors.grey.shade700,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.bold,
              color: isTotal ? const Color(0xFF8E4CB6) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildScanForDepartureButton() {
    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5B53C2), Color(0xFFB945AA)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5B53C2).withAlpha(102),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _openQRScanner,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(
            Icons.qr_code_scanner,
            color: Colors.white,
            size: 28,
          ),
          label: const Text(
            'Scan for Departure',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}