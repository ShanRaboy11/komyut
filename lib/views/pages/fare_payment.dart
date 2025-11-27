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
import 'package:komyut/main.dart';
import 'commuter_app.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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
                child: _isLoading ? _buildSkeletonLoading() : _buildReceiptContent(),
              ),
            ),
            
            // Action buttons (NOT included in screenshot)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isDownloading || _isLoading ? null : _downloadReceipt,
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
                        // Prefer navigating via the CommuterApp nested navigator
                        // (matches other receipt pages). If it's not available
                        // fall back to AuthStateHandler to re-evaluate role.
                        if (CommuterApp.navigatorKey.currentState != null) {
                          CommuterApp.navigatorKey.currentState
                              ?.pushNamedAndRemoveUntil('/', (route) => false);
                        } else {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AuthStateHandler(),
                            ),
                            (route) => false,
                          );
                        }
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

  Widget _buildSkeletonLoading() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8E4CB6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route skeleton
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  _buildSkeletonBox(46, 46, radius: 12),
                  Container(
                    height: 35,
                    width: 2,
                    color: Colors.grey.withAlpha((0.2 * 255).round()),
                  ),
                  _buildSkeletonBox(46, 46, radius: 12),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSkeletonBox(120, 16),
                    const SizedBox(height: 4),
                    _buildSkeletonBox(80, 12),
                    const SizedBox(height: 43),
                    _buildSkeletonBox(120, 16),
                    const SizedBox(height: 4),
                    _buildSkeletonBox(80, 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(height: 4, thickness: 1, color: Colors.grey.withAlpha((0.2 * 255).round())),
          const SizedBox(height: 16),

          // Fare details skeleton
          _buildSkeletonRow(),
          _buildSkeletonRow(),
          _buildSkeletonRow(),
          const SizedBox(height: 8),
          Divider(thickness: 1, color: Colors.grey.withAlpha((0.2 * 255).round())),
          const SizedBox(height: 8),
          _buildSkeletonRow(),
          _buildSkeletonRow(),
          const SizedBox(height: 12),
          Divider(thickness: 1, color: Colors.grey.withAlpha((0.2 * 255).round())),
          const SizedBox(height: 8),
          _buildSkeletonRow(),
          const SizedBox(height: 20),

          // Barcode skeleton
          Center(
            child: Column(
              children: [
                _buildSkeletonBox(200, 60, radius: 8),
                const SizedBox(height: 8),
                _buildSkeletonBox(120, 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonBox(double width, double height, {double radius = 4}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha((0.2 * 255).round()),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildSkeletonRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSkeletonBox(100, 14),
          _buildSkeletonBox(60, 14),
        ],
      ),
    );
  }

  Widget _buildReceiptContent() {
    if (_tripDetails == null) {
      return Center(
        child: Text(
          'No trip details available',
          style: GoogleFonts.nunito(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      );
    }

    // driver and route details are available on _tripDetails if needed
    final metadata = _tripDetails!['metadata'] as Map<String, dynamic>?;
    
    final driverName = _getDriverName();
    
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
    
    final completedAt = _tripDetails!['completed_at'] != null 
        ? DateTime.parse(_tripDetails!['completed_at'])
        : DateTime.now();

    final dateFormat = DateFormat('MMMM d, yyyy').format(startedAt);
    final fromTime = DateFormat('h:mm a').format(startedAt);
    final toTime = DateFormat('h:mm a').format(completedAt);
    final timeFormat = DateFormat('h:mm a').format(startedAt);

    // Check if discount was applied
    final discountApplied = metadata?['discount_applied'] == true;
    // discountRate extracted from metadata if needed
    final originalFare = (metadata?['original_fare'] as num?)?.toDouble() ?? widget.fareAmount ?? 0.0;
    final discountAmount = discountApplied ? (originalFare - (widget.fareAmount ?? 0)) : 0.0;
    
    final passengers = _tripDetails!['passengers_count'] ?? 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8E4CB6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🗺️ Route
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon column with fixed width
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFCCF8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.map_outlined,
                      color: Color(0xFFB945AA),
                      size: 30,
                    ),
                  ),
                  Container(
                    height: 35,
                    width: 2,
                    color: const Color(0xFFB945AA).withAlpha((0.4 * 255).round()),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9C5FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Color(0xFF8E4CB6),
                      size: 30,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Text column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Boarding location
                    _buildLocationRow(originStop, fromTime),
                    const SizedBox(height: 43),
                    // Departure location
                    _buildLocationRow(destinationStop, toTime),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 28, thickness: 1),

          // 🧾 Fare details
          _buildFareRow("Driver", driverName, isBoldRight: true),
          _buildFareRow("Date", "$dateFormat   $timeFormat", isBoldRight: true),
          _buildFareRow("No. of Passenger/s", passengers.toString()),
          const SizedBox(height: 8),
          const Divider(thickness: 1),
          const SizedBox(height: 8),
          _buildFareRow("Base Fare", "₱${originalFare.toStringAsFixed(2)}"),
          _buildFareRow(
            "Discount (if applicable)",
            "₱${discountAmount.toStringAsFixed(2)}",
          ),
          const SizedBox(height: 12),
          const Divider(thickness: 1),
          const SizedBox(height: 8),
          _buildFareRow(
            "Total Fare",
            "₱${(widget.fareAmount ?? 0.0).toStringAsFixed(2)}",
            isBoldRight: true,
            isBoldLeft: true,
          ),

          const SizedBox(height: 20),

          // 🧍 Barcode Section
          Center(
            child: Column(
              children: [
                Builder(
                  builder: (context) {
                    final tx = (_transactionNumber ?? '').trim();
                    return tx.isNotEmpty
                        ? Column(
                            children: [
                              BarcodeWidget(
                                barcode: Barcode.code128(),
                                data: tx,
                                height: 60,
                                width: 200,
                                drawText: false,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                tx,
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Colors.black.withAlpha((0.7 * 255).round()),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              Container(
                                height: 60,
                                width: 200,
                                decoration: BoxDecoration(
                                  color: Colors.grey.withAlpha((0.1 * 255).round()),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.withAlpha((0.3 * 255).round()),
                                    style: BorderStyle.solid,
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.qr_code_2,
                                    size: 40,
                                    color: Colors.grey.withAlpha((0.4 * 255).round()),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No Transaction Number',
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                  color: Colors.grey.withAlpha((0.6 * 255).round()),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(String title, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Colors.grey.withAlpha((0.6 * 255).round()),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: GoogleFonts.nunito(
              fontSize: 12,
              color: Colors.black.withAlpha((0.6 * 255).round()),
            ),
        ),
      ],
    );
  }

  Widget _buildFareRow(
    String label,
    String value, {
    bool isBoldRight = false,
    bool isBoldLeft = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontWeight: isBoldLeft ? FontWeight.w800 : FontWeight.w600,
                fontSize: isBoldLeft ? 16 : 14,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontWeight: isBoldRight ? FontWeight.w800 : FontWeight.w600,
              fontSize: 13,
              color: Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}