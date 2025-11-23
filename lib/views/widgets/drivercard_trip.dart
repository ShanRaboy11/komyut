import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DriverCard extends StatelessWidget {
  final String? name;
  final String role;
  final String? plate;

  const DriverCard({
    super.key,
    this.name,
    required this.role,
    this.plate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // Avatar: show initials when name is available, otherwise icon
          Container(
            height: 50,
            width: 50,
            decoration: const BoxDecoration(
              color: Color(0xFFF2EAFF),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Builder(builder: (context) {
              final n = (name ?? '').trim();
              if (n.isEmpty || n.toLowerCase() == 'null') {
                return const Icon(
                  Icons.person_outline_rounded,
                  color: Color(0xFF9C6BFF),
                  size: 28,
                );
              }

              // Compute initials (first letter of first two words)
              String initials = '';
              final parts = n.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
              if (parts.isEmpty) {
                initials = n[0].toUpperCase();
              } else if (parts.length == 1) {
                initials = parts[0][0].toUpperCase();
              } else {
                initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
              }

              return Text(
                initials,
                style: GoogleFonts.manrope(
                  color: const Color(0xFF9C6BFF),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              );
            }),
          ),
          const SizedBox(width: 15),

          // Text Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  () {
                    final n = (name ?? '').trim();
                    return (n.isNotEmpty && n.toLowerCase() != 'null') ? n : 'Unknown Driver';
                  }(),
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "$role • ${((plate ?? '').isNotEmpty ? plate : '-')}",
                  overflow: TextOverflow.ellipsis,
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
    );
  }
}
