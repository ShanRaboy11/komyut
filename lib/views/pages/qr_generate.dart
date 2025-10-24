// lib/pages/driver_qr_generate_page.dart - WITH NAVIGATION BAR & DOWNLOAD
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import '../services/qr_service.dart';
import '../widgets/navbar.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class DriverQRGenerateNav extends StatefulWidget {
  const DriverQRGenerateNav({super.key});

  @override
  State<DriverQRGenerateNav> createState() => _DriverQRGenerateNavState();
}

class _DriverQRGenerateNavState extends State<DriverQRGenerateNav> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBottomNavBar(
      pages: const [
        DriverQRGeneratePage(),
        Center(child: Text("📋 Activity")),
        Center(child: Text("✍️ Feedback")),
        Center(child: Text("🔔 Notifications")),
        Center(child: Text("👤 Profile")),
      ],
      items: const [
        NavItem(icon: Icons.home_rounded, label: 'Home'),
        NavItem(icon: Symbols.overview_rounded, label: 'Activity'),
        NavItem(icon: Symbols.rate_review_rounded, label: 'Feedback'),
        NavItem(icon: Icons.notifications_rounded, label: 'Notification'),
        NavItem(icon: Icons.person_rounded, label: 'Profile'),
      ],
    );
  }
}

class DriverQRGeneratePage extends StatefulWidget {
  const DriverQRGeneratePage({super.key});

  @override
  State<DriverQRGeneratePage> createState() => _DriverQRGeneratePageState();
}

