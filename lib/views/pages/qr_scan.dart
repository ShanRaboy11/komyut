import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../widgets/background_circles.dart';
import './fare_payment.dart';
import './ongoing_trip.dart';

class QRScannerScreen extends StatefulWidget {
  final VoidCallback? onScanComplete;
  final String? tripId;
  final bool isArrivalScan;
  final int passengerCount;

  const QRScannerScreen({
    super.key,
    this.onScanComplete,
    this.tripId,
    this.isArrivalScan = false,
    this.passengerCount = 1,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with SingleTickerProviderStateMixin {
  MobileScannerController cameraController = MobileScannerController();
  bool isScanning = true;
  bool isFlashOn = false;
  final ImagePicker _imagePicker = ImagePicker();
  late AnimationController _animationController;
  late Animation<double> _animation;

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);

    cameraController.start();
  }

  @override
  void dispose() {
    _animationController.dispose();
    cameraController.stop();
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture barcodeCapture) {
    if (!isScanning || _isProcessing) return;

    final List<Barcode> barcodes = barcodeCapture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        final cleanCode = code.trim();
        debugPrint('📱 QR Code detected: "$cleanCode"');

        cameraController.stop();

        setState(() {
          isScanning = false;
          _isProcessing = true;
        });

        _handleScannedCode(cleanCode);
      }
    }
  }

  Future<void> _handleScannedCode(String qrCode) async {
    _animationController.stop();

    try {
      final trimmedQR = qrCode.trim();
      final normalizedQR = trimmedQR.toUpperCase();

      debugPrint('🔍 ============ QR CODE SCAN DEBUG ============');

      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        _showError('Please log in to continue');
        _resetScanner();
        return;
      }

      final profileResponse = await supabase
          .from('profiles')
          .select('id, role')
          .eq('user_id', userId)
          .maybeSingle();

      if (profileResponse == null) {
        _showError('User profile not found. Please complete registration.');
        _resetScanner();
        return;
      }

      final profileId = profileResponse['id'] as String;
      final role = profileResponse['role'] as String;

      if (role != 'commuter') {
        _showError('This feature is only available for commuters');
        _resetScanner();
        return;
      }

      debugPrint('✅ Profile ID: $profileId');

      // Get driver information with route stops
      final driverResponse = await _findDriver(trimmedQR, normalizedQR);

      if (driverResponse == null) {
        _showError(
          'Invalid QR code\n\n'
          'Scanned: "$trimmedQR"\n'
          'Please scan a valid driver QR code.',
        );
        _resetScanner();
        return;
      }

      debugPrint('✅ ============ MATCH SUCCESS ============');

      final driverId = driverResponse['id'] as String;
      final routeId = driverResponse['route_id'] as String?;
      final puvType = driverResponse['puv_type'] as String? ?? 'traditional';

      if (routeId == null) {
        _showError('This driver is not assigned to any route');
        _resetScanner();
        return;
      }

      // Load route stops
      final routeStops = await _loadRouteStops(routeId);

      if (routeStops.isEmpty) {
        _showError('Route has no stops configured');
        _resetScanner();
        return;
      }

      // Check for existing ongoing trip or if this is a continuation
      final existingTrip = widget.isArrivalScan && widget.tripId != null
          ? await supabase
              .from('trips')
              .select('id, origin_stop_id, started_at, driver_id, route_id, metadata, passengers_count')
              .eq('id', widget.tripId!)
              .eq('status', 'ongoing')
              .maybeSingle()
          : await supabase
              .from('trips')
              .select('id, origin_stop_id, started_at, driver_id, route_id, metadata, passengers_count')
              .eq('created_by_profile_id', profileId)
              .eq('status', 'ongoing')
              .maybeSingle();

      if (existingTrip != null) {
        debugPrint('🔄 Existing trip found: ${existingTrip['id']}');
        // SECOND SCAN - Arrival at destination
        await _handleArrivalScan(
          existingTrip['id'],
          existingTrip['origin_stop_id'],
          existingTrip['metadata'],
          routeStops,
          puvType,
          profileId,
          existingTrip['passengers_count'] ?? 1,
        );
      } else {
        debugPrint('🚌 First scan - Creating new trip');
        // FIRST SCAN - Boarding/Takeoff
        await _handleTakeoffScan(
          driverId,
          routeId,
          profileId,
          trimmedQR,
          puvType,
          routeStops,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ ============ ERROR ============');
      debugPrint('❌ Error: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      _showError('Error processing QR code: ${e.toString()}');
      _resetScanner();
    }
  }

  Future<Map<String, dynamic>?> _findDriver(
      String trimmedQR, String normalizedQR) async {
    final supabase = Supabase.instance.client;

    final allDriversResponse = await supabase
        .from('drivers')
        .select('''
          id, 
          profile_id,
          current_qr,
          route_id,
          vehicle_plate,
          operator_name,
          puv_type,
          active,
          routes:route_id (
            id,
            code,
            name
          ),
          profiles:profile_id (
            first_name,
            last_name
          )
        ''')
        .eq('active', true)
        .not('current_qr', 'is', null);

    if (allDriversResponse.isEmpty) {
      return null;
    }

    // Try exact match
    for (var driver in allDriversResponse) {
      final dbQR = (driver['current_qr'] as String?)?.trim() ?? '';
      if (dbQR == trimmedQR) {
        return driver;
      }
    }

    // Try case-insensitive match
    for (var driver in allDriversResponse) {
      final dbQR =
          (driver['current_qr'] as String?)?.trim().toUpperCase() ?? '';
      if (dbQR == normalizedQR) {
        return driver;
      }
    }

    return null;
  }

  Future<List<Map<String, dynamic>>> _loadRouteStops(String routeId) async {
    final supabase = Supabase.instance.client;

    final stopsResponse = await supabase
        .from('route_stops')
        .select('id, name, sequence, latitude, longitude')
        .eq('route_id', routeId)
        .order('sequence', ascending: true);

    return List<Map<String, dynamic>>.from(stopsResponse);
  }

  // Find the closest stop to a given location
  Map<String, dynamic>? _findClosestStop(
    double lat,
    double lng,
    List<Map<String, dynamic>> stops,
  ) {
    if (stops.isEmpty) return null;

    Map<String, dynamic>? closestStop;
    double minDistance = double.infinity;

    for (var stop in stops) {
      final stopLat = stop['latitude'] as double;
      final stopLng = stop['longitude'] as double;

      final distance = Geolocator.distanceBetween(lat, lng, stopLat, stopLng);

      if (distance < minDistance) {
        minDistance = distance;
        closestStop = stop;
      }
    }

    // Only return if within 500 meters
    if (minDistance <= 500) {
      debugPrint('📍 Closest stop: ${closestStop!['name']} (${minDistance.toStringAsFixed(0)}m away)');
      return closestStop;
    }

    return null;
  }

  // Calculate route distance between two stops
  double _calculateRouteDistance(
    String? originStopId,
    String? destinationStopId,
    List<Map<String, dynamic>> stops,
  ) {
    if (originStopId == null || destinationStopId == null || stops.isEmpty) {
      return 0.0;
    }

    // Find origin and destination stops
    final originIndex = stops.indexWhere((s) => s['id'] == originStopId);
    final destIndex = stops.indexWhere((s) => s['id'] == destinationStopId);

    if (originIndex == -1 || destIndex == -1) {
      return 0.0;
    }

    // Allow same stop (minimum fare applies)
    if (originIndex == destIndex) {
      debugPrint('📏 Same stop - applying minimum fare');
      return 0.0;
    }

    // Calculate cumulative distance along the route
    // Support both forward and backward travel
    double totalDistance = 0.0;
    
    if (originIndex < destIndex) {
      // Forward direction: origin → destination
      for (int i = originIndex; i < destIndex; i++) {
        final currentStop = stops[i];
        final nextStop = stops[i + 1];

        final distance = Geolocator.distanceBetween(
          currentStop['latitude'],
          currentStop['longitude'],
          nextStop['latitude'],
          nextStop['longitude'],
        );

        totalDistance += distance;
      }
      debugPrint('📏 Forward route distance from stop ${originIndex + 1} to ${destIndex + 1}: ${totalDistance.toStringAsFixed(2)}m');
    } else {
      // Backward direction: destination ← origin (for return trips)
      for (int i = originIndex; i > destIndex; i--) {
        final currentStop = stops[i];
        final prevStop = stops[i - 1];

        final distance = Geolocator.distanceBetween(
          currentStop['latitude'],
          currentStop['longitude'],
          prevStop['latitude'],
          prevStop['longitude'],
        );

        totalDistance += distance;
      }
      debugPrint('📏 Backward route distance from stop ${originIndex + 1} to ${destIndex + 1}: ${totalDistance.toStringAsFixed(2)}m');
    }

    return totalDistance;
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied) {
          return null;
        }
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('❌ Error getting location: $e');
      return null;
    }
  }

  void _resetScanner() {
    setState(() {
      isScanning = true;
      _isProcessing = false;
    });
    _animationController.repeat(reverse: true);
    cameraController.start();
  }

  Future<void> _showSuccessModal({
    required String title,
    required String message,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFB945AA),
                  Color(0xFF8E4CB6),
                  Color(0xFF5B53C2),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(21),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 50,
                      height: 50,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8E4CB6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 90,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        backgroundColor: const Color(0xFF8E4CB6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleTakeoffScan(
    String driverId,
    String? routeId,
    String profileId,
    String qrCode,
    String puvType,
    List<Map<String, dynamic>> routeStops,
  ) async {
    final supabase = Supabase.instance.client;

    debugPrint('🚀 Creating trip for driver: $driverId, route: $routeId');

    try {
      // Step 3: Check wallet balance for initial payment (10 pesos per passenger)
      const double initialPaymentPerPerson = 10.00;

      final walletResponse = await supabase
          .from('wallets')
          .select('id, balance')
          .eq('owner_profile_id', profileId)
          .maybeSingle();

      if (walletResponse == null) {
        _showError('Wallet not found. Please contact support.');
        _resetScanner();
        return;
      }

      final walletId = walletResponse['id'] as String;
      final balance = (walletResponse['balance'] as num).toDouble();

      // Calculate initial payment based on default 1 passenger (will be updated after confirmation)
      final initialPayment = initialPaymentPerPerson;

      // Step 4: Check if there's enough balance
      if (balance < initialPayment) {
        _showError(
          'Insufficient balance!\n\n'
          'Current balance: ₱${balance.toStringAsFixed(2)}\n'
          'Required: ₱${initialPayment.toStringAsFixed(2)}\n\n'
          'Please top up your wallet.',
        );
        _resetScanner();
        return;
      }

      // Step 5: Get current location
      final position = await _getCurrentPosition();

      if (position == null) {
        _showError('Unable to get your location. Please enable location services.');
        _resetScanner();
        return;
      }

      // Find closest stop to boarding location
      final originStop = _findClosestStop(
        position.latitude,
        position.longitude,
        routeStops,
      );

      if (originStop == null) {
        _showError(
          'You are too far from the route!\n\n'
          'Please board at a designated stop along the route.',
        );
        _resetScanner();
        return;
      }

      final boardingLocation = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': DateTime.now().toIso8601String(),
        'closest_stop_id': originStop['id'],
        'closest_stop_name': originStop['name'],
      };

      debugPrint('📍 Boarding at stop: ${originStop['name']}');

      // Deduct initial payment from wallet
      await supabase.from('wallets').update({
        'balance': balance - initialPayment,
      }).eq('id', walletId);

      // Create initial transaction for boarding
      final transactionNumber = 'TXN-${DateTime.now().millisecondsSinceEpoch}';
      
      final transactionResponse = await supabase
          .from('transactions')
          .insert({
            'transaction_number': transactionNumber,
            'wallet_id': walletId,
            'initiated_by_profile_id': profileId,
            'type': 'fare_payment',
            'amount': initialPayment,
            'status': 'pending',
            'metadata': {
              'payment_type': 'initial_boarding',
              'puv_type': puvType,
              'initial_payment_per_person': initialPaymentPerPerson,
            },
          })
          .select()
          .single();

      final transactionId = transactionResponse['id'] as String;

      // Get driver information before creating trip with proper profile join
      final driverInfo = await supabase
          .from('drivers')
          .select('''
            id,
            vehicle_plate,
            puv_type,
            profile_id,
            profiles:profile_id (
              first_name,
              last_name
            ),
            routes:route_id (
              code,
              name
            )
          ''')
          .eq('id', driverId)
          .single();

      debugPrint('🔍 Driver Info Retrieved: $driverInfo');

      final driverProfile = driverInfo['profiles'];
      final route = driverInfo['routes'];
      
      String driverName = 'Driver';
      if (driverProfile != null) {
        final firstName = driverProfile['first_name'] ?? '';
        final lastName = driverProfile['last_name'] ?? '';
        if (firstName.isNotEmpty || lastName.isNotEmpty) {
          driverName = '$firstName $lastName'.trim();
        }
      }
      
      debugPrint('👤 Driver Name: $driverName');
      
      final routeCodeStr = route?['code'] ?? routeId ?? '';

      // Step 6: Create trip with ongoing status
      final result = await supabase
          .from('trips')
          .insert({
            'driver_id': driverId,
            'route_id': routeId,
            'origin_stop_id': originStop['id'],
            'created_by_profile_id': profileId,
            'status': 'ongoing',
            'fare_amount': initialPayment,
            'passengers_count': 1, // Default, will be updated when user confirms
            'started_at': DateTime.now().toIso8601String(),
            'metadata': {
              'takeoff_qr': qrCode,
              'boarding_location': boardingLocation,
              'initial_payment': initialPayment,
              'initial_payment_per_person': initialPaymentPerPerson,
              'puv_type': puvType,
              'driver_name': driverName,
              'driver_first_name': driverProfile?['first_name'] ?? '',
              'driver_last_name': driverProfile?['last_name'] ?? '',
              'route_code': routeCodeStr,
            },
          })
          .select()
          .single();

      final tripId = result['id'] as String;

      // Link transaction to trip
      await supabase.from('transactions').update({
        'related_trip_id': tripId,
      }).eq('id', transactionId);

      debugPrint('✅ Trip created successfully: $tripId');
      debugPrint('💰 Initial payment: ₱$initialPayment');
      debugPrint('📍 Boarding location: ${position.latitude}, ${position.longitude}');
      debugPrint('🚏 Origin stop: ${originStop['name']}');

      if (!mounted) return;

      // Navigate to ongoing trip screen with all required parameters
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OngoingTripScreen(
            tripId: tripId,
            driverName: driverName,
            routeCode: routeCodeStr,
            originStopName: originStop['name'],
            currentLocation: LatLng(position.latitude, position.longitude),
            routeStops: routeStops,
            originStopId: originStop['id'],
            initialPayment: initialPaymentPerPerson,
          ),
        ),
      );

      widget.onScanComplete?.call();
    } catch (e) {
      debugPrint('❌ Error creating trip: $e');
      _showError('Failed to create trip: ${e.toString()}');
      _resetScanner();
    }
  }

  Future<void> _handleArrivalScan(
  String tripId,
  String? originStopId,
  Map<String, dynamic> tripMetadata,
  List<Map<String, dynamic>> routeStops,
  String puvType,
  String profileId,
  int passengerCount,
) async {
  final supabase = Supabase.instance.client;

  debugPrint('🏁 Completing trip: $tripId');
  debugPrint('👥 Passenger count: $passengerCount');

  try {
    // Step 7: Get current location for destination
    final position = await _getCurrentPosition();

    if (position == null) {
      _showError('Unable to get your location. Please enable location services.');
      _resetScanner();
      return;
    }

    // Find closest stop to arrival location
    final destinationStop = _findClosestStop(
      position.latitude,
      position.longitude,
      routeStops,
    );

    if (destinationStop == null) {
      _showError(
        'You are too far from the route!\n\n'
        'Please scan at a designated stop along the route.',
      );
      _resetScanner();
      return;
    }

    final arrivalLocation = {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': DateTime.now().toIso8601String(),
      'closest_stop_id': destinationStop['id'],
      'closest_stop_name': destinationStop['name'],
    };

    debugPrint('📍 Arrived at stop: ${destinationStop['name']}');

    final initialPaymentPerPerson = (tripMetadata['initial_payment_per_person'] as num?)?.toDouble() ?? 10.0;

    // Step 8: Calculate distance using route stops
    final distanceInMeters = _calculateRouteDistance(
      originStopId,
      destinationStop['id'],
      routeStops,
    );

    if (distanceInMeters == 0 && originStopId != destinationStop['id']) {
      _showError(
        'Error calculating distance!\n\n'
        'Please try scanning again.',
      );
      _resetScanner();
      return;
    }

    final distanceInKm = distanceInMeters / 1000;

    debugPrint('📏 Route distance traveled: ${distanceInKm.toStringAsFixed(2)} km');

    // NEW: Check discount eligibility
    final discountInfo = await _checkDiscountEligibility(profileId);
    final isDiscountEligible = discountInfo['eligible'] as bool;
    final discountRate = (discountInfo['discount_rate'] as num).toDouble();

    // Calculate fare per person with discount if eligible
    double farePerPerson = _calculateFare(distanceInKm, puvType, discountRate: discountRate);
    
    // Calculate original fare (without discount) for display
    double originalFarePerPerson = _calculateFare(distanceInKm, puvType, discountRate: 0.0);
    double originalFareTotal = originalFarePerPerson * passengerCount;
    
    // Calculate total fare for all passengers (with discount applied)
    double totalFare = farePerPerson * passengerCount;
    
    // Calculate initial payment made (per person * passenger count)
    double initialPaymentTotal = initialPaymentPerPerson * passengerCount;
    
    // Subtract initial payment already made
    double additionalFare = totalFare - initialPaymentTotal;
    if (additionalFare < 0) additionalFare = 0;

    debugPrint('💰 Fare per person (original): ₱${originalFarePerPerson.toStringAsFixed(2)}');
    if (isDiscountEligible) {
      debugPrint('🎫 Discount applied: ${(discountRate * 100).toStringAsFixed(0)}%');
      debugPrint('💰 Fare per person (discounted): ₱${farePerPerson.toStringAsFixed(2)}');
    }
    debugPrint('👥 Passengers: $passengerCount');
    debugPrint('💰 Original total fare: ₱${originalFareTotal.toStringAsFixed(2)}');
    debugPrint('💰 Final total fare: ₱${totalFare.toStringAsFixed(2)}');
    debugPrint('💰 Already paid: ₱${initialPaymentTotal.toStringAsFixed(2)}');
    debugPrint('💰 Additional fare: ₱${additionalFare.toStringAsFixed(2)}');

    // Step 9: Process payment if there's additional fare
    if (additionalFare > 0) {
      final walletResponse = await supabase
          .from('wallets')
          .select('id, balance')
          .eq('owner_profile_id', profileId)
          .single();

      final walletId = walletResponse['id'] as String;
      final balance = (walletResponse['balance'] as num).toDouble();

      if (balance < additionalFare) {
        _showError(
          'Insufficient balance for additional fare!\n\n'
          'Current balance: ₱${balance.toStringAsFixed(2)}\n'
          'Required: ₱${additionalFare.toStringAsFixed(2)}',
        );
        _resetScanner();
        return;
      }

      // Deduct additional fare
      await supabase.from('wallets').update({
        'balance': balance - additionalFare,
      }).eq('id', walletId);

      // Step 10: Create transaction with barcode
      final transactionNumber = 'TXN-${DateTime.now().millisecondsSinceEpoch}';

      await supabase.from('transactions').insert({
        'transaction_number': transactionNumber,
        'wallet_id': walletId,
        'initiated_by_profile_id': profileId,
        'type': 'fare_payment',
        'amount': additionalFare,
        'status': 'completed',
        'related_trip_id': tripId,
        'processed_at': DateTime.now().toIso8601String(),
        'metadata': {
          'payment_type': 'additional_fare',
          'distance_km': distanceInKm,
          'puv_type': puvType,
          'passengers': passengerCount,
          'fare_per_person': farePerPerson,
          'discount_applied': isDiscountEligible,
        },
      });
    }

    // Step 11 & 12: Update trip and complete transaction
    final tripResponse = await supabase
        .from('trips')
        .select('driver_id')
        .eq('id', tripId)
        .single();

    final driverId = tripResponse['driver_id'] as String;

    // Get driver's profile to find their wallet
    final driverProfileResponse = await supabase
        .from('drivers')
        .select('profile_id')
        .eq('id', driverId)
        .single();

    final driverProfileId = driverProfileResponse['profile_id'] as String;

    // Step 12: Transfer payment to driver's wallet
    final driverWalletResponse = await supabase
        .from('wallets')
        .select('id, balance')
        .eq('owner_profile_id', driverProfileId)
        .maybeSingle();

    if (driverWalletResponse != null) {
      final driverWalletId = driverWalletResponse['id'] as String;
      final driverBalance = (driverWalletResponse['balance'] as num).toDouble();

      await supabase.from('wallets').update({
        'balance': driverBalance + totalFare,
      }).eq('id', driverWalletId);

      debugPrint('✅ Transferred ₱${totalFare.toStringAsFixed(2)} to driver wallet');
    }

    // Step 13: Update trip as completed with discount information
    await supabase.from('trips').update({
      'status': 'completed',
      'destination_stop_id': destinationStop['id'],
      'distance_meters': distanceInMeters.round(),
      'fare_amount': totalFare,
      'passengers_count': passengerCount,
      'ended_at': DateTime.now().toIso8601String(),
      'metadata': {
        ...tripMetadata,
        'arrival_location': arrivalLocation,
        'total_fare': totalFare,
        'fare_per_person': farePerPerson,
        'additional_fare': additionalFare,
        'passengers': passengerCount,
        'discount_applied': isDiscountEligible,
        'discount_rate': discountRate,
        'original_fare': originalFareTotal,
        'category': discountInfo['category'],
      },
    }).eq('id', tripId);

    // Mark initial transaction as completed
    await supabase
        .from('transactions')
        .update({
          'status': 'completed',
          'processed_at': DateTime.now().toIso8601String(),
          'metadata': {
            'payment_type': 'initial_boarding',
            'puv_type': puvType,
            'passengers': passengerCount,
            'initial_payment_per_person': initialPaymentPerPerson,
          },
        })
        .eq('related_trip_id', tripId)
        .eq('status', 'pending');

    // NEW: Award wheel tokens for completed trip
    await _awardWheelTokens(profileId, tripId);

    debugPrint('✅ Trip completed successfully');
    debugPrint('🎁 Wheel token awarded');

    if (!mounted) return;

    // Get origin stop name from metadata
    final originStopName = tripMetadata['boarding_location']?['closest_stop_name'] ?? 'Unknown';

    // Navigate to payment summary screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RideBookingScreen(
          tripId: tripId,
          fareAmount: totalFare,
          distanceMeters: distanceInMeters.round(),
          boardingLocation: LatLng(
            tripMetadata['boarding_location']['latitude'],
            tripMetadata['boarding_location']['longitude'],
          ),
          arrivalLocation: LatLng(position.latitude, position.longitude),
          routeStops: routeStops,
          originStopName: originStopName,
          destinationStopName: destinationStop['name'],
        ),
      ),
    );
  } catch (e) {
    debugPrint('❌ Error completing trip: $e');
    _showError('Failed to complete trip: ${e.toString()}');
    _resetScanner();
  }
}

  // Step 8: Calculate fare based on distance and PUV type (per person)
