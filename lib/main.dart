import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'views/providers/registration_provider.dart';
import 'views/providers/auth_provider.dart';
import 'views/providers/wallet_provider.dart';
import 'views/providers/commuter_dashboard.dart';
import 'views/providers/driver_dashboard.dart';
import 'views/providers/operator_dashboard.dart';
import 'views/providers/trips.dart';
import 'views/providers/driver_trip.dart';

import 'views/pages/landingpage.dart';
import 'views/pages/admin_app.dart';
import 'views/pages/commuter_app.dart';
import 'views/pages/driver_app.dart';
import 'views/pages/operator_app.dart';

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
        
        // Dashboard providers - keep them here for now
        // They will only fetch data when the user's role matches
        ChangeNotifierProvider(create: (_) => CommuterDashboardProvider()),
        ChangeNotifierProvider(create: (_) => DriverDashboardProvider()),
        ChangeNotifierProvider(create: (_) => OperatorDashboardProvider()),
        
        // Stream provider for auth state
        StreamProvider<User?>(
          create: (_) => Supabase.instance.client.auth.onAuthStateChange.map(
            (data) => data.session?.user,
          ),
          initialData: Supabase.instance.client.auth.currentUser,
        ),
      ],
      child: MaterialApp(
        title: 'KOMYUT',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.purple),
        // Start with AuthStateHandler
        home: const AuthStateHandler(),
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

/// Handles authentication state and routes to appropriate page
class AuthStateHandler extends StatefulWidget {
  const AuthStateHandler({Key? key}) : super(key: key);

  @override
  State<AuthStateHandler> createState() => _AuthStateHandlerState();
}

class _AuthStateHandlerState extends State<AuthStateHandler> {
  bool _isLoading = true;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
    
    // Listen to auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        _checkAuthState();
      } else if (event == AuthChangeEvent.signedOut) {
        if (mounted) {
          setState(() {
            _userRole = null;
            _isLoading = false;
          });
        }
      }
    });
  }

  Future<void> _checkAuthState() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      
      if (user == null) {
        if (mounted) {
          setState(() {
            _userRole = null;
            _isLoading = false;
          });
        }
        return;
      }

      // Fetch user role
      final response = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('user_id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _userRole = response['role'] as String?;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error checking auth state: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Not logged in - show landing page
    if (_userRole == null) {
      return const LandingPage();
    }

    // Logged in - show appropriate dashboard
    switch (_userRole!.toLowerCase()) {
      case 'commuter':
        return const CommuterApp();
      case 'driver':
        return const DriverApp();
      case 'operator':
        return const OperatorApp();
      case 'admin':
        return const AdminApp();
      default:
        return const LandingPage();
    }
  }
}