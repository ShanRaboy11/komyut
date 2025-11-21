import 'package:flutter/material.dart';
import '../widgets/role_navbar_wrapper.dart';

import 'home_driver.dart';
import 'activity_driver.dart';
import 'profile.dart';
import 'notification_commuter.dart';
import 'feedback_driver.dart';

import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';

import 'wallet_history_driver.dart';
import 'remit_driver.dart';
import 'remit_confirm.dart';
import 'remit_success.dart';

class DriverApp extends StatelessWidget {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  const DriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      initialRoute: '/',
      onGenerateRoute: _driverRouter,
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
          notificationsPage: NotificationPage(),
          profilePage: ProfilePage(),
        );
        break;

      case '/driver_history':
        final provider = settings.arguments as DriverWalletProvider;
        page = ChangeNotifierProvider.value(
          value: provider,
          child: const WalletHistoryDriverPage(),
        );
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

      default:
        page = const DriverNavBarWrapper(
          homePage: DriverDashboardNav(),
          activityPage: DriverActivityPage(),
          feedbackPage: DriverFeedbackPage(),
          notificationsPage: NotificationPage(),
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
