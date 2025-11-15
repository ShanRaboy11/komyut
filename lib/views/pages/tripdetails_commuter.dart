import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import '../widgets/drivercard_trip.dart';
import '../widgets/tripdetails_card.dart';
import '../widgets/map_trip.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/button.dart';
import '../pages/tripreceipt_commuter.dart';
import 'report_p1_commuter.dart';
import '../services/trips.dart';
import '../models/trips.dart';

class TripDetailsPage extends StatefulWidget {
  final String tripId;
  final String date;
  final String time;
  final String from;
  final String to;
  final String tripCode;
  final String status;

  const TripDetailsPage({
    super.key,
    required this.tripId,
    required this.date,
    required this.time,
    required this.from,
    required this.to,
    required this.tripCode,
    required this.status,
  });

  @override
  State<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> with SingleTickerProviderStateMixin {
  final TripsService _service = TripsService();
  TripDetails? _details;
  bool _loading = false;
  String? _error;
  final MapController _mapController = MapController();
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _loadDetails();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final d = await _service.getTripDetails(widget.tripId);
      if (mounted) {
        setState(() {
          _details = d;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load trip details: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final defaultLocation = LatLng(14.5995, 120.9842); // Manila fallback

    // Determine if we have route data to show dynamic map
    final hasRouteData = _details != null && 
                         _details!.routeStops != null && 
                         _details!.routeStops!.isNotEmpty &&
                         _details!.originStopId != null &&
                         _details!.destinationStopId != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 30,
            right: 30,
            bottom: 30,
            top: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    "Trips",
                    style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Title
              Text(
                "Trip Details",
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),

              // Date and Status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "${widget.date}, ${widget.time}",
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: const Color.fromRGBO(0, 0, 0, 0.7),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusBackground(widget.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.status[0].toUpperCase() + widget.status.substring(1),
                      style: GoogleFonts.nunito(
                        color: _statusColor(widget.status),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Driver Card
              if (_loading)
                _buildLoadingDriverCard()
              else if (_details != null)
                DriverCard(
                  name: _details!.driverName ?? 'Unknown Driver',
                  role: 'Driver',
                  plate: _details!.vehiclePlate ?? '-',
                )
              else
                DriverCard(
                  name: 'Unknown Driver',
                  role: 'Driver',
                  plate: 'N/A',
                ),

              const SizedBox(height: 16),

              // Dynamic Map or Fallback
              if (_loading)
                _buildLoadingMap()
              else if (hasRouteData) ...[
                // Dynamic map with route visualization
                SizedBox(
                  height: 260,
                  child: MapWidget(
                    mapController: _mapController,
                    currentPosition: null,
                    defaultLocation: defaultLocation,
                    isLoading: false,
                    boardingLocation: null,
                    arrivalLocation: null,
                    routeStops: _details!.routeStops,
                    originStopId: _details!.originStopId,
                    destinationStopId: _details!.destinationStopId,
                  ),
                ),
                const SizedBox(height: 12),
                // Distance + Route Code row under the map
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Distance',
                              style: GoogleFonts.nunito(
                                color: Colors.grey[700],
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_details!.distanceKm.toStringAsFixed(1)} km',
                              style: GoogleFonts.manrope(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Route Code',
                              style: GoogleFonts.nunito(
                                color: Colors.grey[700],
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _details!.tripCode.isNotEmpty 
                                  ? _details!.tripCode 
                                  : widget.tripCode,
                              style: GoogleFonts.manrope(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF9C6BFF),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ] else
                // Fallback to static card
                TripDetailsCard(
                  mapImage: 'assets/images/map.png',
                  distance: _details != null 
                      ? '${_details!.distanceKm.toStringAsFixed(1)} kilometers' 
                      : '—',
                  routeCode: _details != null && _details!.tripCode.isNotEmpty
                      ? _details!.tripCode 
                      : widget.tripCode,
                  from: _details != null && _details!.from.isNotEmpty
                      ? _details!.from 
                      : widget.from,
                  fromTime: _details?.time ?? widget.time,
                  to: _details != null && _details!.to.isNotEmpty
                      ? _details!.to 
                      : widget.to,
                  toTime: _details?.time ?? widget.time,
                ),

              const SizedBox(height: 20),

              // Error message
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: GoogleFonts.nunito(
                            color: Colors.red.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Action Buttons
              if (_loading)
                _buildLoadingButtons(screenWidth)
              else if (widget.status.toLowerCase() == "cancelled") ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: "Rate",
                        onPressed: () {},
                        icon: Symbols.star_rounded,
                        width: (screenWidth - 70) / 2,
                        height: 50,
                        textColor: Colors.white,
                        isFilled: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: "Report",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ReportPage(),
                            ),
                          );
                        },
                        icon: Symbols.brightness_alert_rounded,
                        width: (screenWidth - 70) / 2,
                        height: 50,
                        textColor: Colors.white,
                        isFilled: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: "View Receipt",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TripReceiptPage(),
                      ),
                    );
                  },
                  icon: Symbols.receipt_long_rounded,
                  iconColor: const Color(0xFF5B53C2),
                  width: double.infinity,
                  height: 50,
                  isFilled: false,
                  outlinedFillColor: Colors.white,
                  textColor: const Color(0xFF5B53C2),
                  hasShadow: false,
                ),
              ] else if (widget.status.toLowerCase() == "completed") ...[
                CustomButton(
                  text: "Rate Your Trip",
                  onPressed: () {},
                  icon: Symbols.star_rounded,
                  width: double.infinity,
                  height: 50,
                  textColor: Colors.white,
                  isFilled: true,
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: "View Receipt",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TripReceiptPage(),
                      ),
                    );
                  },
                  icon: Symbols.receipt_long_rounded,
                  iconColor: const Color(0xFF5B53C2),
                  width: double.infinity,
                  height: 50,
                  isFilled: false,
                  outlinedFillColor: Colors.white,
                  textColor: const Color(0xFF5B53C2),
                  hasShadow: false,
                ),
              ] else ...[
                CustomButton(
                  text: "Report an Issue",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReportPage(),
                      ),
                    );
                  },
                  icon: Symbols.brightness_alert_rounded,
                  width: double.infinity,
                  height: 50,
                  textColor: Colors.white,
                  isFilled: true,
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: "View Receipt",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TripReceiptPage(),
                      ),
                    );
                  },
                  icon: Symbols.receipt_long_rounded,
                  iconColor: const Color(0xFF5B53C2),
                  width: double.infinity,
                  height: 50,
                  isFilled: false,
                  outlinedFillColor: Colors.white,
                  textColor: const Color(0xFF5B53C2),
                  hasShadow: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Enhanced shimmer effect
  Widget _buildShimmer({required Widget child}) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, shimmerChild) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
              stops: [
                _shimmerController.value - 0.3,
                _shimmerController.value,
                _shimmerController.value + 0.3,
              ],
            ).createShader(bounds);
          },
          child: shimmerChild,
        );
      },
      child: child,
    );
  }

  // Enhanced loading state for driver card
  Widget _buildLoadingDriverCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF8E4CB6).withValues(alpha: 0.3), width: 1.2),
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 4,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildShimmer(
            child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmer(
                  child: Container(
                    width: 140,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildShimmer(
                  child: Container(
                    width: 100,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced loading state for map with animated elements
  Widget _buildLoadingMap() {
    return Column(
      children: [
        Container(
          height: 260,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Stack(
            children: [
              // Base map background
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.grey[100]!,
                      Colors.grey[200]!,
                      Colors.grey[100]!,
                    ],
                  ),
                ),
              ),
              // Animated road lines
              Positioned(
                left: 40,
                top: 60,
                child: _buildShimmer(
                  child: Container(
                    width: 120,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 50,
                top: 100,
                child: _buildShimmer(
                  child: Container(
                    width: 80,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 60,
                bottom: 80,
                child: _buildShimmer(
                  child: Container(
                    width: 100,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              // Pin markers
              Positioned(
                left: 40,
                top: 40,
                child: _buildShimmer(
                  child: Icon(
                    Icons.location_on,
                    size: 32,
                    color: Colors.grey[400],
                  ),
                ),
              ),
              Positioned(
                right: 40,
                bottom: 60,
                child: _buildShimmer(
                  child: Icon(
                    Icons.location_on,
                    size: 32,
                    color: Colors.grey[400],
                  ),
                ),
              ),
              // Center loading indicator
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFF8E4CB6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Loading map...',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Distance and Route Code skeleton
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmer(
                      child: Container(
                        width: 60,
                        height: 13,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildShimmer(
                      child: Container(
                        width: 80,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildShimmer(
                      child: Container(
                        width: 80,
                        height: 13,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildShimmer(
                      child: Container(
                        width: 60,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Loading state for action buttons
  Widget _buildLoadingButtons(double screenWidth) {
    return Column(
      children: [
        _buildShimmer(
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildShimmer(
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Color _statusBackground(String status) {
    switch (status.toLowerCase()) {
      case "ongoing":
        return const Color(0xFFFFF5CC);
      case "completed":
        return const Color(0xFFE9F8E8);
      case "cancelled":
        return const Color(0xFFFFE5E5);
      default:
        return Colors.grey.shade200;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "ongoing":
        return const Color(0xFFFFC107);
      case "completed":
        return Colors.green;
      case "cancelled":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}