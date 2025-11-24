import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RouteFinder extends StatefulWidget {
  const RouteFinder({super.key});

  @override
  State<RouteFinder> createState() => _RouteFinderState();
}

class _RouteFinderState extends State<RouteFinder> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  // Common color used in the app
  final Color _primaryPurple = const Color(0xFF8E4CB6);
  final Color _secondaryPurple = const Color(0xFF5B53C2);

  final List<Map<String, String>> _recentPlaces = [
    {'name': 'SM Seaside', 'area': 'Lagos'},
    {'name': 'SM Cebu Entrance 1', 'area': 'Lekki'},
    {'name': 'CIT-U', 'area': 'Lagos'},
    {'name': 'Colonade', 'area': 'Lekki'},
  ];

  void _swapLocations() {
    final temp = _fromController.text;
    _fromController.text = _toController.text;
    _toController.text = temp;
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FF), // Wallet background color
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with back button
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

            // Title section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find your next Trip',
                    style: GoogleFonts.manrope(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _primaryPurple,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Where are you heading for?',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Input card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryPurple.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // From field
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _fromController,
                        decoration: InputDecoration(
                          hintText: 'From',
                          hintStyle: GoogleFonts.nunito(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                          prefixIcon: Icon(
                            Icons.my_location_rounded,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          color: _primaryPurple,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // To field with swap button
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: TextField(
                              controller: _toController,
                              decoration: InputDecoration(
                                hintText: 'To',
                                hintStyle: GoogleFonts.nunito(
                                  color: Colors.grey[500],
                                  fontSize: 16,
                                ),
                                prefixIcon: Icon(
                                  Icons.location_on_rounded,
                                  color: _primaryPurple,
                                  size: 20,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                color: _primaryPurple,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Swap button
                        GestureDetector(
                          onTap: _swapLocations,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_primaryPurple, _secondaryPurple],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: _secondaryPurple.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.swap_vert_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // UPDATED: "Search" Button (Navigates to JCode Finder as requested)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryPurple, _secondaryPurple],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _secondaryPurple.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      // Navigate to JCode Finder as per previous instruction
                      Navigator.pushNamed(context, '/jcode_finder');
                    },
                    child: Center(
                      child: Text(
                        'Search',
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
            ),

            const SizedBox(height: 24),

            // Recent places section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 0,
                    ),
                    child: Text(
                      'Recent places',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      itemCount: _recentPlaces.length,
                      itemBuilder: (context, index) {
                        final place = _recentPlaces[index];
                        return _buildPlaceItem(place['name']!, place['area']!);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceItem(String name, String area) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: () {
          _toController.text = name;
        },
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.05),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                Icons.history_rounded,
                color: _primaryPurple,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  area,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
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
