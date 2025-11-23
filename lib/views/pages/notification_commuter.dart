// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/notification.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => NotificationPageState();
}

class NotificationPageState extends State<NotificationPage>
    with SingleTickerProviderStateMixin {
  void resetToDefault() {
    setState(() {
      activeTab = 'Trips';
      for (var n in allNotifications) {
        n.isRead = n.isRead;
      }
    });
  }

  final Color primary1 = const Color(0xFF9C6BFF);
  final List<String> tabs = ['Trips', 'Wallet', 'Others'];

  String activeTab = 'Trips';

  final List<_NotifItem> allNotifications = [
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
    _NotifItem(
      'trips',
      'Route updated for Line 5.',
      'Oct 10, 2025',
      'Older',
      true,
    ),
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
    _NotifItem(
      'rewards',
      'You earned 10 reward points!',
      'Oct 06, 2025',
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

    // Filter based on active tab
    List<_NotifItem> filtered;
    if (activeTab == 'Trips') {
      filtered = allNotifications.where((n) => n.variant == 'trips').toList();
    } else if (activeTab == 'Wallet') {
      filtered = allNotifications.where((n) => n.variant == 'wallet').toList();
    } else {
      filtered = allNotifications
          .where((n) => n.variant != 'trips' && n.variant != 'wallet')
          .toList();
    }

    final Map<String, List<_NotifItem>> grouped = {};
    for (var n in filtered) {
      grouped.putIfAbsent(n.section, () => []).add(n);
    }

    final hasUnread = filtered.any((n) => !n.isRead);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      floatingActionButton: hasUnread
          ? Padding(
              padding: const EdgeInsets.only(bottom: 100),
              child: FloatingActionButton.extended(
                backgroundColor: primary1,
                onPressed: () {
                  setState(() {
                    for (var n in filtered) {
                      n.isRead = true;
                    }
                  });
                },
                label: Row(
                  children: [
                    const Icon(Icons.done_all_rounded, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      "Mark all as read",
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Notification',
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              // Tabs with animated selection
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primary1.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: tabs
                      .map((t) => _buildPillTab(t, activeTab == t, isSmall))
                      .toList(),
                ),
              ),
              const SizedBox(height: 20),

              // AnimatedSwitcher for smooth tab change
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  layoutBuilder:
                      (Widget? currentChild, List<Widget> previousChildren) {
                        // This ensures widgets stack from top instead of center during switch
                        return Stack(
                          alignment: Alignment.topCenter,
                          children: <Widget>[
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        );
                      },
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.1, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                  child: SingleChildScrollView(
                    key: ValueKey<String>(activeTab),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (grouped.containsKey('Today')) ...[
                          _sectionTitle('TODAY'),
                          const SizedBox(height: 5),
                          _buildSectionList(grouped['Today']!),
                          const SizedBox(height: 18),
                        ],
                        if (grouped.containsKey('Yesterday')) ...[
                          _sectionTitle('YESTERDAY'),
                          const SizedBox(height: 5),
                          _buildSectionList(grouped['Yesterday']!),
                          const SizedBox(height: 18),
                        ],
                        if (grouped.containsKey('Older')) ...[
                          _sectionTitle('OLDER'),
                          const SizedBox(height: 5),
                          _buildSectionList(grouped['Older']!, olderMode: true),
                          const SizedBox(height: 18),
                        ],
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ),
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
          padding: EdgeInsets.symmetric(vertical: isSmall ? 10 : 12),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: active ? primary1 : Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
            child: Text(title),
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
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildSectionList(List<_NotifItem> items, {bool olderMode = false}) {
    return Column(
      children: items.map((n) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          child: Padding(
            key: ValueKey(n.isRead),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: NotificationCard(
              variant: n.variant,
              description: n.description,
              timeOrDate: n.timeOrDate,
              isRead: n.isRead,
              onTap: () {
                setState(() => n.isRead = !n.isRead);
              },
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _NotifItem {
  final String variant;
  final String description;
  final String timeOrDate;
  final String section;
  bool isRead;

  _NotifItem(
    this.variant,
    this.description,
    this.timeOrDate,
    this.section,
    this.isRead,
  );
}
