import 'package:flutter/material.dart';
import 'views/pages/landingpage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'views/providers/registration_provider.dart';
import 'views/services/auth_provider.dart';

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
      ),
    );
  }
}

class NavBarCommuter extends StatelessWidget {
  const NavBarCommuter({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBottomNavBar(
      pages: const [
        Center(child: Text("🏠 Home")),
        Center(child: Text("📋 Activity")),
        Center(child: Text("✍️ QR Scan")),
        Center(child: Text("🔔 Notifications")),
        Center(child: Text("👤 Profile")),
      ],
      items: const [
        NavItem(icon: Icons.home_rounded, label: 'Home'),
        NavItem(icon: Symbols.overview_rounded, label: 'Activity'),
        NavItem(icon: Symbols.qr_code_scanner_rounded, label: 'QR Scan'),
        NavItem(icon: Icons.notifications_rounded, label: 'Notification'),
        NavItem(icon: Icons.person_rounded, label: 'Profile'),
      ],
    );
  }
}
