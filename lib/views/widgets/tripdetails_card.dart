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
            color: const Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 4,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Map (support asset or network URL)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: mapImage.startsWith('http')
                ? Image.network(
                    mapImage,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  )
                : Image.asset(
                    mapImage,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(height: 15),
          // Distance + Code
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Distance",
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        distance,
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Route Code",
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        routeCode,
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF9C6BFF),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Divider(color: Colors.grey[300], height: 1, thickness: 1),
          ),

          // Route Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
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

        const SizedBox(width: 20),

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
                color: const Color.fromRGBO(0, 0, 0, 0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
