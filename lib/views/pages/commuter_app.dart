import 'package:flutter/material.dart';
import '../widgets/role_navbar_wrapper.dart';

import 'home_commuter.dart';
import 'activity_commuter.dart';
import 'notification_commuter.dart';
import 'profile.dart';

import 'wallet_history_commuter.dart';

import 'otc.dart';
import 'otc_confirm.dart';
import 'otc_instructions.dart';
import 'otc_success.dart';

class CommuterApp extends StatelessWidget {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  const CommuterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      initialRoute: '/',
      onGenerateRoute: _commuterRouter,
    );
  }

  Route<dynamic> _commuterRouter(RouteSettings settings) {
    late Widget page;

    switch (settings.name) {
      case '/':
        page = const CommuterNavBarWrapper(
          homePage: CommuterDashboardNav(),
          activityPage: TripsPage(),
          notificationsPage: NotificationPage(),
          profilePage: ProfilePage(),
        );
        break;

      case '/history':
        final type = settings.arguments as HistoryType;
        page = TransactionHistoryPage(type: type);
        break;

      case '/otc':
        page = const OverTheCounterPage();
        break;
      case '/otc_confirmation':
        final amount = settings.arguments as String;
        page = OtcConfirmationPage(amount: amount);
        break;
      case '/otc_instructions':
        final transaction = settings.arguments as Map<String, dynamic>;
        page = OtcInstructionsPage(transaction: transaction);
        break;
      case '/payment_success':
        page = const PaymentSuccessPage();
        break;

      // TODO: Add cases for '/digital_wallet', '/redeem_tokens' etc. here

      default:
        page = const CommuterNavBarWrapper(
          homePage: CommuterDashboardNav(),
          activityPage: TripsPage(),
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
