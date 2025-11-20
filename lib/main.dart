import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'views/providers/registration_provider.dart';
import 'views/providers/auth_provider.dart';
import 'views/providers/wallet_provider.dart';
// Remove these imports - they'll be created conditionally
// import 'views/providers/commuter_dashboard.dart';
// import 'views/providers/driver_dashboard.dart';
// import 'views/providers/operator_dashboard.dart';
import 'views/providers/trips.dart';
import 'views/providers/driver_trip.dart';

import 'views/pages/landingpage.dart';
import 'views/pages/admin_app.dart';
import 'views/pages/commuter_app.dart';
import 'views/pages/driver_app.dart';
import 'views/pages/operator_app.dart';

// Import the new auth wrapper
import 'views/auth/auth_wrapper.dart';

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
        // Global providers that ALL users need
        ChangeNotifierProvider(create: (_) => RegistrationProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => TripsProvider()),
        ChangeNotifierProvider(create: (_) => DriverTripProvider()),
        
        // Stream provider for auth state
        StreamProvider<User?>(
          create: (_) => Supabase.instance.client.auth.onAuthStateChange.map(
            (data) => data.session?.user,
          ),
          initialData: Supabase.instance.client.auth.currentUser,
        ),
        
        // Dashboard providers will be created conditionally in AuthWrapper
        // based on user role - NOT here!
      ],
      child: MaterialApp(
        title: 'KOMYUT',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.purple),
        // Use AuthWrapper instead of LandingPage directly
        home: const AuthWrapper(),
        routes: {
          '/landing': (context) => const LandingPage(),
          '/home_admin': (context) => const AdminApp(),
          '/home_commuter': (context) => const CommuterApp(),
          '/home_driver': (context) => const DriverApp(),
          '/home_operator': (context) => const OperatorApp(),
        },
      ),
    );
  }
}