// lib/views/widgets/role_navbar_wrappers.dart
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import '../widgets/navbar.dart';

// ============= COMMUTER NAVBAR WRAPPER =============
class CommuterNavBarWrapper extends StatefulWidget {
  final Widget homePage;
  final Widget activityPage;
  final Widget qrScanPage;
  final Widget notificationsPage;
  final Widget profilePage;
  final int initialIndex;

  const CommuterNavBarWrapper({
    super.key,
    required this.homePage,
    required this.activityPage,
    required this.qrScanPage,
    required this.notificationsPage,
    required this.profilePage,
    this.initialIndex = 0,
  });

  @override
  State<CommuterNavBarWrapper> createState() => _CommuterNavBarWrapperState();
}

class _CommuterNavBarWrapperState extends State<CommuterNavBarWrapper> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBottomNavBar(
      pages: [
        widget.homePage,
        widget.activityPage,
        widget.qrScanPage,
        widget.notificationsPage,
        widget.profilePage,
      ],
      items: const [
        NavItem(icon: Icons.home_rounded, label: 'Home'),
        NavItem(icon: Symbols.overview_rounded, label: 'Activity'),
        NavItem(icon: Symbols.qr_code_scanner_rounded, label: 'QR Scan'),
        NavItem(icon: Icons.notifications_rounded, label: 'Notification'),
        NavItem(icon: Icons.person_rounded, label: 'Profile'),
      ],
      initialIndex: _currentIndex,
      onItemSelected: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
    );
  }
}

// ============= DRIVER NAVBAR WRAPPER =============
class DriverNavBarWrapper extends StatefulWidget {
  final Widget homePage;
  final Widget activityPage;
  final Widget feedbackPage;
  final Widget notificationsPage;
  final Widget profilePage;
  final int initialIndex;

  const DriverNavBarWrapper({
    super.key,
    required this.homePage,
    required this.activityPage,
    required this.feedbackPage,
    required this.notificationsPage,
    required this.profilePage,
    this.initialIndex = 0,
  });

  @override
  State<DriverNavBarWrapper> createState() => _DriverNavBarWrapperState();
}

class _DriverNavBarWrapperState extends State<DriverNavBarWrapper> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBottomNavBar(
      pages: [
        widget.homePage,
        widget.activityPage,
        widget.feedbackPage,
        widget.notificationsPage,
        widget.profilePage,
      ],
      items: const [
        NavItem(icon: Icons.home_rounded, label: 'Home'),
        NavItem(icon: Symbols.overview_rounded, label: 'Activity'),
        NavItem(icon: Symbols.rate_review_rounded, label: 'Feedback'),
        NavItem(icon: Icons.notifications_rounded, label: 'Notification'),
        NavItem(icon: Icons.person_rounded, label: 'Profile'),
      ],
      initialIndex: _currentIndex,
      onItemSelected: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
    );
  }
}

// ============= OPERATOR NAVBAR WRAPPER =============
class OperatorNavBarWrapper extends StatefulWidget {
  final Widget homePage;
  final Widget driversPage;
  final Widget transactionsPage;
  final Widget reportsPage;
  final Widget profilePage;
  final int initialIndex;

  const OperatorNavBarWrapper({
    super.key,
    required this.homePage,
    required this.driversPage,
    required this.transactionsPage,
    required this.reportsPage,
    required this.profilePage,
    this.initialIndex = 0,
  });

  @override
  State<OperatorNavBarWrapper> createState() => _OperatorNavBarWrapperState();
}

class _OperatorNavBarWrapperState extends State<OperatorNavBarWrapper> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBottomNavBar(
      pages: [
        widget.homePage,
        widget.driversPage,
        widget.transactionsPage,
        widget.reportsPage,
        widget.profilePage,
      ],
      items: const [
        NavItem(icon: Icons.home_rounded, label: 'Home'),
        NavItem(icon: Symbols.group, label: 'Drivers'),
        NavItem(icon: Symbols.receipt_long, label: 'Transactions'),
        NavItem(icon: Symbols.assessment, label: 'Reports'),
        NavItem(icon: Icons.person_rounded, label: 'Profile'),
      ],
      initialIndex: _currentIndex,
      onItemSelected: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
    );
  }
}

// ============= ADMIN NAVBAR WRAPPER =============
class AdminNavBarWrapper extends StatefulWidget {
  final Widget homePage;
  final Widget verifiedPage;
  final Widget activityPage;
  final Widget reportsPage;
  final int initialIndex;

  const AdminNavBarWrapper({
    super.key,
    required this.homePage,
    required this.verifiedPage,
    required this.activityPage,
    required this.reportsPage,
    this.initialIndex = 0,
  });

  @override
  State<AdminNavBarWrapper> createState() => _AdminNavBarWrapperState();
}

class _AdminNavBarWrapperState extends State<AdminNavBarWrapper> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBottomNavBar(
      pages: [
        widget.homePage,
        widget.verifiedPage,
        widget.activityPage,
        widget.reportsPage,
      ],
      items: const [
        NavItem(icon: Icons.home_rounded, label: 'Home'),
        NavItem(icon: Symbols.verified, label: 'Verified'),
        NavItem(icon: Symbols.overview_rounded, label: 'Activity'),
        NavItem(icon: Symbols.assessment, label: 'Reports'),
      ],
      initialIndex: _currentIndex,
      onItemSelected: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
    );
  }
}