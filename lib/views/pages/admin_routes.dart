import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import './admin_add_route.dart';

// Route Details Page with Edit Functionality
class RouteDetailsPage extends StatefulWidget {
  final String routeId;
  final String routeCode;

  const RouteDetailsPage({
    super.key,
    required this.routeId,
    required this.routeCode,
  });

  @override
  State<RouteDetailsPage> createState() => _RouteDetailsPageState();
}

class _RouteDetailsPageState extends State<RouteDetailsPage> {
  Map<String, dynamic>? _routeData;
  List<Map<String, dynamic>> _stops = [];
  bool _isLoading = true;
  bool _isEditing = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _codeController = TextEditingController();
  final MapController _mapController = MapController();

  List<Marker> _markers = [];
  List<LatLng> _polylinePoints = [];

  static const LinearGradient _kGradient = LinearGradient(
    colors: [Color(0xFF5B53C2), Color(0xFFB945AA)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  void initState() {
    super.initState();
    _loadRouteDetails();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadRouteDetails() async {
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      final routeResponse = await supabase
          .from('routes')
          .select()
          .eq('id', widget.routeId)
          .single();

      final stopsResponse = await supabase
          .from('route_stops')
          .select()
          .eq('route_id', widget.routeId)
          .order('sequence', ascending: true);

      setState(() {
        _routeData = routeResponse;
        _stops = List<Map<String, dynamic>>.from(stopsResponse);
        _isLoading = false;

        _codeController.text = _routeData?['code'] ?? '';
        _nameController.text = _routeData?['name'] ?? '';
        _descriptionController.text = _routeData?['description'] ?? '';

        _updateMapMarkers();
        _updatePolyline();
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showSnackBar('Error: ${e.toString()}', isError: true);
      }
    }
  }

  void _updateMapMarkers() {
    _markers = _stops
        .where((s) => s['isDeleted'] != true)
        .toList()
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key;
          final stop = entry.value;
          final visibleStops = _stops
              .where((s) => s['isDeleted'] != true)
              .toList();
          final isFirst = index == 0;
          final isLast = index == visibleStops.length - 1;

          return Marker(
            point: LatLng(stop['latitude'], stop['longitude']),
            width: 50,
            height: 60,
            child: GestureDetector(
              onTap: _isEditing
                  ? () => _showStopOptions(_stops.indexOf(stop))
                  : null,
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
                        '${stop['sequence']}',
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
        })
        .toList();
  }

  void _updatePolyline() {
    _polylinePoints = _stops.where((s) => s['isDeleted'] != true).map((stop) {
      return LatLng(stop['latitude'], stop['longitude']);
    }).toList();
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (_isEditing) {
      _showAddStopDialog(point);
    }
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
      final newStop = {
        'name': name,
        'sequence': _stops.where((s) => s['isDeleted'] != true).length + 1,
        'latitude': point.latitude,
        'longitude': point.longitude,
        'route_id': widget.routeId,
        'isNew': true,
      };
      _stops.add(newStop);
      _updateMapMarkers();
      _updatePolyline();
    });

    _showSnackBar('Stop "$name" added. Click Save to update route.');
  }

  void _showStopOptions(int index) {
    final stop = _stops[index];
    final visibleStops = _stops.where((s) => s['isDeleted'] != true).toList();
    final visibleIndex = visibleStops.indexOf(stop);
    final isFirst = visibleIndex == 0;
    final isLast = visibleIndex == visibleStops.length - 1;

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
                      '${stop['sequence']}',
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
                        stop['name'],
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
                            : 'Stop #${stop['sequence']}',
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
                    '${stop['latitude'].toStringAsFixed(6)}, ${stop['longitude'].toStringAsFixed(6)}',
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
    final stopName = _stops[index]['name'];
    setState(() {
      if (_stops[index].containsKey('id')) {
        _stops[index]['isDeleted'] = true;
      } else {
        _stops.removeAt(index);
      }

      int sequence = 1;
      for (var stop in _stops) {
        if (stop['isDeleted'] != true) {
          stop['sequence'] = sequence++;
        }
      }

      _updateMapMarkers();
      _updatePolyline();
    });
    _showSnackBar('Stop "$stopName" will be removed when you save.');
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final visibleStops = _stops.where((s) => s['isDeleted'] != true).toList();

    if (visibleStops.length < 2) {
      _showSnackBar('Route must have at least 2 stops', isError: true);
      return;
    }

    try {
      final supabase = Supabase.instance.client;

      await supabase
          .from('routes')
          .update({
            'code': _codeController.text.trim(),
            'name': _nameController.text.trim(),
            'description': _descriptionController.text.trim(),
            'start_lat': visibleStops.first['latitude'],
            'start_lng': visibleStops.first['longitude'],
            'end_lat': visibleStops.last['latitude'],
            'end_lng': visibleStops.last['longitude'],
          })
          .eq('id', widget.routeId);

      for (var stop in _stops.where((s) => s['isDeleted'] == true)) {
        if (stop.containsKey('id')) {
          await supabase.from('route_stops').delete().eq('id', stop['id']);
        }
      }

      for (var stop in _stops.where(
        (s) => s['isDeleted'] != true && s['isNew'] != true,
      )) {
        await supabase
            .from('route_stops')
            .update({'sequence': stop['sequence']})
            .eq('id', stop['id']);
      }

      final newStops = _stops.where((s) => s['isNew'] == true).toList();
      if (newStops.isNotEmpty) {
        final stopsData = newStops
            .map(
              (stop) => {
                'route_id': widget.routeId,
                'name': stop['name'],
                'sequence': stop['sequence'],
                'latitude': stop['latitude'],
                'longitude': stop['longitude'],
              },
            )
            .toList();
        await supabase.from('route_stops').insert(stopsData);
      }

      setState(() => _isEditing = false);

      _showSnackBar('Route updated successfully!');
      _loadRouteDetails();
    } catch (e) {
      _showSnackBar('Error saving changes: ${e.toString()}', isError: true);
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _codeController.text = _routeData?['code'] ?? '';
      _nameController.text = _routeData?['name'] ?? '';
      _descriptionController.text = _routeData?['description'] ?? '';
    });
    _loadRouteDetails();
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
    final visibleStops = _stops.where((s) => s['isDeleted'] != true).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      appBar: AppBar(
        title: Text(
          'Route ${widget.routeCode}',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isEditing) ...[
            TextButton.icon(
              onPressed: _cancelEdit,
              icon: const Icon(Icons.close, size: 20),
              label: const Text('Cancel'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _saveChanges,
              icon: const Icon(Icons.check, size: 20),
              label: const Text('Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B53C2),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
            const SizedBox(width: 8),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                setState(() => _isEditing = true);
              },
              tooltip: 'Edit Route',
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5B53C2), Color(0xFFB945AA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5B53C2).withAlpha(76),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isEditing) ...[
                            TextFormField(
                              controller: _codeController,
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Route Code',
                                labelStyle: GoogleFonts.nunito(
                                  color: Colors.white.withAlpha(230),
                                  fontSize: 14,
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.white.withAlpha(128),
                                  ),
                                ),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a route code';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              style: GoogleFonts.manrope(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Route Name',
                                labelStyle: GoogleFonts.nunito(
                                  color: Colors.white.withAlpha(230),
                                  fontSize: 14,
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.white.withAlpha(128),
                                  ),
                                ),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a route name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _descriptionController,
                              style: GoogleFonts.nunito(
                                color: Colors.white.withAlpha(230),
                                fontSize: 14,
                              ),
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Description',
                                labelStyle: GoogleFonts.nunito(
                                  color: Colors.white.withAlpha(230),
                                  fontSize: 14,
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.white.withAlpha(128),
                                  ),
                                ),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            Text(
                              _routeData?['name'] ?? 'Unnamed Route',
                              style: GoogleFonts.manrope(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (_routeData?['description'] != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _routeData!['description'],
                                style: GoogleFonts.nunito(
                                  color: Colors.white.withAlpha(230),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

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
                            _isEditing ? Icons.touch_app : Icons.map,
                            color: Colors.purple.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _isEditing 
                                  ? 'Tap on the map to add new stops'
                                  : 'Route map showing all stops',
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
                    
                    Container(
                      height: 300,
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
                          initialCenter: _polylinePoints.isNotEmpty
                              ? _polylinePoints.first
                              : const LatLng(10.3157, 123.8854),
                          initialZoom: 13.0,
                          onTap: _isEditing ? _onMapTap : null,
                          interactionOptions: const InteractionOptions(
                            flags:
                                InteractiveFlag.all & ~InteractiveFlag.rotate,
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
                    const SizedBox(height: 24),

                    // STOPS LIST SECTION
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Color(0xFF5B53C2),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Stops',
                          style: GoogleFonts.manrope(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5B53C2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${visibleStops.length}',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: visibleStops.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final stop = visibleStops[index];
                        final isFirst = index == 0;
                        final isLast = index == visibleStops.length - 1;
                        final isNew = stop['isNew'] == true;

                        return InkWell(
                          onTap: _isEditing
                              ? () => _showStopOptions(_stops.indexOf(stop))
                              : null,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isNew
                                    ? Colors.green.shade300
                                    : Colors.purple.shade100,
                                width: isNew ? 2 : 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(10),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
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
                                                    : const Color(0xFF5B53C2))
                                                .withAlpha(76),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${stop['sequence']}',
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
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              stop['name'],
                                              style: GoogleFonts.manrope(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                          if (isNew)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.green.shade300,
                                                ),
                                              ),
                                              child: Text(
                                                'NEW',
                                                style: GoogleFonts.manrope(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green.shade700,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (isFirst || isLast) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          isFirst
                                              ? 'Starting Point'
                                              : 'End Point',
                                          style: GoogleFonts.nunito(
                                            fontSize: 12,
                                            color: isFirst
                                                ? Colors.green
                                                : Colors.red,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (_isEditing)
                                  IconButton(
                                    icon: Icon(
                                      Icons.more_vert,
                                      color: Colors.grey.shade600,
                                    ),
                                    onPressed: () =>
                                        _showStopOptions(_stops.indexOf(stop)),
                                    tooltip: 'Stop Options',
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}

// Main Admin Routes Page
class AdminRoutesPage extends StatefulWidget {
  const AdminRoutesPage({super.key});

  @override
  State<AdminRoutesPage> createState() => _AdminRoutesPageState();
}

class _AdminRoutesPageState extends State<AdminRoutesPage> {
  List<Map<String, dynamic>> _routes = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
  setState(() => _isLoading = true);

  try {
    final supabase = Supabase.instance.client;

    // Fetch routes with stop count using aggregation
    final response = await supabase
        .from('routes')
        .select('*, route_stops!inner(count)')
        .order('code', ascending: true);

    setState(() {
      _routes = List<Map<String, dynamic>>.from(response).map((route) {
        // Extract the count from the nested structure
        final stopData = route['route_stops'];
        int stopCount = 0;
        
        if (stopData is List && stopData.isNotEmpty) {
          // If it returns a list with count property
          stopCount = stopData[0]['count'] ?? 0;
        } else if (stopData is Map && stopData.containsKey('count')) {
          // If it returns a map with count
          stopCount = stopData['count'] ?? 0;
        }
        
        return {
          ...route,
          'stop_count': stopCount,
        };
      }).toList();
      _isLoading = false;
    });
  } catch (e) {
    setState(() => _isLoading = false);
    _showSnackBar('Error loading routes: ${e.toString()}', isError: true);
  }
}


  Future<void> _deleteRoute(String routeId, String routeCode) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Delete Route',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete route $routeCode? This action cannot be undone.',
          style: GoogleFonts.nunito(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.manrope(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final supabase = Supabase.instance.client;
      await supabase.from('routes').delete().eq('id', routeId);

      _showSnackBar('Route $routeCode deleted successfully');
      _loadRoutes();
    } catch (e) {
      _showSnackBar('Error deleting route: ${e.toString()}', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredRoutes {
    if (_searchQuery.isEmpty) return _routes;

    return _routes.where((route) {
      final code = (route['code'] ?? '').toString().toLowerCase();
      final name = (route['name'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return code.contains(query) || name.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      body: SafeArea(
        child: Column(
          children: [
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
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Manage Routes',
                              style: GoogleFonts.manrope(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'View and organize all routes',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF5B53C2), Color(0xFFB945AA)],
                          ),
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
                          '${_routes.length} routes',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by code or name...',
                      hintStyle: GoogleFonts.nunito(
                        color: Colors.grey.shade500,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey.shade600,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.purple.shade100),
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
                      filled: true,
                      fillColor: const Color(0xFFF7F4FF),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminAddRoutePage(),
                          ),
                        );
                        _loadRoutes();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B53C2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.white,
                      ),
                      label: Text(
                        'Add New Route',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredRoutes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _searchQuery.isEmpty
                                  ? Icons.route_outlined
                                  : Icons.search_off,
                              size: 64,
                              color: Colors.purple.shade300,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No routes yet'
                                : 'No routes found',
                            style: GoogleFonts.manrope(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Create your first route to get started'
                                : 'Try adjusting your search',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadRoutes,
                      color: const Color(0xFF5B53C2),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredRoutes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
  final route = _filteredRoutes[index];
  // Use the pre-calculated stop_count
  final stopCount = route['stop_count'] ?? 0;

  return _RouteCard(
    routeCode: route['code'] ?? 'N/A',
    routeName: route['name'],
    description: route['description'],
    stopCount: stopCount,
    onDelete: () => _deleteRoute(
      route['id'],
      route['code'] ?? 'N/A',
    ),
    onTap: () async {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RouteDetailsPage(
            routeId: route['id'],
            routeCode: route['code'] ?? 'N/A',
          ),
        ),
      );
      _loadRoutes();
    },
  );
}
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final String routeCode;
  final String? routeName;
  final String? description;
  final int stopCount;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _RouteCard({
    required this.routeCode,
    this.routeName,
    this.description,
    required this.stopCount,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFB945AA), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB945AA).withAlpha(26),
              blurRadius: 12,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5B53C2), Color(0xFFB945AA)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5B53C2).withAlpha(76),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    routeCode,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: onDelete,
                    tooltip: 'Delete route',
                  ),
                ),
              ],
            ),
            if (routeName != null) ...[
              const SizedBox(height: 12),
              Text(
                routeName!,
                style: GoogleFonts.manrope(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
            ],
            if (description != null) ...[
              const SizedBox(height: 6),
              Text(
                description!,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F4FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 18,
                    color: Colors.purple.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$stopCount ${stopCount == 1 ? 'stop' : 'stops'}',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.purple.shade700,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
