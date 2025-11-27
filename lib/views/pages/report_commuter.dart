import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../widgets/big_card.dart';
import '../providers/report.dart';
import '../models/report.dart';
import 'success_reportpage_commuter.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  bool showFirst = true;
  bool show = false;
  bool showSecondSheet = false;

  double _sheetHeight = 0;
  double _sheetOpacity = 0;
  double _logoOpacity = 0.0;
  final List<String> selectedCategories = [];
  String severity = 'High';
  
  // Form controllers
  final TextEditingController _descriptionController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  final List<String> categories = [
    "Vehicle",
    "Driver",
    "Route",
    "Safety & Security",
    "Traffic",
    "Lost Item",
    "App",
    "Miscellaneous",
  ];

  void toggleCategory(String category) {
    setState(() {
      if (selectedCategories.contains(category)) {
        selectedCategories.remove(category);
      } else {
        selectedCategories.add(category);
      }
    });
  }

  Future<void> _pickImage() async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening image picker...'), duration: Duration(milliseconds: 700)),
        );
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (!mounted) return;

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image selected'), duration: Duration(milliseconds: 900)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _submitReport() async {
    if (selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one category')),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a description')),
      );
      return;
    }

    final reportProvider = Provider.of<ReportProvider>(context, listen: false);

    // Convert selected categories to ReportCategory enum
    final List<ReportCategory> reportCategories = selectedCategories
        .map((cat) => ReportCategory.fromDisplayName(cat))
        .toList();

    // Convert severity to enum
    final ReportSeverity reportSeverity = ReportSeverity.fromString(
      severity.toLowerCase(),
    );

    final success = await reportProvider.submitReport(
      categories: reportCategories,
      severity: reportSeverity,
      description: _descriptionController.text.trim(),
      attachmentFile: _selectedImage,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const SuccessPage(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reportProvider.errorMessage ?? 'Failed to submit report',
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    // Fade in logo AFTER first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenSize = MediaQuery.of(context).size;
      setState(() {
        _sheetHeight = screenSize.height * 0.74;
        _sheetOpacity = 1.0;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _logoOpacity = 1.0;
      });
    });

    // Swap image after delay
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => showFirst = false);
      }
    });
  }

  void _collapseSheet() {
    setState(() {
      _sheetHeight = 0;
      _sheetOpacity = 0;
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final reportProvider = Provider.of<ReportProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        leading: AnimatedOpacity(
          opacity: _logoOpacity,
          duration: const Duration(milliseconds: 2000),
          curve: Curves.easeOut,
          child: IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: Colors.black),
            onPressed: () async {
              _collapseSheet();
              await Future.delayed(const Duration(milliseconds: 200));
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
          ),
        ),
        title: AnimatedOpacity(
          opacity: _logoOpacity,
          duration: const Duration(milliseconds: 2000),
          curve: Curves.easeOut,
          child: Text(
            'Reports',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFFF8F7FF),
            child: Stack(
              children: [
                Positioned(
                  top: screenSize.height * 0.13,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: _sheetOpacity,
                      duration: const Duration(milliseconds: 2000),
                      curve: Curves.easeOut,
                      child: Image.asset(
                        'assets/images/komyut small logo.png',
                        width: screenSize.width * 0.5,
                      ),
                    ),
                  ),
                ),

                // First Sheet - Category Selection
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: showSecondSheet ? 0 : _sheetHeight,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 600),
                    opacity: _sheetHeight == 0 ? 0 : 1,
                    curve: Curves.easeOutCubic,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      decoration: const ShapeDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(0.50, 0.00),
                          end: Alignment(0.50, 1.00),
                          colors: [
                            Color(0xFFB945AA),
                            Color(0xFF8E4CB6),
                            Color(0xFF5B53C2),
                          ],
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(60),
                            topRight: Radius.circular(60),
                          ),
                        ),
                        shadows: [
                          BoxShadow(
                            color: Color(0xFFF8F7FF),
                            blurRadius: 4,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: BigCard(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 65.0,
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Report an Issue",
                                  style: GoogleFonts.manrope(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Thank you for using komyut. Please report any issues you experienced during your ride. Your report helps us improve safety and service.",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "Category of Concern",
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "Select all that apply.",
                                    style: GoogleFonts.nunito(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final double itemWidth =
                                        (constraints.maxWidth - 12) / 2;

                                    return Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: categories.map((category) {
                                        final bool selected = selectedCategories
                                            .contains(category);

                                        return GestureDetector(
                                          onTap: () => toggleCategory(category),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            width: itemWidth,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: selected
                                                  ? Colors.white
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(
                                                10,
                                              ),
                                              border: Border.all(
                                                color: Colors.white70,
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              category,
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.nunito(
                                                fontSize: 12,
                                                fontWeight: selected
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                                color: selected
                                                    ? const Color(0xFF5B53C2)
                                                    : Colors.white,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),

                                const SizedBox(height: 24),

                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "Severity",
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: ["Low", "Medium", "High"].map((level) {
                                    final bool isSelected = severity == level;
                                    return ChoiceChip(
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() {
                                            severity = level;
                                          });
                                        }
                                      },
                                      label: Text(
                                        level,
                                        style: GoogleFonts.nunito(
                                          color: isSelected ? const Color(0xFF5B53C2) : Colors.white,
                                          fontSize: 14,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        ),
                                      ),
                                      backgroundColor: Colors.transparent,
                                      selectedColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    );
                                  }).toList(),
                                ),

                                const SizedBox(height: 40),

                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: const Color(0xFF5B53C2),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          showSecondSheet = true;
                                        });
                                      },
                                      child: Text(
                                        "Continue",
                                        style: GoogleFonts.nunito(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Second Sheet - Report Details
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: showSecondSheet ? _sheetHeight : 0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 600),
                    opacity: _sheetHeight == 0 ? 0 : 1,
                    curve: Curves.easeOutCubic,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      decoration: const ShapeDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(0.50, 0.00),
                          end: Alignment(0.50, 1.00),
                          colors: [
                            Color(0xFFB945AA),
                            Color(0xFF8E4CB6),
                            Color(0xFF5B53C2),
                          ],
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(60),
                            topRight: Radius.circular(60),
                          ),
                        ),
                        shadows: [
                          BoxShadow(
                            color: Color(0xFFF8F7FF),
                            blurRadius: 4,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: BigCard(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 65.0,
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  "Report an Issue",
                                  style: GoogleFonts.manrope(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Thank you for using komyut. Please report any issues you experienced during your ride. Your report helps us improve safety and service.",
                                  style: GoogleFonts.nunito(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),

                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "Report Details",
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white38),
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.white12,
                                  ),
                                  child: TextField(
                                    controller: _descriptionController,
                                    maxLines: 4,
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.all(12),
                                      hintText: "Tell us what happened.",
                                      hintStyle: GoogleFonts.nunito(
                                        fontSize: 14,
                                        color: Colors.white70,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "Attachment",
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: _pickImage,
                                    child: Container(
                                      width: double.infinity,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.white38),
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.white12,
                                      ),
                                      child: _selectedImage != null
                                          ? Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: Image.file(
                                                  _selectedImage!,
                                                  width: double.infinity,
                                                  height: 120,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              Positioned(
                                                top: 4,
                                                right: 4,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _selectedImage = null;
                                                    });
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black54,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.close,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                          : Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons.add_photo_alternate_outlined,
                                                  color: Colors.white70,
                                                  size: 36,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  "Add photo (optional)",
                                                  style: GoogleFonts.nunito(
                                                    fontSize: 14,
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 40),

                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: const Color(0xFF5B53C2),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                      ),
                                      onPressed: reportProvider.isLoading
                                          ? null
                                          : _submitReport,
                                      child: reportProvider.isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<Color>(
                                                  Color(0xFF5B53C2),
                                                ),
                                              ),
                                            )
                                          : Text(
                                              "Submit Report",
                                              style: GoogleFonts.nunito(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (reportProvider.isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}