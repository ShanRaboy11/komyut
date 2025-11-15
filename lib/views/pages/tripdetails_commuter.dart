import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import '../widgets/drivercard_trip.dart';
import '../widgets/tripdetails_card.dart';
import '../widgets/map.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
// geolocator Position not required here; MapWidget accepts null currentPosition
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

class _TripDetailsPageState extends State<TripDetailsPage> {
  final TripsService _service = TripsService();
  TripDetails? _details;
  bool _loading = false;
  String? _error;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadDetails();
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

    // We'll render a dynamic map using the app's MapWidget when routeStops exist.
    final defaultLocation = LatLng(14.5995, 120.9842); // Manila fallback

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
                      onPressed: () {
                        Navigator.pop(context);
                      },
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

              // Date and Status (flexible to avoid overflow)
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

              // Driver Card (show fetched driver when available)
              _loading
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF8E4CB6), width: 1.2),
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
                          Container(height: 50, width: 50, decoration: const BoxDecoration(color: Color(0xFFF2EAFF), shape: BoxShape.circle)),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(width: 140, height: 16, color: Colors.grey[300]),
                                const SizedBox(height: 8),
                                Container(width: 100, height: 14, color: Colors.grey[300]),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : DriverCard(
                      name: _details?.driverName ?? 'Unknown Driver',
                      role: 'Driver',
                      plate: _details?.vehiclePlate ?? '-',
                    ),

              const SizedBox(height: 16),

              // Dynamic Map (when routeStops exist) — show distance underneath
              if (_details != null && _details!.routeStops != null && _details!.routeStops!.isNotEmpty) ...[
                SizedBox(
                  height: 260,
                  child: MapWidget(
                    mapController: _mapController,
                    currentPosition: null,
                    defaultLocation: defaultLocation,
                    isLoading: _loading,
                    boardingLocation: null,
                    arrivalLocation: null,
                    routeStops: _details!.routeStops,
                    originStopId: _details!.originStopId,
                    destinationStopId: _details!.destinationStopId,
                  ),
                ),
                const SizedBox(height: 12),
                // Distance + Route Code row under the map (flexible)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Distance', style: GoogleFonts.nunito(color: Colors.grey[700])),
                            Text(
                              _details != null ? '${_details!.distanceKm.toStringAsFixed(1)} km' : '—',
                              style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700),
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
                            Text('Route Code', style: GoogleFonts.nunito(color: Colors.grey[700])),
                            Text(
                              (_details != null && _details!.tripCode.isNotEmpty) ? _details!.tripCode : widget.tripCode,
                              style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF9C6BFF)),
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
                // Fallback to static image
                TripDetailsCard(
                  mapImage: 'assets/images/map.png',
                  distance: _details != null ? '${_details!.distanceKm.toStringAsFixed(1)} kilometers' : '—',
                  routeCode: (_details != null && _details!.tripCode.isNotEmpty) ? _details!.tripCode : widget.tripCode,
                  from: (_details != null && _details!.from.isNotEmpty) ? _details!.from : widget.from,
                  fromTime: _details != null ? _details!.time : widget.time,
                  to: (_details != null && _details!.to.isNotEmpty) ? _details!.to : widget.to,
                  toTime: _details != null ? _details!.time : widget.time,
                ),

              const SizedBox(height: 20),

              if (_loading) const Center(child: CircularProgressIndicator()),
              if (_error != null) Center(child: Text(_error!)),

              // Buttons (same behavior as before)
              if (widget.status.toLowerCase() == "cancelled") ...[
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
