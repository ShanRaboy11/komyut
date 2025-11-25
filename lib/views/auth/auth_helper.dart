import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Helper functions for authentication
class AuthHelper {
  /// Logout the current user and navigate to landing page
  static Future<void> logout(BuildContext context) async {
    try {
      debugPrint('🔄 Logging out user...');
      
      // Sign out from Supabase
      await Supabase.instance.client.auth.signOut();
      
      debugPrint('✅ User logged out successfully');
      
      // Navigate to landing page and remove all previous routes
      // The AuthWrapper will automatically detect the auth state change
      // and show the LandingPage
      if (context.mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/landing',
            (route) => false,
          );
        });
      }
    } catch (e) {
      debugPrint('❌ Logout error: $e');
      
      // Show error message to user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Get current user role
  static Future<String?> getCurrentUserRole() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      
      if (user == null) {
        return null;
      }

      final response = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('user_id', user.id)
          .single();

      return response['role'] as String?;
    } catch (e) {
      debugPrint('❌ Error fetching user role: $e');
      return null;
    }
  }

  /// Check if current user has a specific role
  static Future<bool> hasRole(String role) async {
    final currentRole = await getCurrentUserRole();
    return currentRole?.toLowerCase() == role.toLowerCase();
  }

  /// Get current user ID
  static String? getCurrentUserId() {
    return Supabase.instance.client.auth.currentUser?.id;
  }

  /// Check if user is logged in
  static bool isLoggedIn() {
    return Supabase.instance.client.auth.currentUser != null;
  }
}