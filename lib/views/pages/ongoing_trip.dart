import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadTripDetails();
    _loadWalletBalance();
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
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8E4CB6), Color(0xFFB945AA)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Trip Confirmed!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8E4CB6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You\'re traveling with $_passengerCount ${_passengerCount == 1 ? 'passenger' : 'passengers'}.\n\nScan the QR code again when you reach your destination.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {
                          _hasConfirmed = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF8E4CB6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Continue',
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
                onPressed: () => Navigator.pop(context),
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
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '4.8',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
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
                  Icons.qr_code_scanner,
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