class _DriverQRGeneratePageState extends State<DriverQRGeneratePage>
    with SingleTickerProviderStateMixin {
  final QRService _qrService = QRService();
  final GlobalKey _qrKey = GlobalKey();

  bool _isLoading = false;
  bool _qrGenerated = false;
  bool _isDownloading = false;
  String? _qrCode;
  Map<String, dynamic>? _driverData;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkExistingQR();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  Future<void> _checkExistingQR() async {
    final result = await _qrService.getCurrentQRCode();
    if (result['success'] && result['hasQR']) {
      setState(() {
        _qrGenerated = true;
        _qrCode = result['qrCode'];
        _driverData = result['data'];
      });
      _animationController.forward();
    }
  }

  Future<void> _generateQRCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Simulate generation time for better UX
    await Future.delayed(const Duration(milliseconds: 1500));

    final result = await _qrService.generateQRCode();

    if (mounted) {
      if (result['success']) {
        setState(() {
          _qrCode = result['qrCode'];
          _driverData = result['data'];
          _qrGenerated = true;
          _isLoading = false;
        });
        _animationController.forward(from: 0.0);

        _showSnackBar('QR Code generated successfully!', Colors.green);
      } else {
        setState(() {
          _errorMessage = result['message'];
          _isLoading = false;
        });

        _showSnackBar(
          result['message'] ?? 'Failed to generate QR code',
          Colors.red,
        );
      }
    }
  }

  Future<void> _downloadQRCode() async {
  if (_qrCode == null) return;

  setState(() {
    _isDownloading = true;
  });

  try {
    // Capture QR code as image
    final boundary =
        _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    if (Platform.isAndroid || Platform.isIOS) {
      // Save to temporary directory first
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final driverName = _driverData?['driverName'] ?? 'Driver';
      final fileName = 'QRCode_${driverName.replaceAll(' ', '_')}_$timestamp.png';
      final filePath = '${directory.path}/$fileName';

      // Write file
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      // Save to gallery using gal - handles all permissions automatically
      await Gal.putImage(filePath);
      
      _showSnackBar('QR Code saved to gallery!', Colors.green);
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // For desktop platforms
      final directory = await getDownloadsDirectory();
      if (directory != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final driverName = _driverData?['driverName'] ?? 'Driver';
        final fileName = 'QRCode_${driverName.replaceAll(' ', '_')}_$timestamp.png';
        final filePath = '${directory.path}/$fileName';

        final file = File(filePath);
        await file.writeAsBytes(pngBytes);

        _showSnackBar('QR Code saved to Downloads folder!', Colors.green);
      } else {
        _showSnackBar('Could not access Downloads folder', Colors.red);
      }
    } else {
      _showSnackBar('Platform not supported', Colors.orange);
    }
  } catch (e) {
    debugPrint('Error downloading QR code: $e');
    _showSnackBar('Failed to download QR code: $e', Colors.red);
  } finally {
    setState(() {
      _isDownloading = false;
    });
  }
}



  void _showSnackBar(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
  extendBody: true, // ✨ This allows content to extend behind the navbar
  body: Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFFB945AA), Color(0xFF8E4CB6), Color(0xFF5B53C2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: SafeArea(
      bottom: false, // ✨ Don't apply SafeArea to bottom
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  tooltip: 'Back',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                Text(
                  'QR Code',
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 20),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom, // ✨ Add padding for safe area at bottom
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isTablet ? 500 : double.infinity,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(30, 30, 30, 100), // ✨ Add extra bottom padding for navbar
                    child: _isLoading
                        ? _buildLoadingState()
                        : _qrGenerated
                            ? _buildQRDisplay()
                            : _buildInitialState(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 60),

        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1500),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (value * 0.2),
              child: Opacity(
                opacity: value,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF8E4CB6),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8E4CB6).withAlpha(76),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: CustomPaint(
                      size: const Size(220, 220),
                      painter: QRLoadingPainter(animationValue: value),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 40),

        const SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8E4CB6)),
          ),
        ),

        const SizedBox(height: 20),

        Text(
          'Generating QR Code...',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Please wait a moment',
          style: GoogleFonts.nunito(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildInitialState() {
    return Column(
      children: [
        const SizedBox(height: 40),

        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.qr_code_2_rounded,
            size: 120,
            color: Colors.grey[400],
          ),
        ),

        const SizedBox(height: 30),

        Text(
          'No QR Code Yet',
          style: GoogleFonts.manrope(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),

        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Generate a QR code for passengers to scan and pay their fare',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ),

        const SizedBox(height: 40),

        ElevatedButton(
          onPressed: _generateQRCode,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8E4CB6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 3,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.qr_code_scanner_rounded, size: 24),
              const SizedBox(width: 12),
              Text(
                'Generate QR Code',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        if (_errorMessage != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.nunito(
                      color: Colors.red[700],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQRDisplay() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          children: [
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFB945AA), Color(0xFF8E4CB6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8E4CB6).withAlpha(76),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _driverData?['driverName'] ?? 'Juan Dela Cruz',
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildInfoChip(
                              _driverData?['plateNumber'] ?? 'ABC-1234',
                              Icons.directions_bus_rounded,
                            ),
                            const SizedBox(width: 8),
                            _buildInfoChip(
                              _driverData?['routeNumber'] ?? 'Route 101',
                              Icons.route_rounded,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            RepaintBoundary(
              key: _qrKey,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF8E4CB6), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        QrImageView(
                          data: _qrCode!,
                          version: QrVersions.auto,
                          size: 250,
                          //backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF8E4CB6),
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF8E4CB6),
                          ),
                          embeddedImage: null,
                        ),

                        //Container(
                        //  width: 60,
                        //  height: 60,
                        //  decoration: BoxDecoration(color: Colors.white),
                        //  child: ClipRRect(
                        //    borderRadius: BorderRadius.circular(5),
                            //child: Padding(
                            //  padding: const EdgeInsets.all(8),
                            //  child: Image.asset(
                            //    'assets/images/logo.png',
                            //    fit: BoxFit.contain,
                            //    errorBuilder: (context, error, stackTrace) {
                            //      return Icon(
                            //        Icons.qr_code_2_rounded,
                           //         size: 35,
                           //         color: const Color(0xFF8E4CB6),
                             //     );
                              //  },
                            //  ),
                           // ),
                         // ),
                       // ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF8E4CB6).withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFF8E4CB6)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF8E4CB6),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Show this QR code to passengers for contactless payment',
                      style: GoogleFonts.nunito(
                        color: Color(0xFF8E4CB6),
                        fontSize: 14,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                 Expanded(
                child: ElevatedButton.icon(
                  onPressed: _generateQRCode,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: Text(
                    'Regenerate',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8E4CB6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isDownloading ? null : _downloadQRCode,
                    icon: _isDownloading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFB945AA),
                              ),
                            ),
                          )
                        : const Icon(Icons.download_rounded, size: 20),
                    label: Text(
                      _isDownloading ? 'Saving...' : 'Download',
                      style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8E4CB6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for loading animation
class QRLoadingPainter extends CustomPainter {
  final double animationValue;

  QRLoadingPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8E4CB6).withAlpha(25)
      ..style = PaintingStyle.fill;

    final gridSize = 20;
    final cellSize = size.width / gridSize;

    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        final progress = ((i + j) / (gridSize * 2)) * animationValue;
        if (progress > 0 && progress <= 1) {
          paint.color = Color.lerp(
            const Color(0xFF8E4CB6).withAlpha(25),
            const Color(0xFF8E4CB6).withAlpha(102),
            progress,
          )!;

          canvas.drawRect(
            Rect.fromLTWH(
              i * cellSize,
              j * cellSize,
              cellSize - 2,
              cellSize - 2,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(QRLoadingPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
