import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool isScanning = true;

  @override
  void dispose() {
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
                  borderRadius: BorderRadius.circular(20),
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

                      // Center Icon
                      Center(
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF9C27B0),
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Stack(
                            children: [
                              // Corner decorations
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
                            const Text(
                              'Hold',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'or enter mobile number',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.flip_camera_android,
                                color: Color(0xFF9C27B0),
                                size: 30,
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

            const SizedBox(height: 20),

            // Upload QR Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: OutlinedButton.icon(
                onPressed: () {
                  // Implement image picker for QR code
                },
                icon: const Icon(
                  Icons.upload_outlined,
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
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: Color(0xFF9C27B0), width: 6)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: Color(0xFF9C27B0), width: 6)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: Color(0xFF9C27B0), width: 6)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: Color(0xFF9C27B0), width: 6)
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
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final centerSquareSize = 250.0;
    final left = (size.width - centerSquareSize) / 2;
    final top = (size.height - centerSquareSize) / 2;
    final rect = Rect.fromLTWH(left, top, centerSquareSize, centerSquareSize);

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(20)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}