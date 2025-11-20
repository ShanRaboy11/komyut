import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/commuter_dashboard.dart';
import '../providers/driver_dashboard.dart';
import '../providers/operator_dashboard.dart';
import '../providers/wallet_provider.dart';
import '../providers/trips.dart';
import '../providers/driver_trip.dart';
import 'personalinfo_commuter.dart';
import 'personalinfo_driver.dart';
import 'personalinfo_operator.dart';
import 'aboutus.dart';
import 'privacypolicy.dart';
import 'landingpage.dart';

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
    // You can customize this based on which ID you want to show
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

  if (confirm == true && mounted) {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (context) => PopScope(
          canPop: false,
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF8E4CB6),
            ),
          ),
        ),
      );

      // CRITICAL: Sign out via AuthProvider to ensure app state clears
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signOut();

      // Clear local state immediately
      setState(() {
        _profileData = null;
        _isLoading = true;
        _errorMessage = null;
      });

      // Proactively clear common providers to avoid stale dashboard state
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

      if (mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const LandingPage(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F4FF),
        body: Center(
          child: CircularProgressIndicator(
            color: const Color(0xFF8E4CB6),
          ),
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
              ElevatedButton(
                onPressed: _loadProfileData,
                child: Text('Retry'),
              ),
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
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.07,
              vertical: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                // --- Title ---
                Text(
                  "Profile",
                  style: GoogleFonts.manrope(
                    fontSize: 28,
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
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getUserRole(),
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              color: const Color(0xFF8E4CB6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            "ID: ${_getUserId()}",
                            style: GoogleFonts.nunito(
                              fontSize: 14,
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
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 3,
                  shadowColor: Colors.redAccent.withValues(alpha: 0.2),
                ),
                child: Text(
                  "Log out",
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
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
          left: 30,
          right: 30,
          top: 20,
          bottom: 20,
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
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.nunito(
                      fontSize: 16,
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