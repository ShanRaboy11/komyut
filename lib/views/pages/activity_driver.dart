import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import 'wallet_driver.dart';
//import 'driver_trip_history_page.dart';

/// This is the main widget for the "Activity" tab.
/// It IS a Navigator, which allows it to handle its own sub-navigation.
class DriverActivityPage extends StatelessWidget {
  const DriverActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      initialRoute: '/', // The initial route shows the Hub UI
      onGenerateRoute: (settings) {
        late Widget page;
        switch (settings.name) {
          case '/wallet':
            page = const DriverWalletPage();
            break;
          case '/trip_history':
            //page = const DriverTripHistoryPage();
            break;
          case '/':
          default:
            page = const _ActivityHub(); // The UI with the buttons
            break;
        }
        return MaterialPageRoute(
          builder: (context) => page,
          settings: settings,
        );
      },
    );
  }
}

/// This is the private UI widget for the Hub.
/// It's the first thing the DriverActivityPage's navigator shows.
class _ActivityHub extends StatelessWidget {
  const _ActivityHub();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FF),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Activity',
          style: GoogleFonts.manrope(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildOptionCard(
              context: context,
              icon: Symbols.account_balance_wallet_rounded,
              title: 'Wallet',
              subtitle: 'View earnings, balance, and make remittances.',
              onTap: () {
                // This call finds the Navigator inside DriverActivityPage
                // and pushes the '/wallet' route.
                Navigator.of(context).pushNamed('/wallet');
              },
            ),
            const SizedBox(height: 16),
            _buildOptionCard(
              context: context,
              icon: Symbols.route,
              title: 'Trip History',
              subtitle: 'Browse your completed trips and earnings per ride.',
              onTap: () {
                Navigator.of(context).pushNamed('/trip_history');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final brandColor = const Color(0xFF8E4CB6);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: brandColor.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: brandColor.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: brandColor, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
