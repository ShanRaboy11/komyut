import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class DriverTrip {
  final DateTime date;
  final String origin;
  final String destination;
  final String routeCode;
  final double fareAmount;
  final String status;

  DriverTrip({
    required this.date,
    required this.origin,
    required this.destination,
    required this.routeCode,
    required this.fareAmount,
    required this.status,
  });
}

class DriverTripHistoryPage extends StatefulWidget {
  const DriverTripHistoryPage({super.key});

  @override
  State<DriverTripHistoryPage> createState() => _DriverTripHistoryPageState();
}

class _DriverTripHistoryPageState extends State<DriverTripHistoryPage> {
  final List<DriverTrip> _trips = List.generate(15, (index) {
    final random = Random();
    const locations = [
      'SM Cebu',
      'Colon',
      'Ayala',
      'IT Park',
      'Talamban',
      'Mactan Airport',
      'Plaza Independencia',
    ];
    final origin = locations[random.nextInt(locations.length)];
    String destination;
    do {
      destination = locations[random.nextInt(locations.length)];
    } while (destination == origin);

    String status;
    if (index == 0) {
      status = 'ongoing';
    } else {
      final statusChance = random.nextDouble();
      if (statusChance > 0.8) {
        status = 'cancelled';
      } else {
        status = 'completed';
      }
    }

    return DriverTrip(
      date: DateTime.now().subtract(
        Duration(days: index, hours: random.nextInt(12)),
      ),
      origin: origin,
      destination: destination,
      routeCode: '04L',
      fareAmount: status == 'completed'
          ? (random.nextDouble() * 800 + 400)
          : 0.0,
      status: status,
    );
  });

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
      body: SingleChildScrollView(
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

    return Container(
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
                DateFormat('MMMM d, yyyy').format(trip.date),
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
            DateFormat('hh:mm a').format(trip.date),
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
                      '${trip.origin} → ${trip.destination}',
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
