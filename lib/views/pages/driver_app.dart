import 'package:flutter/material.dart';
import '../widgets/role_navbar_wrapper.dart';
import './home_driver.dart'; 
import './placeholders.dart';
import './profile.dart';
import './notification_commuter.dart';

class DriverApp extends StatelessWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DriverNavBarWrapper(
      homePage: DriverDashboardNav(), 
      activityPage: DriverActivityPage(),
      feedbackPage: DriverFeedbackPage(),
      notificationsPage: NotificationPage(),
      profilePage: ProfilePage(),
    );
  }
}