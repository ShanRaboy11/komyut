import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminAddRoutePage extends StatefulWidget {
  const AdminAddRoutePage({super.key});

  @override
  State<AdminAddRoutePage> createState() => _AdminAddRoutePageState();
}

class _AdminAddRoutePageState extends State<AdminAddRoutePage> {
  final MapController _mapController = MapController();
  final TextEditingController _routeCodeController = TextEditingController();
  final TextEditingController _routeNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  List<RouteStop> _stops = [];
  List<Marker> _markers = [];
  List<LatLng> _polylinePoints = [];
  bool _isSaving = false;

  // Default center: Cebu City
  final LatLng _cebuCenter = const LatLng(10.3157, 123.8854);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _routeCodeController.dispose();
    _routeNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    _showAddStopDialog(point);
  }

  void _showAddStopDialog(LatLng point) {
    final TextEditingController stopNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Add Stop',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: stopNameController,
              decoration: InputDecoration(
                labelText: 'Stop Name',
                hintText: 'e.g., SM City Cebu',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            Text(
              'Lat: ${point.latitude.toStringAsFixed(6)}\nLng: ${point.longitude.toStringAsFixed(6)}',
              style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (stopNameController.text.trim().isNotEmpty) {
                _addStop(point, stopNameController.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B53C2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Add Stop'),
          ),
        ],
      ),
    );
  }

  void _addStop(LatLng point, String name) {
    setState(() {
      final stop = RouteStop(
        sequence: _stops.length + 1,
        name: name,
        latitude: point.latitude,
        longitude: point.longitude,
      );
      _stops.add(stop);
      _updateMapMarkers();
      _updatePolyline();
    });
  }

  void _updateMapMarkers() {
    _markers = _stops.asMap().entries.map((entry) {
      final index = entry.key;
      final stop = entry.value;

      return Marker(
        point: LatLng(stop.latitude, stop.longitude),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _showStopOptions(index),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.location_on, color: Color(0xFF5B53C2), size: 40),
              Positioned(
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${stop.sequence}',
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF5B53C2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _updatePolyline() {
    _polylinePoints = _stops.map((stop) {
      return LatLng(stop.latitude, stop.longitude);
    }).toList();
  }

  void _showStopOptions(int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _stops[index].name,
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Stop #${_stops[index].sequence}',
              style: GoogleFonts.nunito(color: Colors.grey),
            ),
            const Divider(height: 30),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Remove Stop'),
              onTap: () {
                Navigator.pop(context);
                _removeStop(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removeStop(int index) {
    setState(() {
      _stops.removeAt(index);
      // Re-sequence remaining stops
      for (int i = 0; i < _stops.length; i++) {
        _stops[i].sequence = i + 1;
      }
      _updateMapMarkers();
      _updatePolyline();
    });
  }

  Future<void> _saveRoute() async {
    if (_routeCodeController.text.trim().isEmpty) {
      _showSnackBar('Please enter a route code', isError: true);
      return;
    }

    if (_stops.length < 2) {
      _showSnackBar('Please add at least 2 stops', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;

      // 1. Insert route
      final routeData = {
        'code': _routeCodeController.text.trim().toUpperCase(),
        'name': _routeNameController.text.trim().isEmpty
            ? null
            : _routeNameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'start_lat': _stops.first.latitude,
        'start_lng': _stops.first.longitude,
        'end_lat': _stops.last.latitude,
        'end_lng': _stops.last.longitude,
      };

      final routeResponse = await supabase
          .from('routes')
          .insert(routeData)
          .select()
          .single();

      final routeId = routeResponse['id'];

      // 2. Insert all stops
      final stopsData = _stops.map((stop) {
        return {
          'route_id': routeId,
          'name': stop.name,
          'sequence': stop.sequence,
          'latitude': stop.latitude,
          'longitude': stop.longitude,
        };
      }).toList();

      await supabase.from('route_stops').insert(stopsData);

      _showSnackBar(
        'Route ${_routeCodeController.text.trim().toUpperCase()} saved successfully!',
      );

      // Clear form
      _routeCodeController.clear();
      _routeNameController.clear();
      _descriptionController.clear();
      setState(() {
        _stops.clear();
        _markers.clear();
        _polylinePoints.clear();
      });

      // Navigate back after a short delay
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('Error saving route: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Add New Route',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Form Section
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  TextField(
                    controller: _routeCodeController,
                    decoration: InputDecoration(
                      labelText: 'Route Code *',
                      hintText: 'e.g., 04L',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.route),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _routeNameController,
                    decoration: InputDecoration(
                      labelText: 'Route Name (Optional)',
                      hintText: 'e.g., SM to Ayala',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.label),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'Brief description of the route',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.description),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),

            // Stops Counter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFFF7F4FF),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Stops (${_stops.length})',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Tap on map to add stops',
                    style: GoogleFonts.nunito(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),

            // Map
            Expanded(
              flex: 2,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _cebuCenter,
                  initialZoom: 13.0,
                  onTap: _onMapTap,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    retinaMode: RetinaMode.isHighDensity(context),
                  ),
                  if (_polylinePoints.length > 1)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _polylinePoints,
                          color: const Color(0xFF5B53C2),
                          strokeWidth: 4.0,
                        ),
                      ],
                    ),
                  MarkerLayer(markers: _markers),
                ],
              ),
            ),

            // Stops List
            if (_stops.isNotEmpty)
              Expanded(
                flex: 1,
                child: Container(
                  color: Colors.white,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _stops.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final stop = _stops[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F4FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purple.shade100),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                color: Color(0xFF5B53C2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${stop.sequence}',
                                  style: GoogleFonts.manrope(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stop.name,
                                    style: GoogleFonts.manrope(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '${stop.latitude.toStringAsFixed(6)}, ${stop.longitude.toStringAsFixed(6)}',
                                    style: GoogleFonts.nunito(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeStop(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Save Button
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white, // This outer container's color is white
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: Container(
                  // This is the container that provides the gradient
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFB945AA),
                        Color(0xFF8E4CB6),
                        Color(0xFF5B53C2),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(
                      12,
                    ), // Match button's border radius
                  ),
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveRoute,
                    style: ElevatedButton.styleFrom(
                      // ****** THIS IS THE CRUCIAL CHANGE ******
                      backgroundColor: Colors
                          .transparent, // Make the ElevatedButton transparent
                      shadowColor:
                          Colors.transparent, // Remove button's default shadow
                      padding: EdgeInsets
                          .zero, // Remove default padding to let gradient fill fully
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Save Route',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RouteStop {
  int sequence;
  String name;
  double latitude;
  double longitude;

  RouteStop({
    required this.sequence,
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}