double _calculateFare(double distanceKm, String puvType, {double discountRate = 0.0}) {
  double baseFare;
  double baseDistance;
  double perKmRate = 1.0;

  if (puvType.toLowerCase() == 'modern') {
    baseFare = 15.0;
    baseDistance = 4.0;
  } else {
    // traditional
    baseFare = 13.0;
    baseDistance = 4.0;
  }

  double fare;
  if (distanceKm <= baseDistance) {
    fare = baseFare;
  } else {
    double additionalDistance = distanceKm - baseDistance;
    double additionalFare = additionalDistance * perKmRate;
    fare = baseFare + additionalFare;
  }
  
  // Apply discount if eligible
  if (discountRate > 0) {
    fare = fare * (1 - discountRate);
    debugPrint('💰 Discount applied: ${(discountRate * 100).toStringAsFixed(0)}% off');
  }

  return fare;
}

  Future<void> _pickImageFromGallery() async {
    try {
      cameraController.stop();

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (image != null) {
        final BarcodeCapture? barcodes = await cameraController.analyzeImage(
          image.path,
        );

        if (barcodes != null && barcodes.barcodes.isNotEmpty) {
          final String? code = barcodes.barcodes.first.rawValue;
          if (code != null) {
            final cleanCode = code.trim();
            setState(() {
              _isProcessing = true;
            });
            await _handleScannedCode(cleanCode);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No QR code found in the selected image'),
                backgroundColor: Colors.red,
              ),
            );
          }
          _resetScanner();
        }
      } else {
        _resetScanner();
      }
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      _resetScanner();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFDFDFF), Color(0xFFF1F0FA)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              const BackgroundCircles(),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () async {
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.arrow_back, size: 28),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'QR Scan',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40.0),
                      child: Text(
                        'Scan QR code when boarding and again when arriving at your destination',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0x99000000),
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25.0),
                          child: Stack(
                            children: [
                              MobileScanner(
                                controller: cameraController,
                                onDetect: _onDetect,
                              ),
                              CustomPaint(
                                painter: ScannerOverlay(),
                                child: const SizedBox.expand(),
                              ),
                              AnimatedBuilder(
                                animation: _animation,
                                builder: (context, child) {
                                  return CustomPaint(
                                    painter: ScannerLinePainter(
                                      _animation.value,
                                    ),
                                    child: const SizedBox.expand(),
                                  );
                                },
                              ),
                              Center(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(5.0),
                                  child: SizedBox(
                                    width: 250,
                                    height: 250,
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          top: -3,
                                          left: -3,
                                          child: _buildCorner(true, true),
                                        ),
                                        Positioned(
                                          top: -3,
                                          right: -3,
                                          child: _buildCorner(true, false),
                                        ),
                                        Positioned(
                                          bottom: -3,
                                          left: -3,
                                          child: _buildCorner(false, true),
                                        ),
                                        Positioned(
                                          bottom: -3,
                                          right: -3,
                                          child: _buildCorner(false, false),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 20,
                                left: 0,
                                right: 0,
                                child: Column(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          isFlashOn = !isFlashOn;
                                        });
                                        cameraController.toggleTorch();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isFlashOn
                                              ? Icons.flash_on
                                              : Icons.flash_off,
                                          color: const Color(0xFF9C27B0),
                                          size: 30,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_isProcessing)
                                Container(
                                  color: Colors.black54,
                                  child: const Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'Processing...',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: OutlinedButton.icon(
                        onPressed: _isProcessing ? null : _pickImageFromGallery,
                        icon: const Icon(Icons.image, color: Color(0xFF9C27B0)),
                        label: const Text(
                          'Upload QR',
                          style: TextStyle(
                            color: Color(0xFF9C27B0),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 16,
                          ),
                          side: const BorderSide(
                            color: Color(0xFF9C27B0),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCorner(bool isTop, bool isLeft) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: Color(0xFF9C27B0), width: 8)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: Color(0xFF9C27B0), width: 8)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: Color(0xFF9C27B0), width: 8)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: Color(0xFF9C27B0), width: 8)
              : BorderSide.none,
        ),
      ),
    );
  }
}

class ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withAlpha(204)
      ..style = PaintingStyle.fill;

    final centerSquareSize = 250.0;
    final left = (size.width - centerSquareSize) / 2;
    final top = (size.height - centerSquareSize) / 2;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, centerSquareSize, centerSquareSize),
      const Radius.circular(20.0),
    );

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(rect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class ScannerLinePainter extends CustomPainter {
  final double animationValue;

  ScannerLinePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final centerSquareSize = 250.0;
    final left = (size.width - centerSquareSize) / 2;
    final top = (size.height - centerSquareSize) / 2;

    final lineY = top + (centerSquareSize * animationValue);

    final paint = Paint()
      ..color = const Color(0xFF9C27B0)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(left, lineY),
      Offset(left + centerSquareSize, lineY),
      paint,
    );

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF9C27B0).withAlpha(0),
          const Color(0xFF9C27B0).withAlpha(77),
        ],
      ).createShader(Rect.fromLTWH(left, lineY - 30, centerSquareSize, 30));

    canvas.drawRect(
      Rect.fromLTWH(left, lineY - 30, centerSquareSize, 30),
      gradientPaint,
    );
  }

  @override
  bool shouldRepaint(ScannerLinePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

// Check if commuter is eligible for 20% discount
Future<Map<String, dynamic>> _checkDiscountEligibility(String profileId) async {
  try {
    final supabase = Supabase.instance.client;
    
    final commuterResponse = await supabase
        .from('commuters')
        .select('category, id_verified')
        .eq('profile_id', profileId)
        .maybeSingle();
    
    if (commuterResponse == null) {
      return {
        'eligible': false,
        'discount_rate': 0.0,
        'category': 'regular',
      };
    }
    
    final category = commuterResponse['category'] as String;
    final isVerified = commuterResponse['id_verified'] == true;
    
    // Eligible if: (senior OR student OR pwd) AND id_verified
    final isEligible = isVerified && (category == 'senior' || category == 'student' || category == 'pwd');
    
    debugPrint('🎫 Discount check - Category: $category, Verified: $isVerified, Eligible: $isEligible');
    
    return {
      'eligible': isEligible,
      'discount_rate': isEligible ? 0.20 : 0.0,
      'category': category,
    };
  } catch (e) {
    debugPrint('❌ Error checking discount eligibility: $e');
    return {
      'eligible': false,
      'discount_rate': 0.0,
      'category': 'regular',
    };
  }
}

// Award 1.0 wheel token for completed trip
Future<void> _awardWheelTokens(String profileId, String tripId) async {
  try {
    final supabase = Supabase.instance.client;
    
    // Get commuter ID
    final commuterResponse = await supabase
        .from('commuters')
        .select('id, wheel_tokens')
        .eq('profile_id', profileId)
        .single();
    
    final commuterId = commuterResponse['id'] as String;
    final currentTokens = (commuterResponse['wheel_tokens'] as num).toDouble();
    final newBalance = currentTokens + 1.0;
    
    // Update wheel tokens
    await supabase.from('commuters').update({
      'wheel_tokens': newBalance,
    }).eq('id', commuterId);
    
    // Record transaction
    await supabase.from('points_transactions').insert({
      'commuter_id': commuterId,
      'change': 1.0,
      'reason': 'Trip completion reward',
      'related_transaction_id': null,
      'balance_after': newBalance,
      'metadata': {
        'trip_id': tripId,
        'reward_type': 'trip_completion',
      },
    });
    
    debugPrint('🎁 Awarded 1.0 wheel token! New balance: $newBalance');
  } catch (e) {
    debugPrint('❌ Error awarding wheel tokens: $e');
    // Don't fail the trip completion if token award fails
  }
}