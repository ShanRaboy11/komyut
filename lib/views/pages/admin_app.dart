import 'package:flutter/material.dart';
import '../widgets/role_navbar_wrapper.dart';
import './home_admin.dart'; 
import './placeholders.dart';
import './admin_routes.dart';
import 'admin_verification.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminNavBarWrapper(
      homePage: AdminDashboardNav(), 
      verifiedPage: AdminVerifiedPage(),
      activityPage: AdminActivityPage(),
      reportsPage: AdminReportsPage(),
      routePage: AdminRoutesPage(), 
    );
  }
}