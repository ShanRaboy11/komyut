// ignore_for_file: library_private_types_in_public_api
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import '../widgets/trip_card.dart';
import '../pages/tripdetails_commuter.dart';
import '../services/trips.dart';
import '../models/trips.dart';

class Trip1Page extends StatefulWidget {
  const Trip1Page({super.key});

  @override
  State<Trip1Page> createState() => _Trip1PageState();
}

class _Trip1PageState extends State<Trip1Page> with SingleTickerProviderStateMixin {
  final TripsService _service = TripsService();
  bool _isLoading = true;
  String? _error;
  List<TripItem> _trips = [];
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _loadAllTrips();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadAllTrips() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final rows = await _service.getAllTrips();
      setState(() {
        _trips = rows;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load trips: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Enhanced shimmer effect
  Widget _buildShimmer({required Widget child}) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, shimmerChild) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
              stops: [
                _shimmerController.value - 0.3,
                _shimmerController.value,
                _shimmerController.value + 0.3,
              ],
            ).createShader(bounds);
          },
          child: shimmerChild,
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    ),
                  ),
                  Text(
                    "All Trips",
                    style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Loading State
              if (_isLoading)
                Expanded(
                  child: ListView.builder(
                    itemCount: 8,
                    itemBuilder: (context, idx) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF8E4CB6).withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromRGBO(0, 0, 0, 0.05),
                            blurRadius: 4,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Date and time
                                Row(
                                  children: [
                                    _buildShimmer(
                                      child: Container(
                                        width: 90,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildShimmer(
                                      child: Container(
                                        width: 50,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                
                                // Route code
                                _buildShimmer(
                                  child: Container(
                                    width: 70,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                
                                // From -> To
                                Row(
                                  children: [
                                    _buildShimmer(
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.arrow_forward,
                                      size: 12,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(width: 6),
                                    _buildShimmer(
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildShimmer(
                                        child: Container(
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // Status badge
                          _buildShimmer(
                            child: Container(
                              width: 80,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              
              // Error State
              else if (_error != null)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadAllTrips,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8E4CB6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Retry',
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              
              // Empty State
              else if (_trips.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.directions_bus_outlined,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No trips found',
                          style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your trip history will appear here',
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              
              // Trips List
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadAllTrips,
                    color: const Color(0xFF8E4CB6),
                    child: ListView.builder(
                      itemCount: _trips.length,
                      itemBuilder: (context, idx) {
                        final t = _trips[idx];
                        return TripsCard(
                          date: t.date,
                          time: t.time,
                          from: t.from.isNotEmpty ? t.from : 'Unknown',
                          to: t.to.isNotEmpty ? t.to : 'Unknown',
                          tripCode: t.tripCode.isNotEmpty ? t.tripCode : '',
                          status: t.status,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TripDetailsPage(
                                  tripId: t.tripId,
                                  date: t.date,
                                  time: t.time,
                                  from: t.from,
                                  to: t.to,
                                  tripCode: t.tripCode,
                                  status: t.status,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}