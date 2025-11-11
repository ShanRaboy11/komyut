import 'package:flutter/material.dart';
import '../widgets/role_navbar_wrapper.dart';
import './home_operator.dart';
import './report_operator.dart';
import './placeholders.dart';
import './profile.dart';
import 'driver_operator.dart';

class OperatorApp extends StatelessWidget {
  const OperatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return OperatorNavBarWrapper(
      homePage: OperatorDashboardNav(),
      driversPage: AnalyticsCard(),
      transactionsPage: OperatorTransactionsPage(),
      reportsPage: OperatorReportsPage(),
      profilePage: ProfilePage(),
    );
  }
}
