import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'trips_commuter.dart';
import 'tripdetails_commuter.dart';
import '../providers/trips.dart';
import '../widgets/trip_card.dart';

class TripsPage extends StatefulWidget {
  const TripsPage({super.key});

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage>
    with SingleTickerProviderStateMixin {
  final gradientColors = const [
    Color(0xFFB945AA),
    Color(0xFF8E4CB6),
    Color(0xFF5B53C2),
  ];

  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Load data when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        context.read<TripsProvider>().initialize();
      } catch (e) {
        // Provider might not be available (e.g. after logout navigation); ignore.
        debugPrint('TripsProvider not available on init: $e');
      }
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      body: SafeArea(
        child: Consumer<TripsProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.recentTrips.isEmpty) {
              // Show the full skeleton only when doing a full load
              // and there is no cached recent trips to display.
              return _buildActivitySkeleton(size);
            }

            if (provider.errorMessage != null) {
              return Center(
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
                      'Error: ${provider.errorMessage}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => provider.refresh(),
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
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => provider.refresh(),
              color: const Color(0xFF8E4CB6),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  vertical: 30,
                  horizontal: 30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header & Dropdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Activity",
                          style: GoogleFonts.manrope(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: gradientColors,
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              dropdownColor: const Color(0xFF8A56F0),
                              value: provider.selectedRange,
                              iconEnabledColor: Colors.white,
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              items:
                                  ['Weekly', 'Monthly', 'Yearly', 'All Trips']
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(e),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  provider.changeRange(value);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Analytics Card (show enhanced skeleton when analyticsLoading)
                    provider.analyticsLoading
                        ? _buildAnalyticsSkeleton(size)
                        : _buildAnalyticsCard(context, provider, size),

                    const SizedBox(height: 30),

                    // Recent Trips Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Recent Trips",
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 30),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Trip1Page(),
                              ),
                            );
                          },
                          child: Text(
                            "View All",
                            style: GoogleFonts.nunito(
                              color: const Color.fromARGB(255, 42, 42, 42),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Status Legend
                    Row(
                      children: [
                        Text(
                          "Status",
                          style: GoogleFonts.nunito(
                            color: const Color.fromARGB(255, 0, 0, 0),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 20),
                        _buildStatusDot(Colors.yellow, "Ongoing"),
                        const SizedBox(width: 12),
                        _buildStatusDot(Colors.green, "Completed"),
                        const SizedBox(width: 12),
                        _buildStatusDot(Colors.red, "Cancelled"),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Recent Trips List - Dynamic from provider
                    if (provider.recentTrips.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.directions_bus,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No recent trips',
                                style: GoogleFonts.nunito(
                                  fontSize: 16,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...provider.recentTrips.map(
                        (trip) => TripsCard(
                          date: trip.date,
                          time: trip.time,
                          from: trip.from.isNotEmpty ? trip.from : 'Unknown',
                          to: trip.to.isNotEmpty ? trip.to : 'Unknown',
                          tripCode: trip.tripCode,
                          status: trip.status,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TripDetailsPage(
                                  tripId: trip.tripId,
                                  date: trip.date,
                                  time: trip.time,
                                  from: trip.from,
                                  to: trip.to,
                                  tripCode: trip.tripCode,
                                  status: trip.status,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
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
              colors: [Colors.grey[300]!, Colors.grey[100]!, Colors.grey[300]!],
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

  // Shimmer for white backgrounds (on gradient)
  Widget _buildShimmerOnGradient({required Widget child}) {
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
                Colors.white.withValues(alpha: 0.3),
                Colors.white.withValues(alpha: 0.6),
                Colors.white.withValues(alpha: 0.3),
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

  // Enhanced skeleton with shimmer animation
  Widget _buildActivitySkeleton(Size size) {
    return RefreshIndicator(
      onRefresh: () async {},
      color: const Color(0xFF8E4CB6),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildShimmer(
                  child: Container(
                    width: 140,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                _buildShimmer(
                  child: Container(
                    width: 120,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Analytics skeleton with enhanced visual elements
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: gradientColors,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildShimmerOnGradient(
                        child: Container(
                          width: 100,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chevron_left,
                              color: Colors.white54,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildShimmerOnGradient(
                            child: Container(
                              width: 80,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chevron_right,
                              color: Colors.white54,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Chart area with animated loading
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Total Trips skeleton
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildShimmerOnGradient(
                              child: Container(
                                width: 80,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 60,
                              height: 45,
                              child: Center(
                                child: SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),

                      // Chart skeleton
                      Expanded(
                        flex: 2,
                        child: Stack(
                          children: [
                            Container(
                              height: size.height * 0.15,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            // Animated chart line mockup
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: CustomPaint(
                                  painter: _SkeletonChartPainter(
                                    animation: _shimmerController,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Stats cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildShimmerOnGradient(
                          child: Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 60,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: Colors.white38,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  width: 80,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.white38,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildShimmerOnGradient(
                          child: Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 60,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: Colors.white38,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  width: 80,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.white38,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Recent trips header
            _buildShimmer(
              child: Container(
                width: 140,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Trip skeleton list with enhanced design
            ...List.generate(
              3,
              (idx) => Container(
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
                          _buildShimmer(
                            child: Container(
                              width: 120,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildShimmer(
                            child: Container(
                              width: 80,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildShimmer(
                                child: Container(
                                  width: 12,
                                  height: 12,
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
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildShimmer(
                                child: Container(
                                  width: 100,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildShimmer(
                      child: Container(
                        width: 70,
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
          ],
        ),
      ),
    );
  }

  // Skeleton specifically for the Analytics card (shimmer on gradient)
  Widget _buildAnalyticsSkeleton(Size size) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildShimmerOnGradient(
                child: Container(
                  width: 140,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildShimmerOnGradient(
                    child: Container(
                      width: 80,
                      height: 14,
                      color: Colors.white24,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmerOnGradient(
                      child: Container(
                        width: 80,
                        height: 18,
                        color: Colors.white24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 60,
                      height: 45,
                      child: Center(
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: Container(
                  height: size.height * 0.15,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildShimmerOnGradient(
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildShimmerOnGradient(
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(
    BuildContext context,
    TripsProvider provider,
    Size size,
  ) {
    final analytics = provider.analyticsData;
    final chartData = provider.chartData;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Range + Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Analytics",
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: provider.analyticsLoading
                        ? null
                        : () => provider.prevRange(),
                    icon: Icon(
                      Icons.chevron_left,
                      color: provider.analyticsLoading
                          ? Colors.white38
                          : Colors.white,
                    ),
                  ),
                  SizedBox(
                    child: Center(
                      child: provider.analyticsLoading
                          ? SizedBox(
                              width: 10,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            )
                          : Text(
                              analytics.period.isNotEmpty
                                  ? analytics.period
                                  : '—',
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                    ),
                  ),
                  IconButton(
                    onPressed:
                        (provider.analyticsLoading ||
                            provider.currentIndex >= 0)
                        ? null
                        : () => provider.nextRange(),
                    icon: Icon(
                      Icons.chevron_right,
                      color:
                          (provider.analyticsLoading ||
                              provider.currentIndex >= 0)
                          ? Colors.white38
                          : Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Line Chart
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side: Total Trips
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Trips",
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFF0D7FF),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 50,
                        child: provider.analyticsLoading
                            ? Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ),
                              )
                            : Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  analytics.totalTrips.toString(),
                                  style: GoogleFonts.manrope(
                                    fontSize: 35,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Right side: Chart
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: size.height * 0.15,
                  child: Stack(
                    children: [
                      if (provider.analyticsLoading)
                        Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        )
                      else if (chartData.isEmpty)
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bar_chart,
                                color: Colors.white.withValues(alpha: 0.5),
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No data',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    int index = value.toInt();
                                    if (index < 0 ||
                                        index >= chartData.length) {
                                      return const SizedBox();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        chartData[index].label,
                                        style: GoogleFonts.nunito(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: chartData
                                    .asMap()
                                    .entries
                                    .map(
                                      (e) => FlSpot(
                                        e.key.toDouble(),
                                        e.value.count.toDouble(),
                                      ),
                                    )
                                    .toList(),
                                isCurved: true,
                                color: Colors.white,
                                barWidth: 2,
                                dotData: const FlDotData(show: false),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _analyticsCard(
                "Distance",
                provider.analyticsLoading,
                provider.analyticsLoading
                    ? '—'
                    : "${analytics.totalDistance.toStringAsFixed(1)} km",
                onTap: provider.analyticsLoading
                    ? null
                    : () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Distance Details'),
                            content: Text(
                              'Total distance: ${analytics.totalDistance.toStringAsFixed(2)} km\nTotal trips: ${analytics.totalTrips}',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
              ),
              const SizedBox(width: 10),
              _analyticsCard(
                "Expense",
                provider.analyticsLoading,
                provider.analyticsLoading
                    ? '—'
                    : "₱${analytics.totalSpent.toStringAsFixed(2)}",
                onTap: provider.analyticsLoading
                    ? null
                    : () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Expense Details'),
                            content: Text(
                              'Total spent: ₱${analytics.totalSpent.toStringAsFixed(2)}\nTotal trips: ${analytics.totalTrips}',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.nunito(fontSize: 10)),
      ],
    );
  }

  Widget _analyticsCard(
    String title,
    bool isLoading,
    String value, {
    VoidCallback? onTap,
  }) {
    final card = Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(217, 153, 255, 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: const Color(0xFFF0D7FF),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 36,
            child: isLoading
                ? Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  )
                : Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );

    final tappable = onTap != null
        ? GestureDetector(onTap: onTap, child: card)
        : card;
    return Expanded(child: tappable);
  }
}

// Custom painter for skeleton chart animation
class _SkeletonChartPainter extends CustomPainter {
  final Animation<double> animation;

  _SkeletonChartPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Create a wavy line to simulate chart
    final points = 7;
    for (int i = 0; i < points; i++) {
      final x = (size.width / (points - 1)) * i;
      final y =
          size.height * 0.5 +
          (size.height * 0.3 * (i % 2 == 0 ? -1 : 1)) *
              (0.5 + 0.5 * (1 - animation.value).abs());

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw dots on the line
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points; i++) {
      final x = (size.width / (points - 1)) * i;
      final y =
          size.height * 0.5 +
          (size.height * 0.3 * (i % 2 == 0 ? -1 : 1)) *
              (0.5 + 0.5 * (1 - animation.value).abs());
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }

    // Draw axis labels skeleton
    final labelPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points; i++) {
      final x = (size.width / (points - 1)) * i;
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(x, size.height + 8),
          width: 20,
          height: 8,
        ),
        labelPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_SkeletonChartPainter oldDelegate) => true;
}
