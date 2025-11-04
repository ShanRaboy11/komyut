import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../widgets/map.dart';

class RideBookingScreen extends StatefulWidget {
  final String? tripId;
  final double? fareAmount;
  final int? distanceMeters;
  final LatLng? boardingLocation;
  final LatLng? arrivalLocation;
  final List<Map<String, dynamic>>? routeStops;
  final String? originStopName;
  final String? destinationStopName;

  const RideBookingScreen({
    super.key,
    this.tripId,
    this.fareAmount,
    this.distanceMeters,
    this.boardingLocation,
    this.arrivalLocation,
    this.routeStops,
    this.originStopName,
    this.destinationStopName,
  });

  @override
  State<RideBookingScreen> createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends State<RideBookingScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  bool _isLoading = true;
  String? _transactionNumber;
  Map<String, dynamic>? _tripDetails;

  final LatLng _defaultLocation = const LatLng(10.3157, 123.8854);

  @override
  void initState() {
    super.initState();

    if (widget.tripId != null) {
      debugPrint('Trip ID: ${widget.tripId}');
      debugPrint('Fare: ${widget.fareAmount}');
      debugPrint('Distance: ${widget.distanceMeters}m');
      _loadTripDetails();
    }

    _getCurrentLocation();
  }

  Future<void> _loadTripDetails() async {
    try {
      final supabase = Supabase.instance.client;
      
      // Get trip details with driver information
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
            )
          ''')
          .eq('id', widget.tripId!)
          .single();

      // Get transaction number
      final transactionResponse = await supabase
          .from('transactions')
          .select('transaction_number')
          .eq('related_trip_id', widget.tripId!)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      setState(() {
        _tripDetails = tripResponse;
        _transactionNumber = transactionResponse?['transaction_number'];
        _isLoading = false;
      });

      debugPrint('✅ Trip details loaded');
      debugPrint('📝 Transaction number: $_transactionNumber');
    } catch (e) {
      debugPrint('❌ Error loading trip details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Permission.location.request();

      if (permission.isGranted) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            mapController: _mapController,
            currentPosition: _currentPosition,
            defaultLocation: _defaultLocation,
            isLoading: false,
            boardingLocation: widget.boardingLocation,
            arrivalLocation: widget.arrivalLocation,
            routeStops: widget.routeStops,
            originStopId: _tripDetails?['origin_stop_id'],
            destinationStopId: _tripDetails?['destination_stop_id'],
          ),
          Positioned(
            top: 50,
            left: 16,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildPaymentSummary(),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    if (_isLoading || _tripDetails == null) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final driver = _tripDetails!['drivers'];
    final route = _tripDetails!['routes'];
    final driverName = driver != null && driver['profiles'] != null
        ? '${driver['profiles']['first_name']} ${driver['profiles']['last_name']}'
        : 'Unknown';
    final vehiclePlate = driver?['vehicle_plate'] ?? 'N/A';
    final puvType = driver?['puv_type'] ?? 'traditional';
    final routeName = route?['name'] ?? 'Unknown Route';
    final routeCode = route?['code'] ?? '';

    final distanceKm = (widget.distanceMeters ?? 0) / 1000;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trip Completed!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Payment successful',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Transaction barcode
            if (_transactionNumber != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    BarcodeWidget(
                      barcode: Barcode.code128(),
                      data: _transactionNumber!,
                      width: 250,
                      height: 80,
                      drawText: false,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _transactionNumber!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Trip details
            _buildDetailRow('Driver', driverName),
            _buildDetailRow('Vehicle', '$vehiclePlate (${puvType.toUpperCase()})'),
            _buildDetailRow('Route', '$routeCode - $routeName'),
            if (widget.originStopName != null && widget.destinationStopName != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.trip_origin, color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.originStopName!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Icon(
                  Icons.arrow_downward,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.destinationStopName!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Divider(height: 32),
            
            // Payment breakdown
            _buildDetailRow(
              'Distance',
              '${distanceKm.toStringAsFixed(2)} km',
            ),
            _buildDetailRow(
              'Fare',
              '₱${widget.fareAmount?.toStringAsFixed(2) ?? '0.00'}',
              isHighlighted: true,
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Implement receipt download/share
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Receipt feature coming soon'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Receipt'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF8E4CB6)),
                      foregroundColor: const Color(0xFF8E4CB6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    icon: const Icon(Icons.home),
                    label: const Text('Home'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF8E4CB6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isHighlighted ? 18 : 16,
              color: isHighlighted ? Colors.black : Colors.grey.shade700,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isHighlighted ? 20 : 16,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
              color: isHighlighted ? const Color(0xFF8E4CB6) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}