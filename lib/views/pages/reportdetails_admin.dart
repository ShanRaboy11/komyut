import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ReportDetailsPage extends StatelessWidget {
  final String name;
  final String? role;
  final String id;
  final String? priority;
  final String date;
  final String description;
  final List<String> tags;
  final String imagePath;

  const ReportDetailsPage({
    super.key,
    required this.name,
    this.role,
    required this.id,
    this.priority,
    required this.date,
    required this.description,
    required this.tags,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    // Parse Date
    DateTime originalDate;
    try {
      originalDate = DateFormat('MM/dd/yy').parse(date);
    } catch (e) {
      originalDate = DateTime.now();
    }
    final formattedDate = DateFormat('EEE d MMM yyyy, hh:mma').format(originalDate);

    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFF), 
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header (Back Button and "Reports")
              Center(
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.chevron_left, size: 28, color: Color(0xFF222222)),
                      ),
                    ),
                    Center(
                      child: Text(
                        'Reports',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          color: const Color(0xFF222222),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 2. Report Details Title
              Text(
                'Report Details',
                style: GoogleFonts.manrope(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              // 3. Date and Priority Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formattedDate,
                    style: GoogleFonts.manrope(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (priority != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD8D8), // Light Pink bg
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        priority!,
                        style: GoogleFonts.manrope(
                          color: const Color(0xFFCD0000), // Red text
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // 4. Profile Card (Specific Styling)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFF8E4CB6), width: 1), // Purple Border
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3F000000),
                      blurRadius: 4,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEADDFF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_outline, color: Color(0xFF4F378B), size: 30),
                    ),
                    const SizedBox(width: 15),
                    // Text Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.manrope(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${role ?? "Commuter"} • $id',
                            style: GoogleFonts.manrope(
                              color: const Color(0xFF6D6D6D),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // 5. Description Label & Text
              Text(
                'Description',
                style: GoogleFonts.manrope(
                  color: const Color(0xFF6D6D6D),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                description,
                style: GoogleFonts.manrope(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 20),

              // 6. Tags (Vehicle, Lost Item)
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9C5FF), // Light purple bg
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.manrope(
                        color: const Color(0xFF8E4CB6), // Purple text
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 25),

              // 7. Attachment Section
              Text(
                'Attachment',
                style: GoogleFonts.manrope(
                  color: const Color(0xFF6D6D6D),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              
              // Attachment Image Container
              Container(
                width: 162,
                height: 162,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF8E4CB6), width: 1), // Purple border
                  boxShadow: const [
                     BoxShadow(
                      color: Color(0x3F000000),
                      blurRadius: 4,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Image.network(
                    imagePath.startsWith('http') ? imagePath : "https://placehold.co/162x162",
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Use local asset if network fails or provided path is an asset
                      return Image.asset(
                        imagePath, 
                        fit: BoxFit.cover,
                        errorBuilder: (c,e,s) => Container(
                          color: Colors.grey[200],
                          child: const Center(child: Icon(Icons.image, color: Colors.grey)),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // 8. Back to Home Button
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFB945AA),
                      Color(0xFF8E4CB6),
                      Color(0xFF5B53C2),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3F000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context, 
                        '/home_admin', 
                        (route) => false
                      );
                    },
                    borderRadius: BorderRadius.circular(50),
                    child: Center(
                      child: Text(
                        'Back to Home',
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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