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

class _TripsPageState extends State<TripsPage> {
  final gradientColors = const [
    Color(0xFFB945AA),
    Color(0xFF8E4CB6),
    Color(0xFF5B53C2),
  ];

  @override
  void initState() {
    super.initState();
    // Load data when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripsProvider>().initialize();
    });
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
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${provider.errorMessage}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => provider.refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => provider.refresh(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 30),
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
                            fontSize: 28,
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
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              items: ['Weekly', 'Monthly', 'Yearly', 'All Trips']
                                  .map((e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e),
                                      ))
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

                    // Analytics Card
                    _buildAnalyticsCard(context, provider, size),

                    const SizedBox(height: 30),

                    // Recent Trips Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Recent Trips",
                          style: GoogleFonts.manrope(
                            fontSize: 22,
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
                              fontSize: 16,
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
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 20),
                        _buildStatusDot(Colors.yellow, "Ongoing"),
                        const SizedBox(width: 16),
                        _buildStatusDot(Colors.green, "Completed"),
                        const SizedBox(width: 16),
                        _buildStatusDot(Colors.red, "Cancelled"),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Recent Trips List - Dynamic from provider
                    if (provider.recentTrips.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Text(
                            'No recent trips',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    else
                      ...provider.recentTrips.map((trip) => TripsCard(
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
                          )),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(BuildContext context, TripsProvider provider, Size size) {
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
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: provider.isLoading ? null : () => provider.prevRange(),
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                  ),
                  Text(
                    analytics.period.isNotEmpty ? analytics.period : 'Loading...',
                    style: GoogleFonts.nunito(color: Colors.white, fontSize: 14),
                  ),
                  IconButton(
                    onPressed: (provider.isLoading || provider.currentIndex >= 0)
                        ? null
                        : () => provider.nextRange(),
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
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
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFF0D7FF),
                        ),
                      ),
                      provider.isLoading
                          ? const SizedBox(
                              height: 45,
                              width: 45,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              analytics.totalTrips.toString(),
                              style: GoogleFonts.manrope(
                                fontSize: 45,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
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
                  child: chartData.isEmpty
                      ? const Center(
                          child: Text(
                            'No data',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    int index = value.toInt();
                                    if (index < 0 || index >= chartData.length) {
                                      return const SizedBox();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        chartData[index].label,
                                        style: GoogleFonts.nunito(
                                          color: Colors.white,
                                          fontSize: 12,
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
                                    .map((e) => FlSpot(
                                          e.key.toDouble(),
                                          e.value.count.toDouble(),
                                        ))
                                    .toList(),
                                isCurved: true,
                                color: Colors.white,
                                barWidth: 2,
                                dotData: const FlDotData(show: false),
                              ),
                            ],
                          ),
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
                provider.isLoading ? 'Loading...' : "${analytics.totalDistance.toStringAsFixed(1)} km",
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Distance Details'),
                      content: Text(provider.isLoading
                          ? 'Loading...'
                          : 'Total distance: ${analytics.totalDistance.toStringAsFixed(2)} km\nTotal trips: ${analytics.totalTrips}'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 20),
              _analyticsCard(
                "Expense",
                provider.isLoading ? 'Loading...' : "₱${analytics.totalSpent.toStringAsFixed(2)}",
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Expense Details'),
                      content: Text(provider.isLoading
                          ? 'Loading...'
                          : 'Total spent: ₱${analytics.totalSpent.toStringAsFixed(2)}\nTotal trips: ${analytics.totalTrips}'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
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
        Text(label, style: GoogleFonts.nunito(fontSize: 14)),
      ],
    );
  }

  Widget _analyticsCard(String title, String value, {VoidCallback? onTap}) {
    final card = Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFD999FF).withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 16,
              color: const Color(0xFFF0D7FF),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );

    final tappable = onTap != null ? GestureDetector(onTap: onTap, child: card) : card;
    return Expanded(child: tappable);
  }
}