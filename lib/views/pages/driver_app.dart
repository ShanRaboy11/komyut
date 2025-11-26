import 'package:flutter/material.dart';
import '../widgets/role_navbar_wrapper.dart';

import 'home_driver.dart';
import 'activity_driver.dart';
import 'profile.dart';
import 'notification_driver.dart'; 
import 'feedback_driver.dart';

import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../services/driver_notifications.dart';

import 'wallet_history_driver.dart';
import 'remit_driver.dart';
import 'remit_confirm.dart';
import 'remit_success.dart';

import 'co_driver.dart';
import 'co_driver_confirm.dart';
import 'co_driver_instructions.dart';
import 'co_driver_success.dart';

class DriverApp extends StatelessWidget {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  const DriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DriverWalletProvider()),
        ChangeNotifierProvider(create: (_) => NotificationDriverProvider()),
      ],
      child: Navigator(
        key: navigatorKey,
        initialRoute: '/',
        onGenerateRoute: _driverRouter,
      ),
    );
  }

  Route<dynamic> _driverRouter(RouteSettings settings) {
    late Widget page;

    switch (settings.name) {
      case '/':
        page = const DriverNavBarWrapper(
          homePage: DriverDashboardNav(),
          activityPage: DriverActivityPage(),
          feedbackPage: DriverFeedbackPage(),
          notificationsPage:
              NotificationDriverPage(),
          profilePage: ProfilePage(),
        );
        break;

      case '/driver_history':
        page = const WalletHistoryDriverPage();
        break;

      case '/remit':
        page = const RemitPageDriver();
        break;

      case '/remit_confirmation':
        final args = settings.arguments as Map<String, dynamic>;
        page = RemitConfirmationPage(
          amount: args['amount'] as String,
          operatorName: args['operatorName'] as String,
        );
        break;

      case '/remit_success':
        page = const RemittanceSuccessPage();
        break;

      case '/cash_out':
        page = const DriverCashOutPage();
        break;

      case '/cash_out_confirmation':
        final args = settings.arguments as String;
        page = DriverCashOutConfirmPage(amount: args);
        break;

      case '/cash_out_instructions':
        final args = settings.arguments as Map<String, dynamic>;
        page = DriverCashOutInstructionsPage(transaction: args);
        break;

      case '/cash_out_success':
        page = const DriverCashOutSuccessPage();
        break;

      default:
        page = const DriverNavBarWrapper(
          homePage: DriverDashboardNav(),
          activityPage: DriverActivityPage(),
          feedbackPage: DriverFeedbackPage(),
          notificationsPage:
              NotificationDriverPage(),
          profilePage: ProfilePage(),
        );
        break;
    }

    return MaterialPageRoute<dynamic>(
      builder: (context) => page,
      settings: settings,
    );
  }
}
