import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/admin_verification.dart';

import 'personalinfo_commuter.dart';
import 'personalinfo_driver.dart';
import 'personalinfo_operator.dart';
import 'aboutus.dart';
import 'privacypolicy.dart';

/// Helper class for authentication operations
class AuthHelper {
  /// Logout the current user and navigate to landing page
  static Future<void> logout(BuildContext context) async {
    try {
      debugPrint('🔄 Logging out user...');

      // Sign out from Supabase
      await Supabase.instance.client.auth.signOut();

      debugPrint('✅ User logged out successfully');

      // Navigate to landing page and remove all previous routes
      if (context.mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/landing', (route) => false);
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

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No user logged in');
      }

      // Fetch profile data
      final response = await _supabase
          .from('profiles')
          .select('''
            *, 
            commuters(*), 
            drivers(*, operators(company_name), routes(code, name)), 
            operators(*)
          ''')
          .eq('user_id', userId)
          .single();

      setState(() {
        _profileData = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getUserDisplayName() {
    if (_profileData == null) return '';
    return '${_profileData!['first_name'] ?? ''} ${_profileData!['last_name'] ?? ''}';
  }

  String _getUserId() {
    if (_profileData == null) return '';
    return _profileData!['id']?.toString().substring(0, 8) ?? '';
  }

  String _getUserRole() {
    if (_profileData == null) return '';
    final role = _profileData!['role'] ?? '';
    return role.toString().toUpperCase();
  }

  Widget _getPersonalInfoPage() {
    if (_profileData == null) return const SizedBox();

    final role = _profileData!['role'];
    switch (role) {
      case 'commuter':
        return PersonalInfoCommuterPage(profileData: _profileData!);
      case 'driver':
        return PersonalInfoDriverPage(profileData: _profileData!);
      case 'operator':
        return PersonalInfoOperatorPage(profileData: _profileData!);
      default:
        return PersonalInfoCommuterPage(profileData: _profileData!);
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Logout',
              style: GoogleFonts.manrope(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF2D3436),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to logout?',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: const Color(0xFF636E72),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF636E72),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF5350),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;

    // Show blocking progress dialog (use root navigator)
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const CircularProgressIndicator(),
        ),
      ),
    );

    var signOutSuccess = false;
    try {
      await context.read<AuthProvider>().signOut();
      signOutSuccess = true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      // Dismiss the progress dialog before navigation
      if (mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
      }
    }

    if (signOutSuccess && mounted) {
      try {
        context.read<AdminVerificationProvider>().clearCurrentDetail();
      } catch (_) {}

      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/landing', (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F4FF),
        body: Center(
          child: CircularProgressIndicator(color: const Color(0xFF8E4CB6)),
        ),
      );
    }

    if (_errorMessage != null || _profileData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F4FF),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Failed to load profile',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage ?? 'Unknown error',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadProfileData, child: Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                // --- Title ---
                Text(
                  "Profile",
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 30),

                // --- Profile Header ---
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SvgPicture.asset(
                          "assets/images/profile_holder.svg",
                          width: 90,
                          height: 90,
                        ),
                        SvgPicture.asset(
                          "assets/images/profile.svg",
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ],
                    ),
                    const SizedBox(width: 30),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getUserDisplayName(),
                            style: GoogleFonts.manrope(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getUserRole(),
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: const Color(0xFF8E4CB6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            "ID: ${_getUserId()}",
                            style: GoogleFonts.nunito(
                              fontSize: 10,
                              color: Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // --- Cards ---
                _ProfileCard(
                  icon: Icons.person_outline,
                  title: "Personal Info",
                  subtitle: "Manage your personal details",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => _getPersonalInfoPage(),
                      ),
                    ).then((_) => _loadProfileData()); // Refresh on return
                  },
                ),
                const SizedBox(height: 16),
                _ProfileCard(
                  icon: Icons.info_outline,
                  title: "About Us",
                  subtitle: "About Komyut",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AboutPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _ProfileCard(
                  icon: Icons.privacy_tip_outlined,
                  title: "Privacy Policy",
                  subtitle: "Privacy terms and conditions",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacyPolicyPage(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 150),
              ],
            ),
          ),

          // --- Logout Button at the Bottom ---
          Positioned(
            bottom: 110,
            left: width * 0.07,
            right: width * 0.07,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  elevation: 3,
                  shadowColor: Colors.redAccent.withValues(alpha: 0.2),
                ),
                child: Text(
                  "Log out",
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Reusable Card ---
class _ProfileCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: 12,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF8E4CB6), width: 1),
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFF9F7FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF8E4CB6), size: 30),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: const Color.fromARGB(212, 0, 0, 0),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
