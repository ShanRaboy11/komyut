import 'dart:async';
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

  // Focus nodes
  final FocusNode _fromFocus = FocusNode();
  final FocusNode _toFocus = FocusNode();

  // Colors
  final Color _primaryPurple = const Color(0xFF8E4CB6);
  final Color _secondaryPurple = const Color(0xFF5B53C2);

  // Backend state
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;

  List<Map<String, String>> _recentDestinations = [];
  List<Map<String, String>> _displayList = [];

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchUserRecentDestinations();

    _fromController.addListener(() {
      setState(() {});
      if (_fromFocus.hasFocus) _onSearchChanged(_fromController.text);
    });

    _toController.addListener(() {
      setState(() {});
      if (_toFocus.hasFocus) _onSearchChanged(_toController.text);
    });

    _fromFocus.addListener(() {
      if (_fromFocus.hasFocus) {
        _onSearchChanged(_fromController.text);
      } else {
        setState(() {});
      }
    });

    _toFocus.addListener(() {
      if (_toFocus.hasFocus) {
        _onSearchChanged(_toController.text);
      } else {
        setState(() {});
      }
    });
  }

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
            final String coordString = '$lat, $long';

            uniquePlaces.add({'name': name, 'area': coordString});
            seenNames.add(name);
          }
        }
        if (uniquePlaces.length >= 5) break;
      }

      if (mounted) {
        setState(() {
          _recentDestinations = uniquePlaces;
          _displayList = List.from(uniquePlaces);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching recent places: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onSearchChanged(String query) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.isEmpty) {
      setState(() {
        _displayList = List.from(_recentDestinations);
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final List<Map<String, String>> filteredRecents = _recentDestinations
            .where(
              (place) =>
                  place['name']!.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();

        final response = await _supabase
            .from('route_stops')
            .select('name, latitude, longitude')
            .ilike('name', '%$query%')
            .limit(5);

        final List<Map<String, String>> dbResults = [];
        for (var item in response) {
          final name = item['name'] as String;
          if (!filteredRecents.any((r) => r['name'] == name)) {
            final double lat = (item['latitude'] as num?)?.toDouble() ?? 0.0;
            final double long = (item['longitude'] as num?)?.toDouble() ?? 0.0;
            dbResults.add({'name': name, 'area': '$lat, $long'});
          }
        }

        if (mounted) {
          setState(() {
            _displayList = [...filteredRecents, ...dbResults].take(5).toList();
          });
        }
      } catch (e) {
        debugPrint("Search error: $e");
      }
    });
  }

  void _swapLocations() {
    final temp = _fromController.text;
    _fromController.text = _toController.text;
    _toController.text = temp;
    if (_fromFocus.hasFocus) _onSearchChanged(_fromController.text);
    if (_toFocus.hasFocus) _onSearchChanged(_toController.text);
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _fromFocus.dispose();
    _toFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasInput =
        _fromController.text.isNotEmpty && _toController.text.isNotEmpty;

    String listTitle = 'Recent destinations';
    if (_fromFocus.hasFocus) {
      listTitle = 'Suggested origin';
    } else if (_toFocus.hasFocus) {
      listTitle = 'Suggested destination';
    }

    String currentQuery = '';
    if (_fromFocus.hasFocus) currentQuery = _fromController.text;
    if (_toFocus.hasFocus) currentQuery = _toController.text;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F1FF),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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

              // Title
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
                        color: _primaryPurple.withValues(alpha: 0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextField(
                          controller: _fromController,
                          focusNode: _fromFocus,
                          decoration: InputDecoration(
                            hintText: 'From',
                            hintStyle: GoogleFonts.nunito(
                              color: Colors.grey[500],
                              fontSize: 16,
                            ),
                            prefixIcon: Icon(
                              Icons.my_location_rounded,
                              color:
                                  (_fromFocus.hasFocus ||
                                      _fromController.text.isNotEmpty)
                                  ? _primaryPurple
                                  : Colors.grey[400],
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
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

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
                                focusNode: _toFocus,
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
                                  color: Colors.black,
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

              // Search Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: hasInput
                        ? LinearGradient(
                            colors: [_primaryPurple, _secondaryPurple],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          )
                        : null,
                    color: hasInput ? null : Colors.grey[300],
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: hasInput
                            ? _secondaryPurple.withValues(alpha: 0.25)
                            : Colors.grey.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
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
                            color: hasInput ? Colors.white : Colors.grey[500],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // List Section
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
                        listTitle,
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
                          : _displayList.isEmpty
                          ? Center(
                              child: Text(
                                'No locations found',
                                style: GoogleFonts.nunito(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                              ),
                              itemCount: _displayList.length,
                              itemBuilder: (context, index) {
                                final place = _displayList[index];
                                return _buildPlaceItem(
                                  place['name']!,
                                  place['area']!,
                                  currentQuery,
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
      ),
    );
  }

  Widget _buildPlaceItem(String name, String coordinates, String query) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: () {
          if (_fromFocus.hasFocus) {
            _fromController.text = name;
            _toFocus.requestFocus();
          } else if (_toFocus.hasFocus) {
            _toController.text = name;
            FocusScope.of(context).unfocus();
          } else {
            _toController.text = name;
          }
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
                    blurRadius: 3,
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
                  _buildHighlightedText(name, query),
                  const SizedBox(height: 4),
                  Text(
                    coordinates,
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

  Widget _buildHighlightedText(String text, String query) {
    final TextStyle baseStyle = GoogleFonts.nunito(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: Colors.black87,
    );

    if (query.isEmpty) {
      return Text(text, style: baseStyle, overflow: TextOverflow.ellipsis);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    if (!lowerText.contains(lowerQuery)) {
      return Text(text, style: baseStyle, overflow: TextOverflow.ellipsis);
    }

    final start = lowerText.indexOf(lowerQuery);
    final end = start + lowerQuery.length;

    return RichText(
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: text.substring(0, start)),
          TextSpan(
            text: text.substring(start, end),
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _primaryPurple,
            ),
          ),
          TextSpan(text: text.substring(end)),
        ],
      ),
    );
  }
}
