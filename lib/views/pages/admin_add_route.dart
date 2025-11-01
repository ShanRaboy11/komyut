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

  // Gradient definition
  static const LinearGradient _kGradient = LinearGradient(
    colors: [Color(0xFF5B53C2), Color(0xFFB945AA)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: _kGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.add_location_alt,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Add Stop',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: stopNameController,
              decoration: InputDecoration(
                labelText: 'Stop Name',
                hintText: 'e.g., SM City Cebu',
                prefixIcon: const Icon(
                  Icons.location_on,
                  color: Color(0xFF5B53C2),
                ),
                filled: true,
                fillColor: const Color(0xFFF7F4FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.purple.shade100),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF5B53C2),
                    width: 2,
                  ),
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.my_location,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lat: ${point.latitude.toStringAsFixed(6)}\nLng: ${point.longitude.toStringAsFixed(6)}',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.manrope(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: _kGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5B53C2).withAlpha(76),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                if (stopNameController.text.trim().isNotEmpty) {
                  _addStop(point, stopNameController.text.trim());
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Add Stop',
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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

    _showSnackBar('Stop "${name}" added successfully');
  }

  void _updateMapMarkers() {
    _markers = _stops.asMap().entries.map((entry) {
      final index = entry.key;
      final stop = entry.value;
      final isFirst = index == 0;
      final isLast = index == _stops.length - 1;

      return Marker(
        point: LatLng(stop.latitude, stop.longitude),
        width: 50,
        height: 60,
        child: GestureDetector(
          onTap: () => _showStopOptions(index),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: isFirst
                      ? LinearGradient(
                          colors: [Colors.green, Colors.green.shade700],
                        )
                      : isLast
                      ? LinearGradient(
                          colors: [Colors.red, Colors.red.shade700],
                        )
                      : _kGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isFirst
                                  ? Colors.green
                                  : isLast
                                  ? Colors.red
                                  : const Color(0xFF5B53C2))
                              .withAlpha(102),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${stop.sequence}',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Icon(
                Icons.arrow_drop_down,
                color: isFirst
                    ? Colors.green
                    : isLast
                    ? Colors.red
                    : const Color(0xFF5B53C2),
                size: 20,
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
    final stop = _stops[index];
    final isFirst = index == 0;
    final isLast = index == _stops.length - 1;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: isFirst
                        ? LinearGradient(
                            colors: [Colors.green, Colors.green.shade700],
                          )
                        : isLast
                        ? LinearGradient(
                            colors: [Colors.red, Colors.red.shade700],
                          )
                        : _kGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${stop.sequence}',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stop.name,
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      Text(
                        isFirst
                            ? 'Starting Point'
                            : isLast
                            ? 'End Point'
                            : 'Stop #${stop.sequence}',
                        style: GoogleFonts.nunito(
                          color: isFirst
                              ? Colors.green
                              : isLast
                              ? Colors.red
                              : Colors.grey.shade600,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F4FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.my_location,
                    size: 16,
                    color: Colors.purple.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${stop.latitude.toStringAsFixed(6)}, ${stop.longitude.toStringAsFixed(6)}',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 32),
            InkWell(
              onTap: () {
                Navigator.pop(context);
                _removeStop(index);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      color: Colors.red.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Remove Stop',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _removeStop(int index) {
    final stopName = _stops[index].name;
    setState(() {
      _stops.removeAt(index);
      // Re-sequence remaining stops
      for (int i = 0; i < _stops.length; i++) {
        _stops[i].sequence = i + 1;
      }
      _updateMapMarkers();
      _updatePolyline();
    });
    _showSnackBar('Stop "$stopName" removed');
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
      await Future.delayed(const Duration(seconds: 1));
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
        content: Text(message, style: GoogleFonts.manrope(color: Colors.white)),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
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
            // Enhanced Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F4FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF5B53C2),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add New Route',
                          style: GoogleFonts.manrope(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Create a new jeepney route',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_stops.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: _kGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5B53C2).withAlpha(76),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${_stops.length} ${_stops.length == 1 ? 'stop' : 'stops'}',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Route Details Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.purple.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(13),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: _kGradient,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.edit_road,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Route Details',
                              style: GoogleFonts.manrope(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _routeCodeController,
                          decoration: InputDecoration(
                            labelText: 'Route Code *',
                            hintText: 'e.g., 04L',
                            prefixIcon: const Icon(
                              Icons.route,
                              color: Color(0xFF5B53C2),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF7F4FF),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.purple.shade100,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF5B53C2),
                                width: 2,
                              ),
                            ),
                          ),
                          textCapitalization: TextCapitalization.characters,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _routeNameController,
                          decoration: InputDecoration(
                            labelText: 'Route Name (Optional)',
                            hintText: 'e.g., SM to Ayala',
                            prefixIcon: const Icon(
                              Icons.label_outline,
                              color: Color(0xFF8E4CB6),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF7F4FF),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.purple.shade100,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF8E4CB6),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Description (Optional)',
                            hintText: 'Brief description of the route',
                            prefixIcon: const Icon(
                              Icons.description_outlined,
                              color: Color(0xFFB945AA),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF7F4FF),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.purple.shade100,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFB945AA),
                                width: 2,
                              ),
                            ),
                          ),
                          maxLines: 3,
                          minLines: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Map Instructions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF5B53C2).withAlpha(26),
                          const Color(0xFFB945AA).withAlpha(26),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.touch_app,
                          color: Colors.purple.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Tap on the map to add stops along your route',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              color: Colors.purple.shade900,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Map Card
                  Container(
                    height: 350,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.purple.shade100,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(13),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _cebuCenter,
                        initialZoom: 13.0,
                        onTap: _onMapTap,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                        ),
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
                                borderStrokeWidth: 2.0,
                                borderColor: Colors.white.withAlpha(179),
                              ),
                            ],
                          ),
                        MarkerLayer(markers: _markers),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_stops.isNotEmpty)
                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.purple.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(13),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: _kGradient,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.list_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Route Stops',
                                style: GoogleFonts.manrope(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F4FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_stops.length}',
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF5B53C2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _stops.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 24),
                            itemBuilder: (context, index) {
                              final stop = _stops[index];
                              final isFirst = index == 0;
                              final isLast = index == _stops.length - 1;

                              return InkWell(
                                onTap: () => _showStopOptions(index),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7F4FF),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.purple.shade100,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          gradient: isFirst
                                              ? LinearGradient(
                                                  colors: [
                                                    Colors.green,
                                                    Colors.green.shade700,
                                                  ],
                                                )
                                              : isLast
                                              ? LinearGradient(
                                                  colors: [
                                                    Colors.red,
                                                    Colors.red.shade700,
                                                  ],
                                                )
                                              : _kGradient,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  (isFirst
                                                          ? Colors.green
                                                          : isLast
                                                          ? Colors.red
                                                          : const Color(
                                                              0xFF5B53C2,
                                                            ))
                                                      .withAlpha(76),
                                              blurRadius: 6,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${stop.sequence}',
                                            style: GoogleFonts.manrope(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              stop.name,
                                              style: GoogleFonts.manrope(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                if (isFirst)
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      'START',
                                                      style:
                                                          GoogleFonts.manrope(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.white,
                                                          ),
                                                    ),
                                                  )
                                                else if (isLast)
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      'END',
                                                      style:
                                                          GoogleFonts.manrope(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.white,
                                                          ),
                                                    ),
                                                  ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    '${stop.latitude.toStringAsFixed(4)}, ${stop.longitude.toStringAsFixed(4)}',
                                                    style: GoogleFonts.nunito(
                                                      fontSize: 11,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete_outline,
                                          color: Colors.red.shade600,
                                          size: 22,
                                        ),
                                        onPressed: () => _removeStop(index),
                                        tooltip: 'Remove Stop',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 80), // Extra padding for save button
                ],
              ),
            ),

            // Save Button (sticky at the bottom)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: _isSaving ? null : _kGradient,
                    color: _isSaving ? Colors.grey.shade400 : null,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _isSaving
                        ? null
                        : [
                            BoxShadow(
                              color: const Color(0xFF5B53C2).withAlpha(102),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveRoute,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Saving Route...',
                                style: GoogleFonts.manrope(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'Save Route',
                            style: GoogleFonts.manrope(
                              fontSize: 18,
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
