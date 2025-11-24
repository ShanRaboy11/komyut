import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  // Dynamic Data
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
          _selectedIndex = routes.isNotEmpty ? 0 : -1;
        });
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
            // 1. Header with Back Button
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

            // 2. Main Content
            Expanded(
              child: Padding(
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
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (_isLoading)
                      const Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_errorMessage.isNotEmpty)
                      Expanded(
                        child: Center(
                          child: Text(
                            _errorMessage,
                            style: GoogleFonts.nunito(color: Colors.grey),
                          ),
                        ),
                      )
                    else if (_availableRoutes.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.directions_bus_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No common routes found.',
                                style: GoogleFonts.nunito(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      // 3. MAP CONTAINER
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
                              // Map Image
                              Image.network(
                                'https://upload.wikimedia.org/wikipedia/commons/thumb/b/bd/OpenStreetMap_Logo_2011.svg/1024px-OpenStreetMap_Logo_2011.svg.png',
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (c, o, s) => Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(
                                      Icons.map,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),

                              // RESTORED: Gradient Shadow Overlay (Top)
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

                              // Route Info Pill (Top Left)
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

                      // 4. ROUTE PATH UI
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

                      // 5. Grid of Codes
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.only(bottom: 20),
                          physics: const BouncingScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
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
                                setState(() => _selectedIndex = index);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _primaryPurple
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? _primaryPurple
                                        : Colors.transparent,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelected
                                          ? _primaryPurple.withValues(
                                              alpha: 0.3,
                                            )
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
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
