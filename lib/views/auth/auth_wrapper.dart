import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/commuter_dashboard.dart';
import '../providers/driver_dashboard.dart';
import '../providers/operator_dashboard.dart';

import '../pages/landingpage.dart';
import '../pages/admin_app.dart';
import '../pages/commuter_app.dart';
import '../pages/driver_app.dart';
import '../pages/operator_app.dart';

/// AuthWrapper handles authentication state and creates role-specific providers
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String? _userRole;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeUser();
    
    // Listen to auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        _initializeUser();
      } else if (event == AuthChangeEvent.signedOut) {
        setState(() {
          _userRole = null;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _initializeUser() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      
      if (user == null) {
        setState(() {
          _userRole = null;
          _isLoading = false;
        });
        return;
      }

      debugPrint('🔍 Fetching role for user: ${user.id}');

      // Fetch user role using user_id (not profile_id)
      final response = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('user_id', user.id)
          .single();

      final role = response['role'] as String?;
      debugPrint('✅ User role fetched (using user_id): $role');

      setState(() {
        _userRole = role;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error fetching user role: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show error if any
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeUser,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Watch auth state from provider
    final user = context.watch<User?>();

    // User not logged in - show landing page
    if (user == null || _userRole == null) {
      return const LandingPage();
    }

    // User logged in - wrap dashboard with role-specific providers
    debugPrint('🏠 Building dashboard for role: $_userRole');
    return _buildRoleBasedApp(_userRole!);
  }

  Widget _buildRoleBasedApp(String role) {
    // Create providers based on user role
    switch (role.toLowerCase()) {
      case 'commuter':
        return ChangeNotifierProvider(
          create: (_) => CommuterDashboardProvider(),
          child: const CommuterApp(),
        );

      case 'driver':
        return ChangeNotifierProvider(
          create: (_) => DriverDashboardProvider(),
          child: const DriverApp(),
        );

      case 'operator':
        return ChangeNotifierProvider(
          create: (_) => OperatorDashboardProvider(),
          child: const OperatorApp(),
        );

      case 'admin':
        // Admin might need access to all dashboards
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CommuterDashboardProvider()),
            ChangeNotifierProvider(create: (_) => DriverDashboardProvider()),
            ChangeNotifierProvider(create: (_) => OperatorDashboardProvider()),
          ],
          child: const AdminApp(),
        );

      default:
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning, size: 48, color: Colors.orange),
                const SizedBox(height: 16),
                Text('Unknown role: $role'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    await Supabase.instance.client.auth.signOut();
                  },
                  child: const Text('Logout'),
                ),
              ],
            ),
          ),
        );
    }
  }
}