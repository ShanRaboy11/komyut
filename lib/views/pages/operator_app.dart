import 'package:flutter/material.dart';
import '../widgets/role_navbar_wrapper.dart';
import './home_operator.dart'; 
import './placeholders.dart';
import './personalinfo_operator.dart';

class OperatorApp extends StatelessWidget {
  const OperatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return OperatorNavBarWrapper(
      homePage: OperatorDashboardNav(), 
      driversPage: OperatorDriversPage(),
      transactionsPage: OperatorTransactionsPage(),
      reportsPage: OperatorReportsPage(),
      profilePage: PersonalInfoPage(),
    );
  }
}