import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/reportpagedriver_card.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  bool showFirst = true;
  bool show = false;

  @override
  void initState() {
    super.initState();

    // Trigger bottom slide after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => show = true);
    });

    // Swap image after delay
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => showFirst = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final width = screenSize.width;
    final isSmall = width < 400;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 30,
                      right: 30,
                      top: 30,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.chevron_left_rounded,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          "Reports",
                          style: GoogleFonts.nunito(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 1200),
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: Image.asset(
                      "assets/images/komyut small logo.png",
                      key: const ValueKey("pngImage2"),
                      height: 80,
                    ),
                  ),

                  const SizedBox(height: 24),
                  const ReportIssueCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
