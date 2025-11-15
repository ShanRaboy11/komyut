import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class TripsCard extends StatelessWidget {
  final String date;
  final String time;
  final String from;
  final String to;
  final String tripCode;
  final String status;
  final VoidCallback? onPressed; // ongoing, completed, cancelled

  const TripsCard({
    super.key,
    required this.date,
    required this.time,
    required this.from,
    required this.to,
    required this.tripCode,
    required this.status,
    this.onPressed,
  });

  Color getStatusColor() {
    switch (status) {
      case "ongoing":
        return const Color(0xFFFFC107); // yellow
      case "completed":
        return Colors.green;
      case "cancelled":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF8E4CB6)), // main purple
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Symbols.today_rounded,
                        color: Color(0xFF8E4CB6),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        date,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Symbols.schedule_rounded,
                        color: Color(0xFF8E4CB6),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        time,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const SizedBox(width: 2),
                      Container(
                        height: 15,
                        width: 15,
                        decoration: BoxDecoration(
                          color: getStatusColor(),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                from,
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6), // optional spacing
                            const Icon(
                              Symbols.arrow_forward,
                              color: Color.fromARGB(255, 0, 0, 0),
                              size: 18,
                            ),
                            const SizedBox(width: 6), // optional spacing
                            Flexible(
                              child: Text(
                                to,
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Right content — trip code
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                tripCode,
                style: GoogleFonts.manrope(
                  fontSize: 45,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF9C6BFF),
                  letterSpacing: -1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
