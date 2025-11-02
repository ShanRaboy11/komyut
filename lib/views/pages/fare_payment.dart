import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/map.dart';
import '../widgets/booking.dart';

class RideBookingScreen extends StatefulWidget {
  final String? tripId;
  final double? fareAmount;
  final int? distanceMeters;

  const RideBookingScreen({
    super.key,
    this.tripId,
    this.fareAmount,
    this.distanceMeters,
  });

  @override
  State<RideBookingScreen> createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends State<RideBookingScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  bool _isLoading = true;
  int _passengerCount = 1;

  final LatLng _defaultLocation = const LatLng(10.3157, 123.8854);

  @override
  void initState() {
    super.initState();

    // Use the trip data
    if (widget.tripId != null) {
      debugPrint('Trip ID: ${widget.tripId}');
      debugPrint('Fare: ${widget.fareAmount}');
      debugPrint('Distance: ${widget.distanceMeters}m');
    }

    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Permission.location.request();

      if (permission.isGranted) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        setState(() {
          _currentPosition = position;
          _isLoading = false;
        });

        // Animate to user location
        Future.delayed(const Duration(milliseconds: 300), () {
          // Check if the widget is still mounted before performing UI updates
          if (mounted) {
            _mapController.move(
              LatLng(position.latitude, position.longitude),
              15.0,
            );
          }
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showPermissionDialog();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error getting location: $e');
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'Please enable location permission to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            mapController: _mapController,
            currentPosition: _currentPosition,
            defaultLocation: _defaultLocation,
            isLoading: _isLoading,
          ),
          Positioned(
            top: 50,
            left: 16,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BookingBottomSheet(
              passengerCount: _passengerCount,
              onPassengerCountChanged: (count) {
                setState(() {
                  _passengerCount = count;
                });
              },
              onProceed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Proceeding with booking...')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
