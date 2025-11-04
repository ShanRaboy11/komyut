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

  const OngoingTripScreen({
    super.key,
    required this.tripId,
    required this.driverName,
    required this.routeCode,
    required this.originStopName,
    this.currentLocation,
    required this.routeStops,
    this.originStopId,
  });

  @override
  State<OngoingTripScreen> createState() => _OngoingTripScreenState();
}

class _OngoingTripScreenState extends State<OngoingTripScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  int _passengerCount = 1;
  bool _isLoadingLocation = false;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
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

      // Animate to user location
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

    // Add current location marker
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

    // Add route stops
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
      await supabase.from('trips').update({
        'passengers_count': _passengerCount,
      }).eq('id', widget.tripId);

      debugPrint('✅ Updated passenger count to: $_passengerCount');
    } catch (e) {
      debugPrint('❌ Error updating passenger count: $e');
    }
  }

  void _openQRScanner() async {
    // Update passenger count before scanning
    await _updatePassengerCount();

    if (!mounted) return;

    // Navigate to QR scanner for arrival scan
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(
          onScanComplete: () {
            // Trip completed, scanner will handle navigation to payment screen
          },
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
          // Map in background
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

          // Back button
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

          // Refresh location button
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

          // Draggable bottom sheet
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.35,
            minChildSize: 0.35,
            maxChildSize: 0.75,
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
                    // Drag handle
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
                                      widget.driverName,
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

                          // Passenger counter
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Minus button
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

                              // Count display
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

                              // Plus button
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

                          const SizedBox(height: 32),

                          // Scan for departure button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF5B53C2),
                                    Color(0xFFB945AA),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        const Color(0xFF5B53C2).withAlpha(102),
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
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.qr_code_scanner,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                label: const Text(
                                  'Scan for Departure',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}