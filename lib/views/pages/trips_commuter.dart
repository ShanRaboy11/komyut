// ignore_for_file: library_private_types_in_public_api
// 'material.dart' already imported above
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

class _Trip1PageState extends State<Trip1Page> {
  final TripsService _service = TripsService();
  bool _isLoading = true;
  String? _error;
  List<TripItem> _trips = [];

  @override
  void initState() {
    super.initState();
    _loadAllTrips();
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

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_error != null)
                Center(child: Text(_error!))
              else if (_trips.isEmpty)
                Center(child: Text('No trips found', style: GoogleFonts.nunito()))
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadAllTrips,
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
// removed unused helper
