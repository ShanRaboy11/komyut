import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

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
    if (!isScanning) return;

    final List<Barcode> barcodes = barcodeCapture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        setState(() {
          isScanning = false;
        });
        
        // Handle the scanned QR code
        _handleScannedCode(code);
      }
    }
  }

  void _handleScannedCode(String code) {
    // Pause animation when code is scanned
    _animationController.stop();
    
    // Show dialog with scanned result
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code Scanned'),
        content: Text('Code: $code'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                isScanning = true;
              });
              _animationController.repeat(reverse: true);
            },
            child: const Text('Scan Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Process the payment or navigate to next screen
            },
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      
      if (image != null) {
        // Analyze the picked image for QR code
        final BarcodeCapture? barcodes = await cameraController.analyzeImage(image.path);
        
        if (barcodes != null && barcodes.barcodes.isNotEmpty) {
          final String? code = barcodes.barcodes.first.rawValue;
          if (code != null) {
            _handleScannedCode(code);
          }
        } else {
          // No QR code found in image
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
      backgroundColor: Colors.white,
      body: SafeArea(
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
                'Place the QR at the center of your camera and the QR will be automatically scanned',
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
                        child: Container(),
                      ),

                      // Animated Scanning Line
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: ScannerLinePainter(_animation.value),
                            child: Container(),
                          );
                        },
                      ),

                      // Center Icon
                      Center(
                        child: Container(
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

                      // Bottom controls
                      Positioned(
                        bottom: 40,
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
                onPressed: () {
                  _pickImageFromGallery();
                },
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
    final rect = Rect.fromLTWH(left, top, centerSquareSize, centerSquareSize);

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(0)))
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
    
    // Calculate the Y position of the scanning line
    final lineY = top + (centerSquareSize * animationValue);

    final paint = Paint()
      ..color = const Color(0xFF9C27B0)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    // Draw the scanning line
    canvas.drawLine(
      Offset(left, lineY),
      Offset(left + centerSquareSize, lineY),
      paint,
    );

    // Draw a gradient effect above the line
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