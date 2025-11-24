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
      // UPDATED: Used the Wallet Page background color
      backgroundColor: const Color(0xFFF6F1FF),
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
                  // UPDATED: Decreased size to 28 (was 35)
                  size: 28,
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

            // Input card with From/To fields
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _primaryPurple, width: 2),
                ),
                child: Column(
                  children: [
                    // From field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _fromController,
                        decoration: InputDecoration(
                          hintText: 'From',
                          hintStyle: GoogleFonts.nunito(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        // Text color matches "Find..." style
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          color: _primaryPurple,
                          fontWeight: FontWeight.w600,
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
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _toController,
                              decoration: InputDecoration(
                                hintText: 'To',
                                hintStyle: GoogleFonts.nunito(
                                  color: Colors.grey[500],
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              // Text color matches "Find..." style
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                color: _primaryPurple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Swap button
                        GestureDetector(
                          onTap: _swapLocations,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8E4CB6), Color(0xFF5B53C2)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.swap_vert,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Recent places section
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(30, 24, 30, 16),
                      child: Text(
                        'Recent places',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        itemCount: _recentPlaces.length,
                        itemBuilder: (context, index) {
                          final place = _recentPlaces[index];
                          return _buildPlaceItem(
                            place['name']!,
                            place['area']!,
                          );
                        },
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

  Widget _buildPlaceItem(String name, String area) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: () {
          // Handle place selection
          _toController.text = name;
        },
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _primaryPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.location_on, color: _primaryPurple, size: 22),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  area,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: Colors.grey[600],
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
