import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/role_navbar_wrapper.dart';
import '../providers/wallet_provider.dart';

import 'home_operator.dart';
import 'report_operator.dart';
import 'placeholders.dart';
import 'profile.dart';
import 'driver_operator.dart';

import 'wallet_history_operator.dart';
import 'co_operator.dart';
import 'co_operator_confirm.dart';
import 'co_operator_instructions.dart';
import 'co_operator_success.dart';

class OperatorApp extends StatelessWidget {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  const OperatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      initialRoute: '/',
      onGenerateRoute: _operatorRouter,
    );
  }

  Route<dynamic> _operatorRouter(RouteSettings settings) {
    late Widget page;

    switch (settings.name) {
      case '/':
        page = const OperatorNavBarWrapper(
          homePage: OperatorDashboardNav(),
          driversPage: OperatorDriversPage(),
          transactionsPage: OperatorTransactionsPage(),
          reportsPage: OperatorReportsPage(),
          profilePage: ProfilePage(),
        );
        break;

      case '/wallet_history':
        page = ChangeNotifierProvider(
          create: (_) => OperatorWalletProvider(),
          child: const WalletHistoryOperatorPage(),
        );
        break;

      case '/cash_out':
        page = ChangeNotifierProvider(
          create: (_) => OperatorWalletProvider(),
          child: const OperatorCashOutPage(),
        );
        break;

      case '/cash_out_confirm':
        final amount = settings.arguments as String;
        page = ChangeNotifierProvider(
          create: (_) => OperatorWalletProvider(),
          child: OperatorCashOutConfirmPage(amount: amount),
        );
        break;

      case '/cash_out_instructions':
        final args = settings.arguments as Map<String, dynamic>;
        page = ChangeNotifierProvider(
          create: (_) => OperatorWalletProvider(),
          child: OperatorCashOutInstructionsPage(transaction: args),
        );
        break;

      case '/cash_out_success':
        page = const OperatorCashOutSuccessPage();
        break;

      default:
        page = const OperatorNavBarWrapper(
          homePage: OperatorDashboardNav(),
          driversPage: OperatorDriversPage(),
          transactionsPage: OperatorTransactionsPage(),
          reportsPage: OperatorReportsPage(),
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
