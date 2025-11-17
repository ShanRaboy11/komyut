import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import '../widgets/drivercard_trip.dart';
import '../widgets/tripdetails_card.dart';
import '../widgets/map_trip.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/button.dart';
import 'report_p1_driver.dart';
import '../services/driver_trip.dart';
import '../models/driver_trip.dart';

class DriverTripDetailsPage extends StatefulWidget {
  final String tripId;
  final String date;
  final String time;
  final String from;
  final String to;
  final String tripCode;
  final String status;

  const DriverTripDetailsPage({
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
  State<DriverTripDetailsPage> createState() => _DriverTripDetailsPageState();
}

class _DriverTripDetailsPageState extends State<DriverTripDetailsPage> with SingleTickerProviderStateMixin {
  final DriverTripService _service = DriverTripService();
  DriverTrip? _details;
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
      final d = await _service.getTripById(widget.tripId);
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final defaultLocation = LatLng(14.5995, 120.9842); // Manila fallback

    final hasRouteData = _details != null &&
        _details!.distanceMeters != null &&
        _details!.distanceMeters! > 0;

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

              Text(
                "Trip Details",
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),

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

              if (_loading)
                _buildLoadingDriverCard()
              else if (_details != null)
                DriverCard(
                  name: _details!.originName, // show route owner or placeholder
                  role: 'Driver',
                  plate: _details!.routeCode,
                )
              else
                DriverCard(
                  name: 'Driver',
                  role: 'Driver',
                  plate: '-',
                ),

              const SizedBox(height: 16),

              if (_loading)
                _buildLoadingMap()
              else if (hasRouteData) ...[
                SizedBox(
                  height: 260,
                  child: MapWidget(
                    mapController: _mapController,
                    currentPosition: null,
                    defaultLocation: defaultLocation,
                    isLoading: false,
                    boardingLocation: null,
                    arrivalLocation: null,
                    routeStops: null,
                    originStopId: null,
                    destinationStopId: null,
                  ),
                ),
                const SizedBox(height: 12),
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
                              _details != null ? '${(_details!.distanceMeters ?? 0)/1000.0} km' : '—',
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
                              _details != null && _details!.routeCode.isNotEmpty ? _details!.routeCode : widget.tripCode,
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
                TripDetailsCard(
                  mapImage: 'assets/images/map.png',
                  distance: _details != null ? '${(_details!.distanceMeters ?? 0)/1000.0} kilometers' : '—',
                  routeCode: _details != null && _details!.routeCode.isNotEmpty ? _details!.routeCode : widget.tripCode,
                  from: _details != null && _details!.originName.isNotEmpty ? _details!.originName : widget.from,
                  fromTime: _details?.startedAt.toIso8601String() ?? widget.time,
                  to: _details != null && _details!.destinationName.isNotEmpty ? _details!.destinationName : widget.to,
                  toTime: _details?.startedAt.toIso8601String() ?? widget.time,
                ),

              const SizedBox(height: 20),

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

              if (_loading)
                _buildLoadingButtons(screenWidth)
              else if (widget.status.toLowerCase() == "cancelled") ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: "View Summary",
                        onPressed: () {},
                        icon: Symbols.info_rounded,
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
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Receipt not available')));
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
                  text: "Trip Summary",
                  onPressed: () {},
                  icon: Symbols.receipt_long_rounded,
                  width: double.infinity,
                  height: 50,
                  textColor: Colors.white,
                  isFilled: true,
                ),
                const SizedBox(height: 12),
                CustomButton(
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

  Widget _buildLoadingDriverCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 16, width: 120, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Container(height: 12, width: 80, color: Colors.grey[200]),
        ],
      ),
    );
  }

  Widget _buildLoadingMap() {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildLoadingButtons(double screenWidth) {
    return Column(
      children: [
        Container(height: 50, width: double.infinity, color: Colors.grey[200]),
        const SizedBox(height: 12),
        Container(height: 50, width: double.infinity, color: Colors.grey[200]),
      ],
    );
  }
}
