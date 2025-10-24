import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/background_circles.dart';
import './fare_payment.dart';


class QRScannerScreen extends StatefulWidget {
  final VoidCallback? onScanComplete;

  const QRScannerScreen({super.key, this.onScanComplete}); 
  
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
  
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    
    // Ensure camera starts when screen initializes
    cameraController.start(); 
  }

  @override
  void dispose() {
    _animationController.dispose();
    cameraController.stop(); // Explicitly stop the camera
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture barcodeCapture) {
    if (!isScanning || _isProcessing) return;

    final List<Barcode> barcodes = barcodeCapture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        final cleanCode = code.trim();
        debugPrint('📱 QR Code detected (raw): "$code"');
        debugPrint('📱 QR Code detected (clean): "$cleanCode"');
        
        // Pause camera immediately to prevent multiple detections
        cameraController.stop(); 

        setState(() {
          isScanning = false;
          _isProcessing = true;
        });
        
        _handleScannedCode(cleanCode);
      }
    }
  }

  Future<void> _handleScannedCode(String qrCode) async {
    _animationController.stop();
    
    try {
      // ... (your existing Supabase logic for handling scanned QR code) ...
      final trimmedQR = qrCode.trim();
      final normalizedQR = trimmedQR.toUpperCase();
      
      debugPrint('🔍 ============ QR CODE SCAN DEBUG ============');
      // ... (rest of your debug prints) ...
      
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        _showError('Please log in to continue');
        _resetScanner();
        return;
      }

      final profileResponse = await supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (profileResponse == null) {
        _showError('User profile not found. Please complete registration.');
        _resetScanner();
        return;
      }

      final profileId = profileResponse['id'] as String;
      debugPrint('✅ Profile ID: $profileId');

      debugPrint('🔍 Querying drivers with route join...');
      
      final allDriversResponse = await supabase
          .from('drivers')
          .select('''
            id, 
            profile_id,
            current_qr,
            route_id,
            vehicle_plate,
            operator_name,
            active,
            routes:route_id (
              id,
              code,
              name
            )
          ''')
          .eq('active', true)
          .not('current_qr', 'is', null);

      debugPrint('📊 Total active drivers with QR codes: ${allDriversResponse.length}');

      if (allDriversResponse.isEmpty) {
        debugPrint('⚠️ No active drivers with QR codes found!');
        _showError('No active drivers available. Please try again later.');
        _resetScanner();
        return;
      }

      // ✅ Try multiple matching strategies
      Map<String, dynamic>? driverResponse;
      String matchStrategy = '';
      
      // Strategy 1: Exact match (case-sensitive, trimmed)
      for (var driver in allDriversResponse) {
        final dbQR = (driver['current_qr'] as String?)?.trim() ?? '';
        if (dbQR == trimmedQR) {
          driverResponse = driver;
          matchStrategy = 'Exact match (case-sensitive)';
          debugPrint('✅ Match found: $matchStrategy');
          break;
        }
      }
      
      // Strategy 2: Case-insensitive match
      if (driverResponse == null) {
        for (var driver in allDriversResponse) {
          final dbQR = (driver['current_qr'] as String?)?.trim().toUpperCase() ?? '';
          if (dbQR == normalizedQR) {
            driverResponse = driver;
            matchStrategy = 'Case-insensitive match';
            debugPrint('✅ Match found: $matchStrategy');
            break;
          }
        }
      }
      
      // Strategy 3: Contains match (for partial QR codes)
      if (driverResponse == null && trimmedQR.length >= 8) {
        for (var driver in allDriversResponse) {
          final dbQR = (driver['current_qr'] as String?)?.trim().toUpperCase() ?? '';
          if (dbQR.contains(normalizedQR) || normalizedQR.contains(dbQR)) {
            driverResponse = driver;
            matchStrategy = 'Partial match';
            debugPrint('✅ Match found: $matchStrategy');
            break;
          }
        }
      }

      if (driverResponse == null) {
        // ... (error handling for no match) ...
        debugPrint('❌ NO MATCH FOUND!');
        debugPrint('📊 All QR codes in database:');
        for (var driver in allDriversResponse) {
          final dbQR = driver['current_qr'] as String?;
          debugPrint('   Driver ${driver['id']}:');
          debugPrint('     Raw: "$dbQR"');
          debugPrint('     Trimmed: "${dbQR?.trim()}"');
          debugPrint('     Normalized: "${dbQR?.trim().toUpperCase()}"');
          debugPrint('     Length: ${dbQR?.length}');
          debugPrint('     Active: ${driver['active']}');
          debugPrint('     Route: ${driver['routes']}');
        }
        
        _showError(
          'Invalid QR code\n\n'
          'Scanned: "$trimmedQR"\n'
          'Please scan a valid driver QR code.'
        );
        _resetScanner();
        return;
      }

      debugPrint('✅ ============ MATCH SUCCESS ============');
      // ... (rest of your success debug prints) ...

      final driverId = driverResponse['id'] as String;
      final routeId = driverResponse['route_id'] as String?;
      final routeData = driverResponse['routes'];
      
      // ... (route data debug prints) ...

      // Check for existing ongoing trip
      final existingTrip = await supabase
          .from('trips')
          .select('id, origin_stop_id, started_at, driver_id, route_id')
          .eq('created_by_profile_id', profileId)
          .eq('status', 'ongoing')
          .maybeSingle();

      if (existingTrip != null) {
        debugPrint('🔄 Existing trip found: ${existingTrip['id']}');
        // SECOND SCAN - Arrival at destination
        await _handleArrivalScan(
          existingTrip['id'],
          existingTrip['origin_stop_id'],
          existingTrip['route_id'],
          trimmedQR,
          profileId,
        );
      } else {
        debugPrint('🚌 First scan - Creating new trip');
        // FIRST SCAN - Boarding/Takeoff
        await _handleTakeoffScan(driverId, routeId, profileId, trimmedQR);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ ============ ERROR ============');
      debugPrint('❌ Error: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      _showError('Error processing QR code: ${e.toString()}');
      _resetScanner();
    }
  }

  void _resetScanner() {
    setState(() {
      isScanning = true;
      _isProcessing = false;
    });
    _animationController.repeat(reverse: true);
    cameraController.start(); // Restart camera scanning
  }

  // ✨ NEW METHOD: Modal with gradient border
  Future<void> _showSuccessModal({
    required String title,
    required String message,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFB945AA),
                  Color(0xFF8E4CB6),
                  Color(0xFF5B53C2),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(21),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    child: Image.asset(
                      'assets/images/logo.png', // Replace with your image asset path
                      width: 50, // Set the desired width
                      height: 50,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8E4CB6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    //width: double.infinity,
                    width: 90,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        backgroundColor: const Color(0xFF8E4CB6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleTakeoffScan(
    String driverId,
    String? routeId,
    String profileId,
    String qrCode,
  ) async {
    final supabase = Supabase.instance.client;

    debugPrint('🚀 Creating trip for driver: $driverId, route: $routeId');

    try {
      final result = await supabase.from('trips').insert({
        'driver_id': driverId,
        'route_id': routeId,
        'created_by_profile_id': profileId,
        'status': 'ongoing',
        'started_at': DateTime.now().toIso8601String(),
        'metadata': {
          'takeoff_qr': qrCode,
        },
      }).select().single();

      debugPrint('✅ Trip created successfully: ${result['id']}');

      if (!mounted) return;

      // ✨ CHANGED: Modal instead of snackbar
      await _showSuccessModal(
        title: 'Boarding Recorded',
        message: 'Your trip has started.\nScan again when you arrive at your destination.',
      );
      
      // Notify parent widget if a callback is provided
      widget.onScanComplete?.call();
      // ✨ CHANGED: Reset scanner instead of Navigator.pop
      _resetScanner();

    } catch (e) {
      debugPrint('❌ Error creating trip: $e');
      _showError('Failed to create trip: ${e.toString()}');
      _resetScanner();
    }
  }

  Future<void> _handleArrivalScan(
    String tripId,
    String? originStopId,
    String? routeId,
    String qrCode,
    String profileId,
  ) async {
    final supabase = Supabase.instance.client;

    debugPrint('🏁 Completing trip: $tripId');

    try {
      // ... (your existing logic for calculating fare and updating trip) ...
      // Get destination stop (for now, we'll use a placeholder approach)
      String? destinationStopId;
      if (routeId != null && originStopId != null) {
        // Get the next stop in sequence after origin
        final originStop = await supabase
            .from('route_stops')
            .select('sequence, route_id')
            .eq('id', originStopId)
            .maybeSingle();

        if (originStop != null) {
          // Get the next stop after the origin
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

      // Placeholder values (you can calculate these properly later)
      const int distanceMeters = 5000;
      const double fareAmount = 15.00;

      debugPrint('📍 Destination stop: $destinationStopId');
      debugPrint('💰 Fare: ₱$fareAmount');

      // Update the trip with destination and fare
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

      debugPrint('✅ Trip completed successfully');

      if (!mounted) return;

      // Navigate to the fare payment screen
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
    } catch (e) {
      debugPrint('❌ Error completing trip: $e');
      _showError('Failed to complete trip: ${e.toString()}');
      _resetScanner();
    }
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
      // Pause scanning while picking image
      cameraController.stop();

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      
      if (image != null) {
        // Analyze the picked image for QR codes
        final BarcodeCapture? barcodes = await cameraController.analyzeImage(image.path);
        
        if (barcodes != null && barcodes.barcodes.isNotEmpty) {
          final String? code = barcodes.barcodes.first.rawValue;
          if (code != null) {
            final cleanCode = code.trim();
            setState(() {
              _isProcessing = true;
            });
            await _handleScannedCode(cleanCode);
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
          _resetScanner(); // Resume camera if no QR found
        }
      } else {
        _resetScanner(); // Resume camera if image picker cancelled
      }
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      _resetScanner(); // Resume camera on error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // ... (your existing UI code for the scanner) ...
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
                        const Text(
                          'QR Scan',
                          style: TextStyle(
                            fontSize: 28,
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
                        fontSize: 16,
                        color: Color(0x99000000),
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
                              // No startDelay needed here if you explicitly call controller.start() in initState
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

  // ... (your existing _buildCorner, ScannerOverlay, ScannerLinePainter classes) ...
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