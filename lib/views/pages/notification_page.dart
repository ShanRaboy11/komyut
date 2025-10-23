import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import '../widgets/notification.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // primary color
  final Color primary1 = const Color(0xFF9C6BFF);

  // tab options shown on top (matching screenshot)
  final List<String> tabs = ['Trips', 'Wallet', 'Others'];

  String activeTab = 'Trips';

  // Hardcoded sample data structure
  // section values: 'Today', 'Yesterday', 'Older' (Older uses date for timeOrDate)
  final List<_NotifItem> allNotifications = [
    // Trips - Today
    _NotifItem(
      'trips',
      'Your jeepney with Plate ABC-123 has started its trip.',
      '11:00 AM',
      'Today',
      false,
    ),
    _NotifItem('trips', 'Trip ended. :)', '11:00 AM', 'Today', true),
    _NotifItem(
      'trips',
      'Your jeepney with Plate ABC-123 has started its trip.',
      '09:30 AM',
      'Today',
      false,
    ),

    // Trips - Yesterday
    _NotifItem(
      'trips',
      'Driver has arrived at your stop.',
      'Yesterday',
      'Yesterday',
      true,
    ),
    _NotifItem(
      'trips',
      'Trip started for Plate ABC-200.',
      'Yesterday',
      'Yesterday',
      true,
    ),

    // Trips - Older
    _NotifItem(
      'trips',
      'Route updated for Line 5.',
      'Oct 10, 2025',
      'Older',
      true,
    ),

    // Wallet entries
    _NotifItem(
      'wallet',
      '₱50 credited to your wallet.',
      '10:45 AM',
      'Today',
      false,
    ),
    _NotifItem(
      'wallet',
      'Payment successful for trip ABC-123.',
      'Oct 12, 2025',
      'Older',
      true,
    ),

    // Others
    _NotifItem(
      'rewards',
      'You earned 10 reward points!',
      'Oct 09, 2025',
      'Older',
      true,
    ),
    _NotifItem(
      'alert',
      'Service update scheduled tomorrow.',
      'Oct 08, 2025',
      'Older',
      false,
    ),
    _NotifItem(
      'general',
      'New terms & conditions posted.',
      'Oct 05, 2025',
      'Older',
      true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 420;

    // Build filtered list depending on activeTab
    List<_NotifItem> filtered;
    if (activeTab == 'Trips') {
      filtered = allNotifications.where((n) => n.variant == 'trips').toList();
    } else if (activeTab == 'Wallet') {
      filtered = allNotifications.where((n) => n.variant == 'wallet').toList();
    } else {
      // Others -> show rewards, alert, general
      filtered = allNotifications
          .where((n) => n.variant != 'trips' && n.variant != 'wallet')
          .toList();
    }

    // Group into map by section label order: Today, Yesterday, Older
    final Map<String, List<_NotifItem>> grouped = {};
    for (var n in filtered) {
      grouped.putIfAbsent(n.section, () => []).add(n);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBFF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 14 : 20,
            vertical: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Notification',
                style: GoogleFonts.manrope(
                  fontSize: isSmall ? 22 : 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 18),

              // Pill-style tabs container (like screenshot)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primary1.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: tabs
                      .map((t) => _buildPillTab(t, activeTab == t, isSmall))
                      .toList(),
                ),
              ),

              const SizedBox(height: 20),

              // For each section in order: Today, Yesterday, Older
              if (grouped.containsKey('Today')) ...[
                _sectionTitle('TODAY'),
                const SizedBox(height: 8),
                _buildSectionList(grouped['Today']!),
                const SizedBox(height: 18),
              ],
              if (grouped.containsKey('Yesterday')) ...[
                _sectionTitle('YESTERDAY'),
                const SizedBox(height: 8),
                _buildSectionList(grouped['Yesterday']!),
                const SizedBox(height: 18),
              ],
              if (grouped.containsKey('Older')) ...[
                _sectionTitle('OLDER'),
                const SizedBox(height: 8),
                _buildSectionList(grouped['Older']!, olderMode: true),
                const SizedBox(height: 18),
              ],

              // spacer bottom
              SizedBox(height: isSmall ? 80 : 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillTab(String title, bool active, bool isSmall) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => activeTab = title),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: EdgeInsets.symmetric(vertical: isSmall ? 10 : 12),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: isSmall ? 13 : 14,
              color: active ? primary1 : Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.nunito(
        color: primary1,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildSectionList(List<_NotifItem> items, {bool olderMode = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        // subtle grouped container outline similar to screenshot
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: items.map((n) {
          return GestureDetector(
            onTap: () {
              // toggle read/unread instantly
              setState(() => n.isRead = !n.isRead);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: NotificationCard(
                variant: n.variant,
                description: n.description,
                timeOrDate: olderMode ? n.timeOrDate : n.timeOrDate,
                isRead: n.isRead,
                onTap: () {
                  // also toggle if inner onTap used
                  setState(() => n.isRead = !n.isRead);
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Helper local model
class _NotifItem {
  final String variant;
  final String description;
  final String timeOrDate; // either "11:00 AM" or "Oct 10, 2025"
  final String section; // 'Today', 'Yesterday', 'Older'
  bool isRead;

  _NotifItem(
    this.variant,
    this.description,
    this.timeOrDate,
    this.section,
    this.isRead,
  );
}
