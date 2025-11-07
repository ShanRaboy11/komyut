import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:gal/gal.dart';
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
  bool _isLoading = true;
  String? _transactionNumber;
  Map<String, dynamic>? _tripDetails;
  bool _isDownloading = false;
  final GlobalKey _receiptKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    if (widget.tripId != null) {
      debugPrint('Trip ID: ${widget.tripId}');
      debugPrint('Fare: ${widget.fareAmount}');
      debugPrint('Distance: ${widget.distanceMeters}m');
      _loadTripDetails();
    }
  }

  Future<void> _loadTripDetails() async {
    try {
      final supabase = Supabase.instance.client;
      
      debugPrint('🔍 === FETCHING TRIP DETAILS ===');
      
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
              profile_id
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

      debugPrint('✅ Trip response received');
      debugPrint('👤 Driver data: ${tripResponse['drivers']}');

      // Get driver's profile separately using the profile_id
      Map<String, dynamic>? driverProfile;
      if (tripResponse['drivers'] != null) {
        final driverData = tripResponse['drivers'] as Map<String, dynamic>;
        final driverProfileId = driverData['profile_id'] as String?;
        
        debugPrint('🔍 Extracted profile_id: $driverProfileId');
        
        if (driverProfileId != null && driverProfileId.isNotEmpty) {
          try {
            debugPrint('🔍 Attempting to fetch profile for ID: $driverProfileId');
            
            driverProfile = await supabase
                .from('profiles')
                .select('first_name, last_name')
                .eq('id', driverProfileId)
                .maybeSingle();
            
            if (driverProfile != null) {
              debugPrint('✅ Profile fetched successfully: $driverProfile');
              // Add profile data to driver object
              tripResponse['drivers']['profiles'] = driverProfile;
            } else {
              debugPrint('⚠️ Profile query returned null');
              debugPrint('⚠️ Checking if profile exists in database...');
              
              // Try to get ANY profile to see if table is accessible
              final testQuery = await supabase
                  .from('profiles')
                  .select('id, first_name, last_name')
                  .eq('id', driverProfileId)
                  .maybeSingle();
              
              debugPrint('🔍 Test query result: $testQuery');
            }
          } catch (e, stackTrace) {
            debugPrint('❌ Error fetching driver profile: $e');
            debugPrint('❌ Stack trace: $stackTrace');
            debugPrint('⚠️ Will use metadata fallback');
          }
        } else {
          debugPrint('⚠️ profile_id is null or empty');
        }
      } else {
        debugPrint('⚠️ No driver data in trip response');
      }

      // Get transaction number
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
      debugPrint('👤 Trip metadata: ${tripResponse['metadata']}');
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading trip details: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getDriverName() {
    if (_tripDetails == null) {
      debugPrint('⚠️ _tripDetails is null');
      return 'Unknown Driver';
    }

    debugPrint('🔍 === GETTING DRIVER NAME ===');
    
    // Try to get from metadata first (most reliable as it's stored during trip creation)
    final metadata = _tripDetails!['metadata'] as Map<String, dynamic>?;
    debugPrint('📋 Metadata: $metadata');
    
    // Check for driver_name in metadata (stored during trip creation)
    if (metadata != null && metadata.containsKey('driver_name')) {
      final driverName = metadata['driver_name'] as String?;
      debugPrint('🔍 Found driver_name in metadata: "$driverName"');
      if (driverName != null && driverName.isNotEmpty && driverName != 'Driver') {
        debugPrint('✅ Using driver name from metadata: $driverName');
        return driverName;
      }
    }

    // Try to construct from metadata first/last name
    if (metadata != null) {
      final firstName = metadata['driver_first_name'] as String? ?? '';
      final lastName = metadata['driver_last_name'] as String? ?? '';
      debugPrint('🔍 Metadata first_name: "$firstName", last_name: "$lastName"');
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        final name = '$firstName $lastName'.trim();
        debugPrint('✅ Constructed driver name from metadata: $name');
        return name;
      }
    }

    // Try to get from driver's profile (from database join)
    final driver = _tripDetails!['drivers'];
    debugPrint('🔍 Driver object: $driver');
    if (driver != null) {
      final profiles = driver['profiles'];
      debugPrint('🔍 Profiles object: $profiles');
      if (profiles != null) {
        final firstName = profiles['first_name'] as String? ?? '';
        final lastName = profiles['last_name'] as String? ?? '';
        debugPrint('🔍 Profile first_name: "$firstName", last_name: "$lastName"');
        if (firstName.isNotEmpty || lastName.isNotEmpty) {
          final name = '$firstName $lastName'.trim();
          debugPrint('✅ Got driver name from profiles: $name');
          return name;
        }
      }
    }

    debugPrint('⚠️ Could not find driver name anywhere, using fallback');
    return 'Driver';
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
      appBar: AppBar(
        title: const Text('Trip Receipt'),
        backgroundColor: const Color(0xFF8E4CB6),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Receipt content wrapped with RepaintBoundary for screenshot
            RepaintBoundary(
              key: _receiptKey,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(24),
                child: _buildReceiptContent(),
              ),
            ),
            
            // Action buttons (NOT included in screenshot)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
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
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CommuterApp(),
                          ),
                          (route) => false,
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
            ),
          ],
        ),
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
    
    final dateFormat = '${startedAt.month}/${startedAt.day}/${startedAt.year}';
    final timeFormat = '${startedAt.hour.toString().padLeft(2, '0')}:${startedAt.minute.toString().padLeft(2, '0')}';

    // Check if discount was applied
    final discountApplied = metadata?['discount_applied'] == true;
    final discountRate = (metadata?['discount_rate'] as num?)?.toDouble() ?? 0.0;
    final originalFare = metadata?['original_fare'] as num?;

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
        
        // Show discount information if applicable
        if (discountApplied && originalFare != null) ...[
          const SizedBox(height: 8),
          _buildDetailRow(
            'Original Fare',
            '₱${originalFare.toStringAsFixed(2)}',
          ),
          _buildDetailRow(
            'Discount (${(discountRate * 100).toStringAsFixed(0)}%)',
            '-₱${(originalFare - (widget.fareAmount ?? 0)).toStringAsFixed(2)}',
            valueColor: Colors.green,
          ),
        ],
        
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
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false, Color? valueColor}) {
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
              color: valueColor ?? (isTotal ? const Color(0xFF8E4CB6) : Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}