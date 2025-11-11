import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DriverCard extends StatelessWidget {
  final String name;
  final String puvType;
  final String plate;
  final VoidCallback? onPressed;

  const DriverCard({
    super.key,
    required this.name,
    required this.puvType,
    required this.plate,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF8E4CB6), width: 1.2),
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              height: 50,
              width: 50,
              decoration: const BoxDecoration(
                color: Color(0xFFF2EAFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: Color(0xFF9C6BFF),
                size: 28,
              ),
            ),
            SizedBox(width: 15),

            // Text Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "$puvType • $plate",
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      color: Colors.black.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
