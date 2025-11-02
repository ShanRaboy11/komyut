import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReportCard extends StatelessWidget {
  final String name;
  final String priority;
  final String date;
  final String description;
  final List<String> tags;
  final VoidCallback? onTap;

  const ReportCard({
    super.key,
    required this.name,
    required this.priority,
    required this.date,
    required this.description,
    required this.tags,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 400;

    return GestureDetector(
      onTap: onTap, // 👈 TRIGGER TAP
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF8E4CB6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header Row (Name + Priority + Date) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    "$name • $priority",
                    style: GoogleFonts.manrope(
                      fontSize: isSmall ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  date,
                  style: GoogleFonts.nunito(
                    fontSize: isSmall ? 12 : 14,
                    color: const Color.fromARGB(157, 0, 0, 0),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // --- Description Text ---
            Text(
              "“$description”",
              style: GoogleFonts.nunito(
                fontSize: isSmall ? 13 : 14,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 10),

            // --- Tags Section ---
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: tags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9B8FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.nunito(
                          fontSize: isSmall ? 12 : 13,
                          color: const Color(0xFF6B2CBF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
