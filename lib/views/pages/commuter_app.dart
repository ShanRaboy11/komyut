import 'package:flutter/material.dart';
import '../widgets/role_navbar_wrapper.dart';
import './home_commuter.dart'; 
import './qr_scan.dart';
import './placeholders.dart';
import './notification_commuter.dart';
import './profile.dart';

class CommuterApp extends StatelessWidget {
  const CommuterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CommuterNavBarWrapper(
      homePage: CommuterDashboardNav(),
      activityPage: CommuterActivityPage(),
      qrScanPage: QRScannerScreen(),
      notificationsPage: NotificationPage(),
      profilePage: CommuterProfilePage(),
    );
  }
}