import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/role_navbar_wrapper.dart';
import '../providers/operator_dashboard.dart';
import './home_operator.dart';
import './report_operator.dart';
import './placeholders.dart';
import './profile.dart';
import 'driver_operator.dart';

class OperatorApp extends StatelessWidget {
  const OperatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OperatorDashboardProvider(),
      child: OperatorNavBarWrapper(
        homePage: OperatorDashboardNav(),
        driversPage: OperatorDriversPage(),
        transactionsPage: OperatorTransactionsPage(),
        reportsPage: OperatorReportsPage(),
        profilePage: ProfilePage(),
      ),
    );
  }
}