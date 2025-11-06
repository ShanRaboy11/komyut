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

import 'dw.dart';
import 'dw_payment_method.dart';
import 'dw_payment_source.dart';
import 'dw_confirm.dart';
import 'dw_success.dart';

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

      case '/digital_wallet':
        page = const DigitalWalletPage();
        break;
      case '/dw_payment_method':
        final args = settings.arguments as Map<String, String>;
        page = DwPaymentMethodPage(
          name: args['name']!,
          email: args['email']!,
          amount: args['amount']!,
        );
        break;
      case '/dw_payment_source':
        final args = settings.arguments as Map<String, String>;
        page = DwSourceSelectionPage(
          name: args['name']!,
          email: args['email']!,
          amount: args['amount']!,
          paymentMethod: args['paymentMethod']!,
        );
        break;
      case '/dw_confirmation':
        final args = settings.arguments as Map<String, String>;
        page = DwConfirmationPage(
          name: args['name']!,
          email: args['email']!,
          amount: args['amount']!,
          source: args['source']!,
          transactionCode: args['transactionCode']!,
        );
        break;
      case '/dw_success':
        page = const DwSuccessPage();
        break;

      // TODO: Add cases for '/redeem_tokens'

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
