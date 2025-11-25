import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/map_route.dart';
import '../services/route_service.dart';

class JCodeFinder extends StatefulWidget {
  const JCodeFinder({super.key});

  @override
  State<JCodeFinder> createState() => _JCodeFinderState();
}

class _JCodeFinderState extends State<JCodeFinder> {
  final Color _primaryPurple = const Color(0xFF8E4CB6);
  final _routeService = RouteService();

  bool _isLoading = true;
  String _errorMessage = '';

  final MapController _mapController = MapController();
  final LatLng _defaultLocation = const LatLng(10.3157, 123.8854);

  bool _isMapLoading = false;
  List<Map<String, dynamic>> _currentRouteStops = [];

  List<RouteBasic> _availableRoutes = [];
  int _selectedIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchRelevantRoutes();
  }

  Future<void> _fetchRelevantRoutes() async {
    if (_availableRoutes.isNotEmpty || !_isLoading) return;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final String origin = args?['origin'] ?? '';
    final String destination = args?['destination'] ?? '';

    if (origin.isEmpty || destination.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Search details missing";
      });
      return;
    }

    try {
      final routes = await _routeService.findRoutesConnecting(
        origin,
        destination,
      );

      if (mounted) {
        setState(() {
          _availableRoutes = routes;
          _isLoading = false;
        });

        if (routes.isNotEmpty) {
          _onRouteSelected(0);
        } else {
          setState(() => _selectedIndex = -1);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Failed to load routes. Please try again.";
        });
      }
    }
  }

  Future<void> _onRouteSelected(int index) async {
    setState(() {
      _selectedIndex = index;
      _isMapLoading = true;
    });

    try {
      final routeId = _availableRoutes[index].id;
      final stops = await _routeService.getStopsForRoute(routeId);

      if (mounted) {
        setState(() {
          _currentRouteStops = stops;
          _isMapLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading stops: $e");
      if (mounted) setState(() => _isMapLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final RouteBasic? currentRoute =
        (_availableRoutes.isNotEmpty && _selectedIndex != -1)
        ? _availableRoutes[_selectedIndex]
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FF),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 20, 30, 10),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.chevron_left_rounded,
                  color: Colors.black54,
                  size: 24,
                ),
              ),
            ),

            Expanded(child: _buildBody(currentRoute)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(RouteBasic? currentRoute) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          _errorMessage,
          style: GoogleFonts.nunito(color: Colors.grey),
        ),
      );
    }

    if (_availableRoutes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _primaryPurple.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _primaryPurple.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.wrong_location_rounded,
                      size: 26,
                      color: _primaryPurple,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Direct Route',
                style: GoogleFonts.manrope(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "No single jeepney connects these spots directly.",
                style: GoogleFonts.nunito(
                  color: Colors.grey[600],
                  fontSize: 13,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Compact Pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _primaryPurple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _primaryPurple.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 14,
                      color: _primaryPurple,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Try searching by landmark',
                      style: GoogleFonts.nunito(
                        color: _primaryPurple,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jeepney Routes',
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _primaryPurple,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select a code to view route details.',
            style: GoogleFonts.nunito(fontSize: 14, color: Colors.grey[600]),
          ),

          const SizedBox(height: 20),

          // Map Container
          Container(
            height: 350,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _primaryPurple.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  MapRoute(
                    mapController: _mapController,
                    routeStops: _currentRouteStops,
                    defaultLocation: _defaultLocation,
                    isLoading: _isMapLoading,
                  ),

                  Container(
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  Positioned(
                    top: 20,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.directions_bus,
                            size: 16,
                            color: _primaryPurple,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Route: ${currentRoute?.code ?? "N/A"}',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _primaryPurple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Route Path Pill
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _primaryPurple.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.swap_calls_rounded,
                    color: _primaryPurple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Route Path',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentRoute?.name ??
                            currentRoute?.description ??
                            'Unknown Route',
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Grid of Codes
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
              ),
              itemCount: _availableRoutes.length,
              itemBuilder: (context, index) {
                final route = _availableRoutes[index];
                final isSelected = _selectedIndex == index;

                return GestureDetector(
                  onTap: () {
                    _onRouteSelected(index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? _primaryPurple : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? _primaryPurple : Colors.transparent,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? _primaryPurple.withValues(alpha: 0.3)
                              : Colors.grey.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        route.code,
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
