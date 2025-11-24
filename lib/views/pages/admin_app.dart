import 'package:flutter/material.dart';
import '../widgets/role_navbar_wrapper.dart';
import './home_admin.dart'; 
import './placeholders.dart';
import './admin_routes.dart';
import 'admin_verification.dart';
import 'admin_report.dart';

class AdminApp extends StatelessWidget {
  final int initialIndex;

  const AdminApp({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    return AdminNavBarWrapper(
      homePage: AdminDashboardNav(),
      verifiedPage: AdminVerifiedPage(),
      activityPage: AdminActivityPage(),
      reportsPage: AdminReportsPage(),
      routePage: AdminRoutesPage(),
      initialIndex: initialIndex,
    );
  }
}