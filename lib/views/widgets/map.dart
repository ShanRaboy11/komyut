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
  List<Marker> _buildMarkers() {
    List<Marker> markers = [];

    // Add current location marker if available
    if (widget.currentPosition != null) {
      markers.add(
        Marker(
          point: LatLng(
            widget.currentPosition!.latitude,
            widget.currentPosition!.longitude,
          ),
          width: 40,
          height: 40,
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF8E4CB6),
                Color(0xFFB945AA),
              ],
            ).createShader(bounds),
            child: const Icon(
              Icons.my_location,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
      );
    }

    // Add route stops as markers
    if (widget.routeStops != null && widget.routeStops!.isNotEmpty) {
      for (int i = 0; i < widget.routeStops!.length; i++) {
        final stop = widget.routeStops![i];
        final stopId = stop['id'];
        final isOrigin = stopId == widget.originStopId;
        final isDestination = stopId == widget.destinationStopId;
        final sequence = stop['sequence'] as int;

        // Determine marker color and size
        Color markerColor;
        double markerSize;
        IconData markerIcon;

        if (isOrigin) {
          markerColor = Colors.green;
          markerSize = 45;
          markerIcon = Icons.location_on;
        } else if (isDestination) {
          markerColor = Colors.red;
          markerSize = 45;
          markerIcon = Icons.location_on;
        } else {
          markerColor = const Color(0xFF8E4CB6);
          markerSize = 32;
          markerIcon = Icons.location_on_outlined;
        }

        markers.add(
          Marker(
            point: LatLng(stop['latitude'], stop['longitude']),
            width: markerSize + 20,
            height: markerSize + 40,
            child: Column(
              children: [
                // Stop label (only for origin and destination)
                if (isOrigin || isDestination)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: markerColor,
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
                // Marker icon with sequence number
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      markerIcon,
                      color: markerColor,
                      size: markerSize,
                    ),
                    if (!isOrigin && !isDestination)
                      Positioned(
                        top: 6,
                        child: Text(
                          '$sequence',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
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
    }

    // Add boarding location marker (user's actual boarding position)
    if (widget.boardingLocation != null) {
      markers.add(
        Marker(
          point: widget.boardingLocation!,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(
              Icons.person_pin,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      );
    }

    // Add arrival location marker (user's actual arrival position)
    if (widget.arrivalLocation != null) {
      markers.add(
        Marker(
          point: widget.arrivalLocation!,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(
              Icons.person_pin,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      );
    }

    return markers;
  }

  List<Polyline> _buildPolylines() {
    List<Polyline> polylines = [];

    // Draw polyline through all route stops
    if (widget.routeStops != null && widget.routeStops!.length > 1) {
      // Full route polyline (gray, dashed)
      final allStopPoints = widget.routeStops!
          .map((stop) => LatLng(stop['latitude'], stop['longitude']))
          .toList();

      polylines.add(
        Polyline(
          points: allStopPoints,
          color: Colors.grey.shade400,
          strokeWidth: 3.0,
          isDotted: true,
        ),
      );

      // Highlight the traveled segment (origin to destination)
      if (widget.originStopId != null && widget.destinationStopId != null) {
        final originIndex = widget.routeStops!
            .indexWhere((stop) => stop['id'] == widget.originStopId);
        final destIndex = widget.routeStops!
            .indexWhere((stop) => stop['id'] == widget.destinationStopId);

        if (originIndex != -1 && destIndex != -1 && originIndex != destIndex) {
          List<LatLng> traveledPoints;
          
          if (originIndex < destIndex) {
            // Forward travel
            traveledPoints = widget.routeStops!
                .sublist(originIndex, destIndex + 1)
                .map((stop) => LatLng(stop['latitude'], stop['longitude']))
                .toList();
          } else {
            // Backward travel (return trip)
            traveledPoints = widget.routeStops!
                .sublist(destIndex, originIndex + 1)
                .reversed
                .map((stop) => LatLng(stop['latitude'], stop['longitude']))
                .toList();
          }

          polylines.add(
            Polyline(
              points: traveledPoints,
              color: const Color(0xFF8E4CB6),
              strokeWidth: 5.0,
              borderColor: Colors.white,
              borderStrokeWidth: 2.0,
            ),
          );
        }
      }
    }

    return polylines;
  }

  LatLngBounds? _getBounds() {
    List<LatLng> allPoints = [];

    // Add route stops
    if (widget.routeStops != null) {
      for (var stop in widget.routeStops!) {
        allPoints.add(LatLng(stop['latitude'], stop['longitude']));
      }
    }

    // Add boarding and arrival locations
    if (widget.boardingLocation != null) {
      allPoints.add(widget.boardingLocation!);
    }
    if (widget.arrivalLocation != null) {
      allPoints.add(widget.arrivalLocation!);
    }

    if (allPoints.isEmpty) return null;

    double minLat = allPoints.first.latitude;
    double maxLat = allPoints.first.latitude;
    double minLng = allPoints.first.longitude;
    double maxLng = allPoints.first.longitude;

    for (var point in allPoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    // Add padding
    double latPadding = (maxLat - minLat) * 0.2;
    double lngPadding = (maxLng - minLng) * 0.2;

    return LatLngBounds(
      LatLng(minLat - latPadding, minLng - lngPadding),
      LatLng(maxLat + latPadding, maxLng + lngPadding),
    );
  }

  @override
  void initState() {
    super.initState();
    
    // Fit bounds after map is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bounds = _getBounds();
      if (bounds != null && mounted) {
        widget.mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(50),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final initialCenter = widget.currentPosition != null
        ? LatLng(
            widget.currentPosition!.latitude,
            widget.currentPosition!.longitude,
          )
        : widget.boardingLocation ?? widget.defaultLocation;

    return FlutterMap(
      mapController: widget.mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 15.0,
        minZoom: 5.0,
        maxZoom: 18.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.example.app',
          maxZoom: 19,
          retinaMode: RetinaMode.isHighDensity(context),
        ),
        PolylineLayer(
          polylines: _buildPolylines(),
        ),
        MarkerLayer(
          markers: _buildMarkers(),
        ),
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              '© OpenStreetMap contributors © CARTO',
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}