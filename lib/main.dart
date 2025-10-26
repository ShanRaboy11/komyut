import 'package:flutter/material.dart';
import 'views/pages/landingpage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'views/providers/registration_provider.dart';
import 'views/services/auth_provider.dart';
import 'views/pages/admin_app.dart';
import 'views/pages/commuter_app.dart';
import 'views/pages/driver_app.dart';
import 'views/pages/operator_app.dart';
import 'views/pages/wallet.dart';
import 'views/pages/otc.dart';

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
          '/wallet': (context) => const WalletPage(),
          '/otc': (context) => const OverTheCounterPage(),
        },
      ),
    );
  }
}