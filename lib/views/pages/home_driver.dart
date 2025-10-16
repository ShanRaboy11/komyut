//driver
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dotted_border/dotted_border.dart';
import '../widgets/button.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  bool _isVisible = true;

  // 🔹 Added missing state variables
  bool showTooltip = false;
  bool qrGenerated = false;
  bool isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isTablet ? 500 : double.infinity,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER SECTION
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFB945AA),
                          Color(0xFF8E4CB6),
                          Color(0xFF5B53C2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // LOGO
                        SvgPicture.asset('assets/images/logo.svg', height: 80),
                        const SizedBox(height: 20),

                        // EARNINGS + BALANCE
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildHeaderCard(
                              title: "Today's Earnings",
                              amount: '₱500.00',
                            ),
                            _buildHeaderCard(
                              title: "Current Balance",
                              amount: '₱500.00',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // MAIN QR DISPLAY AREA
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.all(Radius.circular(24)),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Header with Info Icon
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'QR Code',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  showTooltip = !showTooltip;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (showTooltip)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade800,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Use your QR code for quick and secure payments',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),

                        // QR Code Display Area
                        DottedBorder(
                          color: const Color(0xFFB945AA),
                          strokeWidth: 1,
                          dashPattern: const [6, 3], // dash length, gap length
                          borderType: BorderType.RRect,
                          radius: const Radius.circular(16),
                          child: Container(
                            height: 280,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color.fromARGB(255, 246, 238, 250),
                                  Color(0xFFF4E9FF),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(child: _buildQRContent()),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: qrGenerated
                              ? [
                                  Expanded(
                                    child: CustomButton(
                                      text: 'Download',
                                      icon: Icons.download_rounded,
                                      onPressed: () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Download QR'),
                                          ),
                                        );
                                      },
                                      height: 50,
                                      borderRadius: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: CustomButton(
                                      text: 'Share',
                                      icon: Icons.share_rounded,
                                      isFilled: false,
                                      outlinedFillColor: Colors.white,
                                      textColor: const Color(0xFF8E4CB6),
                                      onPressed: () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Share QR'),
                                          ),
                                        );
                                      },
                                      height: 50,
                                      borderRadius: 14,
                                    ),
                                  ),
                                ]
                              : [
                                  Expanded(
                                    child: CustomButton(
                                      text: 'Generate QR',
                                      onPressed: isGenerating
                                          ? () {}
                                          : handleGenerateQR,
                                      height: 50,
                                      borderRadius: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: CustomButton(
                                      text: 'Import',
                                      isFilled: false,
                                      outlinedFillColor: Colors.white,
                                      textColor: const Color(0xFF8E4CB6),
                                      onPressed: handleImport,
                                      height: 50,
                                      borderRadius: 14,
                                    ),
                                  ),
                                ],
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          'Use your QR for quick payments.',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Nunito',
                            color: Color(0xFF6D6D6D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ANALYTICS & FEEDBACK
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildAnalyticsCard()),
                      const SizedBox(width: 10),
                      Expanded(child: _buildFeedbackCard()),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 Placeholder: QR Content Builder
  Widget _buildQRContent() {
    return const Icon(Icons.qr_code_2, size: 150, color: Color(0xFF8E4CB6));
  }

  // 🔹 Placeholder: Generate & Import handlers
  void handleGenerateQR() {
    setState(() {
      isGenerating = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        isGenerating = false;
        qrGenerated = true;
      });
    });
  }

  void handleImport() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Import clicked')));
  }

  // HEADER CARD
  Widget _buildHeaderCard({required String title, required String amount}) {
    return StatefulBuilder(
      builder: (context, setInnerState) {
        bool visible = _isVisible;

        return Container(
          width: 150,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: GoogleFonts.nunito(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () => setInnerState(() {
                      visible = !visible;
                    }),
                    child: Icon(
                      visible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                visible ? amount : '•••••',
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF8E4CB6), width: 0.7),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analytics',
            style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(height: 60, color: Colors.grey[200]),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: const Offset(0, 3),
                ),
              ],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Rating 4.20',
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF8E4CB6), width: 0.7),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Feedback',
            style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: const Offset(0, 3),
                ),
              ],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Reports 2',
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          CustomButton(
            text: 'View commuter reports',
            onPressed: () {},
            isFilled: true,
            textColor: Colors.white,
            width: double.infinity,
            height: 45,
            borderRadius: 30,
            fontSize: 14,
          ),
        ],
      ),
    );
  }
}
