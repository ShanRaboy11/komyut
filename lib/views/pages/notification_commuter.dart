// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/notification.dart';
import '../services/notifications.dart';
import '../models/notification.dart';
import 'tripdetails_commuter.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => NotificationPageState();
}

class NotificationPageState extends State<NotificationPage> {
  final Color primary1 = const Color(0xFF9C6BFF);
  final List<String> tabs = ['Trips', 'Wallet', 'Others'];
  String activeTab = 'Trips';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).fetchNotifications();
    });
  }

  // Grouping Logic
  String _getSection(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final check = DateTime(date.year, date.month, date.day);

    if (check == today) {
      return 'Today';
    }
    if (check == yesterday) {
      return 'Yesterday';
    }
    return 'Older';
  }

  // Time Display Logic
  String _getDisplayTime(NotifItem item, String section) {
    if (item.isLocal) {
      return item.timeOrDate;
    }
    if (section == 'Today') {
      return DateFormat('hh:mm a').format(item.sortDate);
    }
    if (section == 'Yesterday') {
      return 'Yesterday';
    }
    return DateFormat('MMM dd, yyyy').format(item.sortDate);
  }

  // Tap Logic: Mark Read + Navigate
  void _onTapNotif(NotifItem item) async {
    // 1. Mark Read Immediately
    if (!item.isRead) {
      Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).markAsRead(item.id);
    }

    // 2. Navigate if Trip
    if (item.variant == 'trips' && item.payload != null) {
      final p = item.payload!;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TripDetailsPage(
            tripId: item.tripId,
            date: p['date_str'] ?? '',
            time: p['time_str'] ?? '',
            status: p['status'] ?? 'ongoing',
            from: "Loading...",
            to: "...",
            tripCode: "...",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 420;

    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        final all = provider.notifications;

        // Filter Tabs
        List<NotifItem> filtered;
        if (activeTab == 'Trips') {
          filtered = all.where((n) => n.variant == 'trips').toList();
        } else if (activeTab == 'Wallet') {
          filtered = all.where((n) => n.variant == 'wallet').toList();
        } else {
          filtered = all
              .where((n) => n.variant != 'trips' && n.variant != 'wallet')
              .toList();
        }

        // Group by Date
        final Map<String, List<NotifItem>> grouped = {};
        for (var n in filtered) {
          String section;
          if (n.isLocal) {
            if (n.timeOrDate.contains('Today') ||
                n.timeOrDate.contains('AM') ||
                n.timeOrDate.contains('PM')) {
              section = 'Today';
            } else if (n.timeOrDate.contains('Yesterday')) {
              section = 'Yesterday';
            } else {
              section = 'Older';
            }
          } else {
            section = _getSection(n.sortDate);
          }
          grouped.putIfAbsent(section, () => []).add(n);
        }

        final hasUnread = filtered.any((n) => !n.isRead);

        return Scaffold(
          backgroundColor: const Color(0xFFF7F4FF),
          floatingActionButton: hasUnread
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: FloatingActionButton.extended(
                    backgroundColor: primary1,
                    onPressed: () => provider.markAllAsRead(filtered),
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
                  Text(
                    'Notification',
                    style: GoogleFonts.manrope(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),

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

                  Expanded(
                    child: provider.isLoading
                        ? Center(
                            child: CircularProgressIndicator(color: primary1),
                          )
                        : RefreshIndicator(
                            onRefresh: provider.fetchNotifications,
                            color: primary1,
                            child: SingleChildScrollView(
                              key: ValueKey<String>(activeTab),
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (grouped.containsKey('Today')) ...[
                                    _sectionTitle('TODAY'),
                                    const SizedBox(height: 5),
                                    _buildSectionList(
                                      grouped['Today']!,
                                      'Today',
                                    ),
                                    const SizedBox(height: 18),
                                  ],
                                  if (grouped.containsKey('Yesterday')) ...[
                                    _sectionTitle('YESTERDAY'),
                                    const SizedBox(height: 5),
                                    _buildSectionList(
                                      grouped['Yesterday']!,
                                      'Yesterday',
                                    ),
                                    const SizedBox(height: 18),
                                  ],
                                  if (grouped.containsKey('Older')) ...[
                                    _sectionTitle('OLDER'),
                                    const SizedBox(height: 5),
                                    _buildSectionList(
                                      grouped['Older']!,
                                      'Older',
                                      olderMode: true,
                                    ),
                                    const SizedBox(height: 18),
                                  ],
                                  const SizedBox(height: 50),
                                  if (filtered.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 50),
                                      child: Center(
                                        child: Text(
                                          "No notifications",
                                          style: GoogleFonts.nunito(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
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
      },
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

  Widget _buildSectionList(
    List<NotifItem> items,
    String section, {
    bool olderMode = false,
  }) {
    return Column(
      children: items.map((n) {
        return Padding(
          key: ValueKey(n.virtualId), // Use Virtual ID for uniqueness
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: NotificationCard(
            variant: n.variant == 'alert' ? 'alert' : n.variant,
            description: n.title, // Strict Title
            timeOrDate: _getDisplayTime(n, section),
            isRead: n.isRead,
            onTap: () => _onTapNotif(n),
          ),
        );
      }).toList(),
    );
  }
}
