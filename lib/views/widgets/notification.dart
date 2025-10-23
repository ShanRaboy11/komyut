import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class NotificationCard extends StatelessWidget {
  final String variant; // 'trips','wallet','rewards','alert','general'
  final String description;
  final String timeOrDate;
  final bool isRead;
  final VoidCallback? onTap;

  const NotificationCard({
    super.key,
    required this.variant,
    required this.description,
    required this.timeOrDate,
    this.isRead = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // primary border color
    final Color borderColor = const Color(0xFF8E4CB6);

    final Map<String, Map<String, dynamic>> variants = {
      'trips': {
        'bgColor': const Color(0xFFF0D3FF),
        'icon': Symbols.directions_bus_rounded,
        'iconColor': const Color(0xFF8E4CB6),
      },
      'wallet': {
        'bgColor': const Color(0xFFD8FCCA),
        'icon': Symbols.account_balance_wallet,
        'iconColor': const Color(0xFF3DC863),
      },
      'rewards': {
        'bgColor': const Color(0xFFFEFCD6),
        'icon': Symbols.featured_seasonal_and_gifts_rounded,
        'iconColor': const Color(0xFFB3A11B),
      },
      'alert': {
        'bgColor': const Color(0xFFF7B4AE),
        'icon': Symbols.report_rounded,
        'iconColor': const Color(0xFFFF1400),
      },
      'general': {
        'bgColor': const Color(0xFFD8E3FE),
        'icon': Symbols.notifications_active_rounded,
        'iconColor': const Color(0xFF3F63F6),
      },
    };

    final selected = variants[variant.toLowerCase()] ?? variants['general']!;
    final Color cardColor = isRead ? Colors.transparent : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: cardColor,
          border: Border.all(color: borderColor, width: 1.0),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon circle
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected['bgColor'],
                shape: BoxShape.circle,
              ),
              child: Icon(
                selected['icon'] as IconData,
                color: selected['iconColor'] as Color,
                size: 22,
              ),
            ),

            const SizedBox(width: 15),

            // Texts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: isRead ? FontWeight.w400 : FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    timeOrDate,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: Colors.grey[600],
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
