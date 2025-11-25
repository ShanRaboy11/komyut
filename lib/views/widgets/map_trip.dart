import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapWidget extends StatefulWidget {
  final MapController mapController;
  final Position? currentPosition;
  final LatLng defaultLocation;
  final bool isLoading;
  final LatLng? boardingLocation;
  final LatLng? arrivalLocation;
  final List<Map<String, dynamic>>? routeStops;
  final String? originStopId;
  final String? destinationStopId;

  const MapWidget({
    super.key,
    required this.mapController,
    required this.currentPosition,
    required this.defaultLocation,
    required this.isLoading,
    this.boardingLocation,
    this.arrivalLocation,
    this.routeStops,
    this.originStopId,
    this.destinationStopId,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  // Brand Colors
  final Color _startColor = const Color(0xFF5B53C2); // Secondary Purple
  final Color _endColor = const Color(0xFF8E4CB6); // Primary Purple
  final Color _intermediateColor = const Color(0xFF9C6BFF);

  // Get only the stops the user traveled through
  List<Map<String, dynamic>> _getTraveledStops() {
    if (widget.routeStops == null ||
        widget.routeStops!.isEmpty ||
        widget.originStopId == null ||
        widget.destinationStopId == null) {
      return [];
    }

    final originIndex = widget.routeStops!.indexWhere(
      (stop) => stop['id'] == widget.originStopId,
    );
    final destIndex = widget.routeStops!.indexWhere(
      (stop) => stop['id'] == widget.destinationStopId,
    );

    if (originIndex == -1 || destIndex == -1) {
      return [];
    }

    if (originIndex <= destIndex) {
      return widget.routeStops!.sublist(originIndex, destIndex + 1);
    } else {
      return widget.routeStops!
          .sublist(destIndex, originIndex + 1)
          .reversed
          .toList();
    }
  }

  // Styled Pin Builder (Label + Circle Head)
  Marker _createPin({
    required LatLng point,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Marker(
      point: point,
      width: 140, // Wide enough for location names
      height: 90,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          // Pin Head (Circle with Icon)
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  // Simple dot for intermediate stops
  Marker _createIntermediateDot({
    required LatLng point,
    required int sequence,
  }) {
    return Marker(
      point: point,
      width: 24,
      height: 24,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: _intermediateColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            "$sequence",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _intermediateColor,
            ),
          ),
        ),
      ),
    );
  }

  List<Marker> _buildMarkers() {
    List<Marker> markers = [];

    // 1. Current User Location (Blue Dot)
    if (widget.currentPosition != null) {
      markers.add(
        Marker(
          point: LatLng(
            widget.currentPosition!.latitude,
            widget.currentPosition!.longitude,
          ),
          width: 50,
          height: 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Route Stops
    final traveledStops = _getTraveledStops();

    for (int i = 0; i < traveledStops.length; i++) {
      final stop = traveledStops[i];
      final stopId = stop['id'];
      final isOrigin = stopId == widget.originStopId;
      final isDestination = stopId == widget.destinationStopId;
      final latLng = LatLng(stop['latitude'], stop['longitude']);
      final locationName = stop['name'] ?? 'Stop';

      if (isOrigin) {
        // Origin: Target Icon
        markers.add(
          _createPin(
            point: latLng,
            label: locationName,
            color: _startColor,
            icon: Icons.trip_origin_rounded,
          ),
        );
      } else if (isDestination) {
        // Destination: Pin Icon (As requested)
        markers.add(
          _createPin(
            point: latLng,
            label: locationName,
            color: _endColor,
            icon: Icons.location_on_rounded,
          ),
        );
      } else {
        // Intermediate: Small Dots
        markers.add(_createIntermediateDot(point: latLng, sequence: i + 1));
      }
    }

    // 3. Actual Boarding/Arrival Locations (Styled pins)
    if (widget.boardingLocation != null) {
      markers.add(
        _createPin(
          point: widget.boardingLocation!,
          label: "Boarded",
          color: Colors.orange,
          icon: Icons.hail_rounded,
        ),
      );
    }

    if (widget.arrivalLocation != null) {
      markers.add(
        _createPin(
          point: widget.arrivalLocation!,
          label: "Dropped",
          color: Colors.green,
          icon: Icons.emoji_people_rounded,
        ),
      );
    }

    return markers;
  }

  List<Polyline> _buildPolylines() {
    final traveledStops = _getTraveledStops();

    if (traveledStops.length > 1) {
      final traveledPoints = traveledStops
          .map((stop) => LatLng(stop['latitude'], stop['longitude']))
          .toList();

      return [
        Polyline(
          points: traveledPoints,
          color: _endColor,
          strokeWidth: 5.0,
          borderColor: Colors.white.withValues(alpha: 0.7),
          borderStrokeWidth: 2.0,
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      ];
    }
    return [];
  }

  LatLngBounds? _getBounds() {
    List<LatLng> allPoints = [];

    final traveledStops = _getTraveledStops();
    for (var stop in traveledStops) {
      allPoints.add(LatLng(stop['latitude'], stop['longitude']));
    }

    if (widget.boardingLocation != null)
      allPoints.add(widget.boardingLocation!);
    if (widget.arrivalLocation != null) allPoints.add(widget.arrivalLocation!);
    if (widget.currentPosition != null) {
      allPoints.add(
        LatLng(
          widget.currentPosition!.latitude,
          widget.currentPosition!.longitude,
        ),
      );
    }

    if (allPoints.isEmpty) return null;

    return LatLngBounds.fromPoints(allPoints);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bounds = _getBounds();
      if (bounds != null && mounted) {
        widget.mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 70),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Container(
        color: Colors.grey[100],
        child: Center(child: CircularProgressIndicator(color: _endColor)),
      );
    }

    final traveledStops = _getTraveledStops();
    final initialCenter = traveledStops.isNotEmpty
        ? LatLng(
            traveledStops.first['latitude'],
            traveledStops.first['longitude'],
          )
        : (widget.currentPosition != null
              ? LatLng(
                  widget.currentPosition!.latitude,
                  widget.currentPosition!.longitude,
                )
              : widget.boardingLocation ?? widget.defaultLocation);

    return FlutterMap(
      mapController: widget.mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 15.0,
        minZoom: 5.0,
        maxZoom: 18.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.komyut.app',
          maxZoom: 19,
          retinaMode: RetinaMode.isHighDensity(context),
        ),
        PolylineLayer(polylines: _buildPolylines()),
        MarkerLayer(markers: _buildMarkers()),
        RichAttributionWidget(
          showFlutterMapAttribution: true,
          attributions: [
            TextSourceAttribution(
              'OpenStreetMap contributors',
              onTap: () {},
              textStyle: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
            TextSourceAttribution(
              'CARTO',
              onTap: () {},
              textStyle: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }
}
