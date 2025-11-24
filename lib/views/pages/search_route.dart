import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  // Backend state
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, String>> _recentPlaces = [];

  @override
  void initState() {
    super.initState();
    _fetchUserRecentDestinations();

    // Listen to changes to update button state
    _fromController.addListener(() => setState(() {}));
    _toController.addListener(() => setState(() {}));
  }

  /// Fetches recent destinations from the user's trip history
  Future<void> _fetchUserRecentDestinations() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .single();

      final response = await _supabase
          .from('trips')
          .select('''
            destination_stop:destination_stop_id (
              name,
              latitude,
              longitude
            )
          ''')
          .eq('created_by_profile_id', profile['id'])
          .order('started_at', ascending: false)
          .limit(20);

      final List<Map<String, String>> uniquePlaces = [];
      final Set<String> seenNames = {};

      for (var item in response) {
        final dest = item['destination_stop'];
        if (dest != null) {
          final String name = dest['name'] ?? 'Unknown Location';

          if (!seenNames.contains(name)) {
            final double lat = (dest['latitude'] as num?)?.toDouble() ?? 0.0;
            final double long = (dest['longitude'] as num?)?.toDouble() ?? 0.0;

            // UPDATED: No rounding off. Shows exact DB value.
            final String coordString = '$lat, $long';

            uniquePlaces.add({'name': name, 'area': coordString});
            seenNames.add(name);
          }
        }
        if (uniquePlaces.length >= 5) break;
      }

      if (mounted) {
        setState(() {
          _recentPlaces = uniquePlaces;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching recent places: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
    // Check if both fields have text
    final bool hasInput =
        _fromController.text.isNotEmpty && _toController.text.isNotEmpty;

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

            // UPDATED: Search Button (Disabled logic added)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  // Show gradient only if enabled
                  gradient: hasInput
                      ? LinearGradient(
                          colors: [_primaryPurple, _secondaryPurple],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : null,
                  // Show grey if disabled
                  color: hasInput ? null : Colors.grey[300],
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: hasInput
                      ? [
                          BoxShadow(
                            color: _secondaryPurple.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ]
                      : [], // No shadow when disabled
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    // Disable tap if inputs are empty
                    onTap: hasInput
                        ? () {
                            Navigator.pushNamed(context, '/jcode_finder');
                          }
                        : null,
                    child: Center(
                      child: Text(
                        'Search',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          // Change text color to greyish if disabled
                          color: hasInput ? Colors.white : Colors.grey[500],
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
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _recentPlaces.isEmpty
                        ? Center(
                            child: Text(
                              'No recent trips found',
                              style: GoogleFonts.nunito(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
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
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceItem(String name, String coordinates) {
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    coordinates, // Full precision coordinates
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
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
    );
  }
}
