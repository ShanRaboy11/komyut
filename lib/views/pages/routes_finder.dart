import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/route_service.dart';

class RouteFinderPage extends StatefulWidget {
  const RouteFinderPage({super.key});

  @override
  State<RouteFinderPage> createState() => _RouteFinderPageState();
}

class _RouteFinderPageState extends State<RouteFinderPage> {
  final TextEditingController _searchController = TextEditingController();
  final RouteService _routeService = RouteService();
  final MapController _mapController = MapController();

  List<RouteSearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  RouteDetail? _selectedRoute;
  bool _isLoadingRoute = false;

  final LatLng _cebuCenter = const LatLng(10.3157, 123.8854);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchRoutes() async {
    final query = _searchController.text.trim();
    
    if (query.isEmpty) {
      _showSnackBar('Please enter a place name', isError: true);
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = false;
      _selectedRoute = null;
    });

    try {
      final results = await _routeService.searchRoutesByPlace(query);
      
      setState(() {
        _searchResults = results;
        _isSearching = false;
        _hasSearched = true;
      });

      if (results.isEmpty) {
        _showSnackBar('No routes found for "$query"');
      }
    } catch (e) {
      setState(() => _isSearching = false);
      _showSnackBar('Error searching routes: ${e.toString()}', isError: true);
    }
  }

  Future<void> _viewRouteDetails(RouteSearchResult result) async {
    setState(() => _isLoadingRoute = true);

    try {
      final routeDetail = await _routeService.getRouteDetail(result.routeId);
      
      setState(() {
        _selectedRoute = routeDetail;
        _isLoadingRoute = false;
      });

      // Center map on route if we have coordinates
      if (routeDetail?.stops.isNotEmpty ?? false) {
        final firstStop = routeDetail!.stops.first;
        _mapController.move(
          LatLng(firstStop.latitude, firstStop.longitude),
          14.0,
        );
      }
    } catch (e) {
      setState(() => _isLoadingRoute = false);
      _showSnackBar('Error loading route: ${e.toString()}', isError: true);
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

  List<Marker> _buildMarkers() {
    if (_selectedRoute == null) return [];

    return _selectedRoute!.stops.map((stop) {
      return Marker(
        point: LatLng(stop.latitude, stop.longitude),
        width: 40,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.location_on,
              color: Color(0xFF5B53C2),
              size: 40,
            ),
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
      );
    }).toList();
  }

  List<LatLng> _buildPolyline() {
    if (_selectedRoute == null) return [];

    return _selectedRoute!.stops.map((stop) {
      return LatLng(stop.latitude, stop.longitude);
    }).toList();
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
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Route Finder',
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search Bar
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search for a place (e.g., SM City)',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF7F4FF),
                          ),
                          onSubmitted: (_) => _searchRoutes(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF5B53C2), Color(0xFFB945AA)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.search, color: Colors.white),
                          onPressed: _searchRoutes,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Search Results or Route Details
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedRoute != null
                      ? _buildRouteDetailsView()
                      : _buildSearchResultsView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultsView() {
    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Search for a place',
              style: GoogleFonts.manrope(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Enter a landmark, street, or place name to find routes that pass through it',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.route_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No routes found',
              style: GoogleFonts.manrope(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching for another place',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Found ${_searchResults.length} route${_searchResults.length == 1 ? '' : 's'}',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _searchResults.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final result = _searchResults[index];
              return _RouteResultCard(
                result: result,
                onTap: () => _viewRouteDetails(result),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRouteDetailsView() {
    if (_isLoadingRoute) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Back to results button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFFF7F4FF),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() => _selectedRoute = null);
                },
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back to results'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF5B53C2),
                ),
              ),
            ],
          ),
        ),

        // Route info
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5B53C2), Color(0xFFB945AA)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _selectedRoute!.code,
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedRoute!.name ?? 'Route Details',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (_selectedRoute!.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  _selectedRoute!.description!,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
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
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                retinaMode: RetinaMode.isHighDensity(context),
              ),
              if (_buildPolyline().length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _buildPolyline(),
                      color: const Color(0xFF5B53C2),
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),
        ),

        // Stops list
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Stops (${_selectedRoute!.stops.length})',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _selectedRoute!.stops.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final stop = _selectedRoute!.stops[index];
                      return ListTile(
                        leading: Container(
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
                        title: Text(
                          stop.name,
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        contentPadding: EdgeInsets.zero,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RouteResultCard extends StatelessWidget {
  final RouteSearchResult result;
  final VoidCallback onTap;

  const _RouteResultCard({
    required this.result,
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
          border: Border.all(color: Colors.purple.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B53C2), Color(0xFFB945AA)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                result.routeCode,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (result.routeName != null)
                    Text(
                      result.routeName!,
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Passes through ${result.matchingStop}',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}