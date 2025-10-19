import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/background_circles.dart';
import './fare_payment.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> with SingleTickerProviderStateMixin {
  MobileScannerController cameraController = MobileScannerController();
  bool isScanning = true;
  bool isFlashOn = false;
  final ImagePicker _imagePicker = ImagePicker();
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  // Track scan state
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture barcodeCapture) {
    if (!isScanning || _isProcessing) return;

    final List<Barcode> barcodes = barcodeCapture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        setState(() {
          isScanning = false;
          _isProcessing = true;
        });
        
        _handleScannedCode(code);
      }
    }
  }

  Future<void> _handleScannedCode(String qrCode) async {
    _animationController.stop();
    
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        _showError('Please log in to continue');
        setState(() {
          isScanning = true;
          _isProcessing = false;
        });
        _animationController.repeat(reverse: true);
        return;
      }

      // Get user's profile_id
      final profileResponse = await supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (profileResponse == null) {
        _showError('User profile not found. Please complete registration.');
        setState(() {
          isScanning = true;
          _isProcessing = false;
        });
        _animationController.repeat(reverse: true);
        return;
      }

      final profileId = profileResponse['id'] as String;

      // Get driver info from QR code
      final driverResponse = await supabase
          .from('drivers')
          .select('id, route_code, profile_id')
          .eq('current_qr', qrCode)
          .maybeSingle();

      if (driverResponse == null) {
        _showError('Invalid QR code. Please scan a valid driver QR code.');
        setState(() {
          isScanning = true;
          _isProcessing = false;
        });
        _animationController.repeat(reverse: true);
        return;
      }

      final driverId = driverResponse['id'] as String;
      final routeCode = driverResponse['route_code'] as String?;

      // Check for existing ongoing trip
      final existingTrip = await supabase
          .from('trips')
          .select('id, origin_stop_id, started_at, driver_id')
          .eq('created_by_profile_id', profileId)
          .eq('status', 'ongoing')
          .maybeSingle();

      if (existingTrip != null) {
        // SECOND SCAN - Arrival at destination
        await _handleArrivalScan(
          existingTrip['id'],
          existingTrip['origin_stop_id'],
          qrCode,
          routeCode,
          profileId,
        );
      } else {
        // FIRST SCAN - Boarding/Takeoff
        await _handleTakeoffScan(driverId, routeCode, profileId, qrCode);
      }
    } catch (e) {
      debugPrint('Error handling scanned code: $e');
      _showError('Error: ${e.toString()}');
      setState(() {
        isScanning = true;
        _isProcessing = false;
      });
      _animationController.repeat(reverse: true);
    }
  }

  Future<void> _handleTakeoffScan(
    String driverId,
    String? routeCode,
    String profileId,
    String qrCode,
  ) async {
    final supabase = Supabase.instance.client;

    // Get route_id from route_code
    String? routeId;
    if (routeCode != null) {
      final routeResponse = await supabase
          .from('routes')
          .select('id')
          .eq('code', routeCode)
          .maybeSingle();
      routeId = routeResponse?['id'];
    }

    // Create trip with 'ongoing' status
    await supabase.from('trips').insert({
      'driver_id': driverId,
      'route_id': routeId,
      'created_by_profile_id': profileId,
      'status': 'ongoing',
      'started_at': DateTime.now().toIso8601String(),
      'metadata': {
        'takeoff_qr': qrCode,
      },
    });

    if (!mounted) return;

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Boarding recorded! Scan again when you arrive.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );

    // Return to previous screen
    Navigator.pop(context);
  }

  Future<void> _handleArrivalScan(
    String tripId,
    String? originStopId,
    String qrCode,
    String? routeCode,
    String profileId,
  ) async {
    final supabase = Supabase.instance.client;

    // Get destination stop (for now, we'll use a placeholder approach)
    // You might want to show a stop selection UI here
    String? destinationStopId;
    if (routeCode != null && originStopId != null) {
      // Get the next stop in sequence after origin
      final originStop = await supabase
          .from('route_stops')
          .select('sequence, route_id')
          .eq('id', originStopId)
          .maybeSingle();

      if (originStop != null) {
        final nextStop = await supabase
            .from('route_stops')
            .select('id')
            .eq('route_id', originStop['route_id'])
            .gt('sequence', originStop['sequence'])
            .order('sequence')
            .limit(1)
            .maybeSingle();
        
        destinationStopId = nextStop?['id'];
      }
    }

    // Calculate distance and fare (you'll need to implement fare calculation logic)
    // For now, using placeholder values
    const int distanceMeters = 5000; // 5km placeholder
    const double fareAmount = 15.00; // Placeholder fare

    // Update trip to completed
    await supabase.from('trips').update({
      'destination_stop_id': destinationStopId,
      'distance_meters': distanceMeters,
      'fare_amount': fareAmount,
      'status': 'completed',
      'ended_at': DateTime.now().toIso8601String(),
      'metadata': {
        'arrival_qr': qrCode,
      },
    }).eq('id', tripId);

    if (!mounted) return;

    // Navigate to fare payment page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RideBookingScreen(
          tripId: tripId,
          fareAmount: fareAmount,
          distanceMeters: distanceMeters,
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      
      if (image != null) {
        final BarcodeCapture? barcodes = await cameraController.analyzeImage(image.path);
        
        if (barcodes != null && barcodes.barcodes.isNotEmpty) {
          final String? code = barcodes.barcodes.first.rawValue;
          if (code != null) {
            setState(() {
              _isProcessing = true;
            });
            await _handleScannedCode(code);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No QR code found in the selected image'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFDFDFF), Color(0xFFF1F0FA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            const BackgroundCircles(),
            SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'QR Scan',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Instructions
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40.0),
                    child: Text(
                      'Scan QR code when boarding and again when arriving at your destination',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Camera Scanner
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25.0),
                        child: Stack(
                          children: [
                            // Camera View
                            MobileScanner(
                              controller: cameraController,
                              onDetect: _onDetect,
                            ),

                            // Scanning Overlay
                            CustomPaint(
                              painter: ScannerOverlay(),
                              child: const SizedBox.expand(),
                            ),

                            // Animated Scanning Line
                            AnimatedBuilder(
                              animation: _animation,
                              builder: (context, child) {
                                return CustomPaint(
                                  painter: ScannerLinePainter(_animation.value),
                                  child: const SizedBox.expand(),
                                );
                              },
                            ),

                            // Center Icon
                            Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5.0),
                                child: SizedBox(
                                  width: 250,
                                  height: 250,
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        top: -3,
                                        left: -3,
                                        child: _buildCorner(true, true),
                                      ),
                                      Positioned(
                                        top: -3,
                                        right: -3,
                                        child: _buildCorner(true, false),
                                      ),
                                      Positioned(
                                        bottom: -3,
                                        left: -3,
                                        child: _buildCorner(false, true),
                                      ),
                                      Positioned(
                                        bottom: -3,
                                        right: -3,
                                        child: _buildCorner(false, false),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Bottom controls
                            Positioned(
                              bottom: 20,
                              left: 0,
                              right: 0,
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        isFlashOn = !isFlashOn;
                                      });
                                      cameraController.toggleTorch();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isFlashOn ? Icons.flash_on : Icons.flash_off,
                                        color: const Color(0xFF9C27B0),
                                        size: 30,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Processing overlay
                            if (_isProcessing)
                              Container(
                                color: Colors.black54,
                                child: const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Processing...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Upload QR Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _pickImageFromGallery,
                      icon: const Icon(
                        Icons.image,
                        color: Color(0xFF9C27B0),
                      ),
                      label: const Text(
                        'Upload QR',
                        style: TextStyle(
                          color: Color(0xFF9C27B0),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                        side: const BorderSide(
                          color: Color(0xFF9C27B0),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner(bool isTop, bool isLeft) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: Color(0xFF9C27B0), width: 8)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: Color(0xFF9C27B0), width: 8)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: Color(0xFF9C27B0), width: 8)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: Color(0xFF9C27B0), width: 8)
              : BorderSide.none,
        ),
      ),
    );
  }
}

class ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withAlpha(204)
      ..style = PaintingStyle.fill;

    final centerSquareSize = 250.0;
    final left = (size.width - centerSquareSize) / 2;
    final top = (size.height - centerSquareSize) / 2;
    final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, centerSquareSize, centerSquareSize),
        const Radius.circular(20.0));

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(rect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class ScannerLinePainter extends CustomPainter {
  final double animationValue;

  ScannerLinePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final centerSquareSize = 250.0;
    final left = (size.width - centerSquareSize) / 2;
    final top = (size.height - centerSquareSize) / 2;

    final lineY = top + (centerSquareSize * animationValue);

    final paint = Paint()
      ..color = const Color(0xFF9C27B0)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(left, lineY),
      Offset(left + centerSquareSize, lineY),
      paint,
    );

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF9C27B0).withAlpha(0),
          const Color(0xFF9C27B0).withAlpha(77),
        ],
      ).createShader(Rect.fromLTWH(left, lineY - 30, centerSquareSize, 30));

    canvas.drawRect(
      Rect.fromLTWH(left, lineY - 30, centerSquareSize, 30),
      gradientPaint,
    );
  }

  @override
  bool shouldRepaint(ScannerLinePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}