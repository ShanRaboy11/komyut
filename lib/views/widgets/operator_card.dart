import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OperatorCard extends StatelessWidget {
  final String operatorName;
  final String activeDrivers;
  final String routeStart;
  final String routeEnd;
  final String routeCode;
  final VoidCallback onApply;

  const OperatorCard({
    super.key,
    required this.operatorName,
    required this.activeDrivers,
    required this.routeStart,
    required this.routeEnd,
    required this.routeCode,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 380;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                operatorName,
                style: GoogleFonts.nunito(
                  fontSize: isSmall ? 15 : 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              Text(
                "$activeDrivers Active Drivers",
                style: GoogleFonts.nunito(
                  fontSize: isSmall ? 12 : 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Divider
          Divider(color: Colors.grey.shade300, thickness: 1),

          const SizedBox(height: 10),

          // Route Row
          Row(
            children: [
              // Icon
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFBA68C8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.alt_route_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),

              // Route Info
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$routeStart → $routeEnd",
                    style: GoogleFonts.nunito(
                      fontSize: isSmall ? 14 : 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    "Route $routeCode",
                    style: GoogleFonts.nunito(
                      fontSize: isSmall ? 12 : 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Apply Button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                border: Border.all(width: 2, color: const Color(0xFF7C3AED)),
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFBA68C8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: TextButton(
                onPressed: onApply,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  "Apply",
                  style: GoogleFonts.nunito(
                    color: const Color(0xFF7C3AED),
                    fontWeight: FontWeight.w700,
                    fontSize: isSmall ? 14 : 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
