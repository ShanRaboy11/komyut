import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TripDetailsCard extends StatelessWidget {
  final String mapImage;
  final String distance;
  final String routeCode;
  final String from;
  final String fromTime;
  final String to;
  final String toTime;

  const TripDetailsCard({
    super.key,
    required this.mapImage,
    required this.distance,
    required this.routeCode,
    required this.from,
    required this.fromTime,
    required this.to,
    required this.toTime,
  });

  final gradientColors = const [
    Color(0xFFB945AA),
    Color(0xFF8E4CB6),
    Color(0xFF5B53C2),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF8E4CB6), width: 1.5),
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Map
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.asset(
              mapImage,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(height: 15),
          // Distance + Code
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Distance",
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  "Route Code",
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.only(left: 20, right: 20, bottom: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  distance,
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  routeCode,
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF9C6BFF),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Divider(color: Colors.grey[300], height: 1, thickness: 1),
          ),

          // Route Details
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStop(
                  context,
                  label: from,
                  time: fromTime,
                  isLast: false,
                  width: 0,
                ),
                _buildStop(
                  context,
                  label: to,
                  time: toTime,
                  isLast: true,
                  width: 0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStop(
    BuildContext context, { // Optional full custom decoration
    required String label,
    required String time,
    required bool isLast,
    required double width,
  }) {
    final gradientColors = const [
      Color(0xFFB945AA),
      Color(0xFF8E4CB6),
      Color(0xFF5B53C2),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon + Line
        Column(
          children: [
            Container(
              padding: EdgeInsets.all(isLast ? 2 : 5),
              margin: EdgeInsets.only(left: isLast ? 1 : 0, top: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: gradientColors,
                ),
                shape: BoxShape.circle,
              ),
              child: Container(
                width: isLast ? 14 : 10, // dynamic inner size
                height: isLast ? 14 : 10,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            if (!isLast)
              Column(
                children: List.generate(6, (index) {
                  return Container(
                    width: 2,
                    height: 5, // dash length
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: gradientColors,
                      ),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  );
                }),
              ),
          ],
        ),

        SizedBox(width: 20),

        // Text
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              time,
              style: GoogleFonts.nunito(
                fontSize: 16,
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
