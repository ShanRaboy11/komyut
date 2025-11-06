import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'views/providers/registration_provider.dart';
import 'views/providers/auth_provider.dart';
import 'views/providers/commuter_dashboard.dart';
import 'views/providers/driver_dashboard.dart';
import 'views/providers/operator_dashboard.dart';
import 'views/providers/wallet_provider.dart';

import 'views/pages/landingpage.dart';
import 'views/pages/admin_app.dart';
import 'views/pages/commuter_app.dart';
import 'views/pages/driver_app.dart';
import 'views/pages/operator_app.dart';

import 'views/pages/wallet_commuter.dart';
import 'views/pages/wallet_history_commuter.dart';

import 'views/pages/otc.dart';
import 'views/pages/otc_confirm.dart';
import 'views/pages/otc_instructions.dart';
import 'views/pages/otc_success.dart';

import 'views/pages/dw.dart';
import 'views/pages/dw_payment_method.dart';
import 'views/pages/dw_payment_source.dart';
import 'views/pages/dw_confirm.dart';
import 'views/pages/dw_success.dart';

import 'views/pages/wt.dart';
import 'views/pages/wt_confirm.dart';
import 'views/pages/wt_success.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("⚠️ No .env file found — skipping dotenv load.");
  }

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RegistrationProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CommuterDashboardProvider()),
        ChangeNotifierProvider(create: (_) => DriverDashboardProvider()),
        ChangeNotifierProvider(create: (_) => OperatorDashboardProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
      ],
      child: MaterialApp(
        title: 'KOMYUT',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.purple),
        home: const LandingPage(),

        routes: {
          '/home_admin': (context) => const AdminApp(),
          '/home_commuter': (context) => const CommuterApp(),
          '/home_driver': (context) => const DriverApp(),
          '/home_operator': (context) => const OperatorApp(),
          '/wallet': (context) => WalletPage(),

          '/otc': (context) => const OverTheCounterPage(),
          '/otc_confirmation': (context) {
            final amount = ModalRoute.of(context)!.settings.arguments as String;
            return OtcConfirmationPage(amount: amount);
          },
          '/otc_instructions': (context) {
            final transaction =
                ModalRoute.of(context)!.settings.arguments
                    as Map<String, dynamic>;
            return OtcInstructionsPage(transaction: transaction);
          },
          '/payment_success': (context) => const PaymentSuccessPage(),

          '/digital_wallet': (context) => const DigitalWalletPage(),
          '/dw_payment_method': (context) {
            final args =
                ModalRoute.of(context)!.settings.arguments
                    as Map<String, String>;
            return DwPaymentMethodPage(
              name: args['name']!,
              email: args['email']!,
              amount: args['amount']!,
            );
          },
          '/dw_payment_source': (context) {
            final args =
                ModalRoute.of(context)!.settings.arguments
                    as Map<String, String>;
            return DwSourceSelectionPage(
              name: args['name']!,
              email: args['email']!,
              amount: args['amount']!,
              paymentMethod: args['paymentMethod']!,
            );
          },
          '/dw_confirmation': (context) {
            final args =
                ModalRoute.of(context)!.settings.arguments
                    as Map<String, String>;
            return DwConfirmationPage(
              name: args['name']!,
              email: args['email']!,
              amount: args['amount']!,
              source: args['source']!,
              transactionCode: args['transactionCode']!,
            );
          },
          '/dw_success': (context) => const DwSuccessPage(),

          '/redeem_tokens': (context) => const RedeemTokensPage(),
          '/token_confirmation': (context) {
            final amount = ModalRoute.of(context)!.settings.arguments as String;
            return TokenConfirmationPage(tokenAmount: amount);
          },
          '/token_success': (context) => const TokenSuccessPage(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/history') {
            final args = settings.arguments as HistoryType;

            return MaterialPageRoute(
              builder: (context) {
                return TransactionHistoryPage(type: args);
              },
            );
          }
          return null;
        },
      ),
    );
  }
}
