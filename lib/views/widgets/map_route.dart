import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapRoute extends StatefulWidget {
  final MapController mapController;
  final List<Map<String, dynamic>>? routeStops;
  final LatLng defaultLocation;
  final bool isLoading;

  const MapRoute({
    super.key,
    required this.mapController,
    required this.routeStops,
    required this.defaultLocation,
    this.isLoading = false,
  });

  @override
  State<MapRoute> createState() => _MapRouteState();
}

class _MapRouteState extends State<MapRoute> {
  final Color _startColor = const Color(0xFF5B53C2);
  final Color _endColor = const Color(0xFF8E4CB6);

  List<Marker> _buildMarkers() {
    if (widget.routeStops == null || widget.routeStops!.isEmpty) return [];

    List<Marker> markers = [];
    final stops = widget.routeStops!;

    Marker createPin({
      required double lat,
      required double lng,
      required Color color,
      required String label,
      required IconData icon,
      bool isDestination = false,
    }) {
      return Marker(
        point: LatLng(lat, lng),
        width: 80,
        height: 80,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
              ),
            ),
            const SizedBox(height: 4),
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

    final startStop = stops.first;
    markers.add(
      createPin(
        lat: startStop['latitude'],
        lng: startStop['longitude'],
        color: _startColor,
        label: "Start",
        icon: Icons.trip_origin_rounded,
      ),
    );

    if (stops.length > 1) {
      final endStop = stops.last;
      markers.add(
        createPin(
          lat: endStop['latitude'],
          lng: endStop['longitude'],
          color: _endColor,
          label: "End",
          icon: Icons.location_on_rounded,
          isDestination: true,
        ),
      );
    }

    return markers;
  }

  List<Polyline> _buildPolylines() {
    if (widget.routeStops == null || widget.routeStops!.length < 2) return [];

    final points = widget.routeStops!
        .map((s) => LatLng(s['latitude'], s['longitude']))
        .toList();

    return [Polyline(points: points, color: _endColor, strokeWidth: 5.0)];
  }

  void _fitBounds() {
    if (widget.routeStops == null || widget.routeStops!.isEmpty) return;

    final points = widget.routeStops!
        .map((s) => LatLng(s['latitude'], s['longitude']))
        .toList();

    if (points.isNotEmpty && mounted) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          widget.mapController.fitCamera(
            CameraFit.bounds(
              bounds: LatLngBounds.fromPoints(points),
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 70),
            ),
          );
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
  }

  @override
  void didUpdateWidget(covariant MapRoute oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routeStops != widget.routeStops) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Container(
        color: Colors.grey[100],
        child: Center(child: CircularProgressIndicator(color: _endColor)),
      );
    }

    final center = (widget.routeStops != null && widget.routeStops!.isNotEmpty)
        ? LatLng(
            widget.routeStops!.first['latitude'],
            widget.routeStops!.first['longitude'],
          )
        : widget.defaultLocation;

    return FlutterMap(
      mapController: widget.mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 13.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
        ),
        PolylineLayer(polylines: _buildPolylines()),
        MarkerLayer(markers: _buildMarkers()),
        RichAttributionWidget(
          showFlutterMapAttribution: true,
          attributions: [
            TextSourceAttribution('OpenStreetMap contributors', onTap: () {}),
          ],
        ),
      ],
    );
  }
}
