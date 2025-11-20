import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/auth_provider.dart';
import '../providers/commuter_dashboard.dart';
import '../providers/driver_dashboard.dart';
import '../providers/operator_dashboard.dart';
import '../providers/wallet_provider.dart';
import '../providers/trips.dart';
import '../providers/driver_trip.dart';
import '../pages/landingpage.dart';

class AuthHelper {
  /// Show a confirmation dialog, sign out, clear common providers and
  /// navigate to the landing page. This centralizes logout behavior.
  static Future<void> logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirm Logout',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.nunito(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.manrope()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Logout',
              style: GoogleFonts.manrope(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    // Show a progress indicator while signing out
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signOut();

      // Clear other providers if present (swallow errors if provider isn't mounted)
      try {
        Provider.of<CommuterDashboardProvider>(context, listen: false).clearData();
      } catch (_) {}
      try {
        Provider.of<DriverDashboardProvider>(context, listen: false).clearData();
      } catch (_) {}
      try {
        Provider.of<OperatorDashboardProvider>(context, listen: false).clearData();
      } catch (_) {}
      try {
        Provider.of<TripsProvider>(context, listen: false).refresh();
      } catch (_) {}
      try {
        Provider.of<DriverTripProvider>(context, listen: false).refreshTrips();
      } catch (_) {}
      try {
        Provider.of<WalletProvider>(context, listen: false).fetchWalletData();
      } catch (_) {}

      if (!context.mounted) return;

      // Dismiss progress dialog
      try {
        Navigator.of(context, rootNavigator: true).pop();
      } catch (_) {}

      // Navigate to landing page and clear navigation stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LandingPage()),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      try {
        Navigator.of(context, rootNavigator: true).pop();
      } catch (_) {}

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  /// Simple helper to read the current user's role from the `profiles` table.
  static Future<String?> getCurrentUserRole() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return null;
      final res = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('user_id', userId)
          .maybeSingle();
      if (res == null) return null;
      return res['role'] as String?;
    } catch (_) {
      return null;
    }
  }
}
