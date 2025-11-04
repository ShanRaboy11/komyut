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

  const MapWidget({
    super.key,
    required this.mapController,
    required this.currentPosition,
    required this.defaultLocation,
    required this.isLoading,
    this.boardingLocation,
    this.arrivalLocation,
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

    // Add boarding location marker (green)
    if (widget.boardingLocation != null) {
      markers.add(
        Marker(
          point: widget.boardingLocation!,
          width: 50,
          height: 50,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Boarding',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(
                Icons.location_on,
                color: Colors.green,
                size: 40,
              ),
            ],
          ),
        ),
      );
    }

    // Add arrival location marker (red)
    if (widget.arrivalLocation != null) {
      markers.add(
        Marker(
          point: widget.arrivalLocation!,
          width: 50,
          height: 50,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Arrival',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 40,
              ),
            ],
          ),
        ),
      );
    }

    return markers;
  }

  List<Polyline> _buildRoute() {
    List<Polyline> polylines = [];

    // Draw line between boarding and arrival if both exist
    if (widget.boardingLocation != null && widget.arrivalLocation != null) {
      polylines.add(
        Polyline(
          points: [
            widget.boardingLocation!,
            widget.arrivalLocation!,
          ],
          color: const Color(0xFF8E4CB6),
          strokeWidth: 4.0,
          borderColor: Colors.white,
          borderStrokeWidth: 2.0,
        ),
      );
    }

    return polylines;
  }

  LatLngBounds? _getBounds() {
    if (widget.boardingLocation != null && widget.arrivalLocation != null) {
      double minLat = widget.boardingLocation!.latitude < widget.arrivalLocation!.latitude
          ? widget.boardingLocation!.latitude
          : widget.arrivalLocation!.latitude;
      double maxLat = widget.boardingLocation!.latitude > widget.arrivalLocation!.latitude
          ? widget.boardingLocation!.latitude
          : widget.arrivalLocation!.latitude;
      double minLng = widget.boardingLocation!.longitude < widget.arrivalLocation!.longitude
          ? widget.boardingLocation!.longitude
          : widget.arrivalLocation!.longitude;
      double maxLng = widget.boardingLocation!.longitude > widget.arrivalLocation!.longitude
          ? widget.boardingLocation!.longitude
          : widget.arrivalLocation!.longitude;

      // Add padding
      double latPadding = (maxLat - minLat) * 0.2;
      double lngPadding = (maxLng - minLng) * 0.2;

      return LatLngBounds(
        LatLng(minLat - latPadding, minLng - lngPadding),
        LatLng(maxLat + latPadding, maxLng + lngPadding),
      );
    }
    return null;
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
          polylines: _buildRoute(),
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