import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/notification.dart';

import '../services/driver_notifications.dart';
import '../models/notification.dart';
import 'tripdetails_driver.dart';
import 'wallet_driver.dart'; // 1. IMPORT THE WALLET PAGE

class NotificationDriverPage extends StatefulWidget {
  const NotificationDriverPage({super.key});

  @override
  State<NotificationDriverPage> createState() => NotificationDriverPageState();
}

class NotificationDriverPageState extends State<NotificationDriverPage> {
  final Color primary1 = const Color(0xFF9C6BFF);
  final List<String> tabs = ['Trips', 'Wallet', 'Others'];
  String activeTab = 'Trips';

  @override
  void initState() {
    super.initState();
    debugPrint("🚀 NotificationDriverPage: initState called");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint("🚀 NotificationDriverPage: fetching notifications...");
      try {
        Provider.of<NotificationDriverProvider>(
          context,
          listen: false,
        ).fetchNotifications();
      } catch (e, stackTrace) {
        debugPrint("❌ Error calling fetchNotifications: $e");
        debugPrint("❌ Stack trace: $stackTrace");
      }
    });
  }

  String _getSection(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final check = DateTime(date.year, date.month, date.day);

    if (check == today) return 'Today';
    if (check == yesterday) return 'Yesterday';
    return 'Older';
  }

  String _getDisplayTime(NotifItem item, String section) {
    if (item.isLocal) return item.timeOrDate;
    if (section == 'Today') return DateFormat('hh:mm a').format(item.sortDate);
    if (section == 'Yesterday') return 'Yesterday';
    return DateFormat('MMM dd, yyyy').format(item.sortDate);
  }

  void _onTapNotif(NotifItem item) async {
    debugPrint("NotificationDriverPage: Tapped notification: ${item.id}");

    // Mark as read
    if (!item.isRead) {
      Provider.of<NotificationDriverProvider>(
        context,
        listen: false,
      ).markAsRead(item.id);
    }

    final payload = item.payload ?? {};

    // --- TRIPS ---
    if (item.variant == 'trips') {
      final String tripId = item.tripId;
      final String status = payload['status'] ?? 'ongoing';
      final String dateStr =
          payload['date_str'] ??
          DateFormat('MMM dd, yyyy').format(item.sortDate);
      final String timeStr =
          payload['time_str'] ?? DateFormat('hh:mm a').format(item.sortDate);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DriverTripDetailsPage(
            tripId: tripId,
            date: dateStr,
            time: timeStr,
            from: "Loading...",
            to: "...",
            tripCode: "Trip #$tripId",
            status: status,
          ),
        ),
      );
    }
    // --- WALLET ---
    else if (item.variant == 'wallet') {
      // 2. REDIRECT TO DRIVER WALLET PAGE
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DriverWalletPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 420;

    return Consumer<NotificationDriverProvider>(
      builder: (context, provider, child) {
        final all = provider.notifications;
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
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(left: 30, right: 30, top: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifications',
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
                    child: provider.isLoading && provider.notifications.isEmpty
                        ? Center(
                            child: CircularProgressIndicator(color: primary1),
                          )
                        : RefreshIndicator(
                            onRefresh: () => provider.fetchNotifications(),
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
                                  if (filtered.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 50),
                                      child: Center(
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.notifications_none_rounded,
                                              size: 64,
                                              color: Colors.grey[300],
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              provider.isLoading
                                                  ? "Checking..."
                                                  : "No notifications",
                                              style: GoogleFonts.nunito(
                                                color: Colors.grey,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 120),
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

  // ... (Rest of the widget methods: _buildPillTab, _sectionTitle, _buildSectionList remain unchanged)
  Widget _buildPillTab(String title, bool active, bool isSmall) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => activeTab = title);
        },
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
          key: ValueKey(n.virtualId),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: NotificationCard(
            variant: n.variant,
            description: n.title,
            timeOrDate: _getDisplayTime(n, section),
            isRead: n.isRead,
            onTap: () => _onTapNotif(n),
          ),
        );
      }).toList(),
    );
  }
}
