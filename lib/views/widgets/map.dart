import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapWidget extends StatefulWidget {
  final MapController mapController;
  final Position? currentPosition;
  final LatLng defaultLocation;
  final bool isLoading;

  const MapWidget({
    super.key,
    required this.mapController,
    required this.currentPosition,
    required this.defaultLocation,
    required this.isLoading,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  List<Marker> _buildMarkers() {
    List<Marker> markers = [];

    if (widget.currentPosition != null) {
      // Current location marker
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
                Color(0xFF8E4CB6), // Light (top)
                Color(0xFFB945AA), // Dark (bottom)
              ],
            ).createShader(bounds),
            child: const Icon(
              Icons.location_on,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
      );

      // Example destination marker
      markers.add(
        Marker(
          point: LatLng(
            widget.currentPosition!.latitude + 0.01,
            widget.currentPosition!.longitude + 0.01,
          ),
          width: 40,
          height: 40,
          child: const Icon(
            Icons.location_on,
            color: Colors.red,
            size: 40,
          ),
        ),
      );
    }

    return markers;
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
        : widget.defaultLocation;

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
          // FIX: Add retinaMode to handle {r} placeholder
          retinaMode: RetinaMode.isHighDensity(context),
        ),
        MarkerLayer(
          markers: _buildMarkers(),
        ),
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              '© OpenStreetMap contributors © CARTO',
              onTap: () {}, // Can add URL launcher here
            ),
          ],
        ),
      ],
    );
  }
}