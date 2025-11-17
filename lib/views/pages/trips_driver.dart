import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import '../models/driver_trip.dart';
import '../services/driver_trip.dart';
import 'tripdetails_driver.dart';

class DriverTripHistoryPage extends StatefulWidget {
  const DriverTripHistoryPage({super.key});

  @override
  State<DriverTripHistoryPage> createState() => _DriverTripHistoryPageState();
}

class _DriverTripHistoryPageState extends State<DriverTripHistoryPage> {
  final DriverTripService _tripService = DriverTripService();
  List<DriverTrip> _trips = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final trips = await _tripService.getDriverTripHistory();
      setState(() {
        _trips = trips;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _statusBackground(String status) {
    switch (status.toLowerCase()) {
      case "ongoing":
        return const Color(0xFFFFF5CC);
      case "completed":
        return const Color(0xFFE9F8E8);
      case "cancelled":
        return const Color(0xFFFFE5E5);
      default:
        return Colors.grey.shade200;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "ongoing":
        return const Color(0xFFFFC107);
      case "completed":
        return Colors.green;
      case "cancelled":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FF),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Trip History',
          style: GoogleFonts.manrope(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
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
                        'Failed to load trips',
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadTrips,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8E4CB6),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : _trips.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No trips yet',
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your trip history will appear here',
                            style: GoogleFonts.nunito(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTrips,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 40.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'All Trips',
                              style: GoogleFonts.manrope(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _buildStatusDot(_statusColor("ongoing"), "Ongoing"),
                                const SizedBox(width: 20),
                                _buildStatusDot(_statusColor("completed"), "Completed"),
                                const SizedBox(width: 20),
                                _buildStatusDot(_statusColor("cancelled"), "Cancelled"),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ListView.separated(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: _trips.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                return _buildTripCard(_trips[index]);
                              },
                            ),
                          ],
                        ),
                      ),
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
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.nunito(fontSize: 14)),
      ],
    );
  }

  Widget _buildTripCard(DriverTrip trip) {
    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

    final statusColor = _statusColor(trip.status);
    final statusBackgroundColor = _statusBackground(trip.status);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DriverTripDetailsPage(
              tripId: trip.id,
              date: DateFormat('MMMM d, yyyy').format(trip.startedAt),
              time: DateFormat('hh:mm a').format(trip.startedAt),
              from: trip.originName,
              to: trip.destinationName,
              tripCode: trip.routeCode,
              status: trip.status,
            ),
          ),
        );
      },
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM d, yyyy').format(trip.startedAt),
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  trip.status.toUpperCase(),
                  style: GoogleFonts.manrope(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('hh:mm a').format(trip.startedAt),
            style: GoogleFonts.nunito(color: Colors.grey[600], fontSize: 14),
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Symbols.route, color: Color(0xFF8E4CB6), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${trip.originName} → ${trip.destinationName}',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Route ${trip.routeCode}',
                      style: GoogleFonts.nunito(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (trip.status == 'completed')
                Text(
                  currencyFormat.format(trip.fareAmount),
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.green[800],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}