import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:gal/gal.dart';
import '../widgets/map.dart';
import 'commuter_app.dart';

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
  bool _isDownloading = false;
  final GlobalKey _receiptKey = GlobalKey();

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
              profile_id,
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
          .eq('id', widget.tripId!)
          .single();

      // Get transaction number - get the most recent completed transaction
      final transactionResponse = await supabase
          .from('transactions')
          .select('transaction_number')
          .eq('related_trip_id', widget.tripId!)
          .eq('status', 'completed')
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
      debugPrint('👤 Driver info: ${tripResponse['drivers']}');
      debugPrint('👤 Driver profile: ${tripResponse['drivers']?['profiles']}');
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

  String _getDriverName() {
    if (_tripDetails != null) {
      final driver = _tripDetails!['drivers'];
      if (driver != null) {
        final profiles = driver['profiles'];
        if (profiles != null) {
          final firstName = profiles['first_name'] ?? '';
          final lastName = profiles['last_name'] ?? '';
          if (firstName.isNotEmpty || lastName.isNotEmpty) {
            return '$firstName $lastName'.trim();
          }
        }
      }
      
      // Fallback to metadata if driver info not available
      final metadata = _tripDetails!['metadata'] as Map<String, dynamic>?;
      if (metadata != null && metadata.containsKey('driver_name')) {
        return metadata['driver_name'];
      }
    }
    return 'Unknown Driver';
  }

  Future<void> _downloadReceipt() async {
    setState(() => _isDownloading = true);

    try {
      // Check and request storage permission
      final hasPermission = await Gal.hasAccess();
      if (!hasPermission) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Storage permission denied. Cannot save receipt.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isDownloading = false);
          return;
        }
      }

      // Capture the receipt widget as an image
      final RenderRepaintBoundary boundary = _receiptKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Get the temporary directory
      final directory = await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'receipt_${_transactionNumber ?? timestamp}.png';
      final File file = File('${directory.path}/$fileName');
      
      // Write the file
      await file.writeAsBytes(pngBytes);

      // Save to gallery using Gal
      await Gal.putImage(file.path, album: 'Komyut Receipts');

      // Delete temporary file
      await file.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Receipt saved to gallery successfully!'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error downloading receipt: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Failed to save receipt: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map background
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
          
          // Draggable scrollable receipt
          DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            builder: (BuildContext context, ScrollController scrollController) {
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
                    
                    // Receipt content wrapped with RepaintBoundary for screenshot
                    RepaintBoundary(
                      key: _receiptKey,
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(24),
                        child: _buildReceiptContent(),
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

  Widget _buildReceiptContent() {
    if (_isLoading || _tripDetails == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final driver = _tripDetails!['drivers'];
    final route = _tripDetails!['routes'];
    final metadata = _tripDetails!['metadata'] as Map<String, dynamic>?;
    
    final driverName = _getDriverName();
    final vehiclePlate = driver?['vehicle_plate'] ?? 'N/A';
    final puvType = driver?['puv_type'] ?? metadata?['puv_type'] ?? 'traditional';
    final routeCode = route?['code'] ?? metadata?['route_code'] ?? 'N/A';

    final distanceKm = (widget.distanceMeters ?? 0) / 1000;
    
    // Get origin and destination stop names
    String originStop = widget.originStopName ?? 
                        _tripDetails!['origin_stops']?['name'] ?? 
                        metadata?['boarding_location']?['closest_stop_name'] ?? 
                        'Unknown';
    
    String destinationStop = widget.destinationStopName ?? 
                            _tripDetails!['destination_stops']?['name'] ?? 
                            'Unknown';

    // Format timestamps
    final startedAt = _tripDetails!['started_at'] != null 
        ? DateTime.parse(_tripDetails!['started_at'])
        : DateTime.now();
    final endedAt = _tripDetails!['ended_at'] != null 
        ? DateTime.parse(_tripDetails!['ended_at'])
        : DateTime.now();
    
    final dateFormat = '${startedAt.month}/${startedAt.day}/${startedAt.year}';
    final timeFormat = '${startedAt.hour.toString().padLeft(2, '0')}:${startedAt.minute.toString().padLeft(2, '0')}';

    return Column(
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

        // Date and Time
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateFormat,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Time',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeFormat,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 20),

        // Trip details
        _buildDetailRow('Driver', driverName),
        _buildDetailRow('Vehicle', '$vehiclePlate (${puvType.toUpperCase()})'),
        _buildDetailRow('Route', routeCode),
        
        const SizedBox(height: 16),

        // Route visualization
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trip Route',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      originStop,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 5),
                child: Column(
                  children: List.generate(
                    3,
                    (index) => Container(
                      width: 2,
                      height: 8,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      destinationStop,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 20),
        
        // Payment breakdown
        const Text(
          'Payment Summary',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        _buildDetailRow(
          'Distance',
          '${distanceKm.toStringAsFixed(2)} km',
        ),
        _buildDetailRow(
          'Passenger${(_tripDetails!['passengers_count'] ?? 1) > 1 ? 's' : ''}',
          '${_tripDetails!['passengers_count'] ?? 1}',
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: _buildDetailRow(
            'Total Fare',
            '₱${widget.fareAmount?.toStringAsFixed(2) ?? '0.00'}',
            isTotal: true,
          ),
        ),

        const SizedBox(height: 24),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isDownloading ? null : _downloadReceipt,
                icon: _isDownloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.download),
                label: Text(_isDownloading ? 'Saving...' : 'Download'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF8E4CB6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CommuterApp(),
                        ),
                  );
                },
                icon: const Icon(Icons.home),
                label: const Text('Home'),
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
          ],
        ),
        
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? Colors.black : Colors.grey.shade700,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
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
}