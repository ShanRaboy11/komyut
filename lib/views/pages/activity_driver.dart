import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import 'wallet_driver.dart';
import 'trips_driver.dart';
import 'operatorlist_driver.dart';
import '../services/driver_dashboard.dart';

class _ActivityHub extends StatefulWidget {
  const _ActivityHub();

  @override
  State<_ActivityHub> createState() => _ActivityHubState();
}

class _ActivityHubState extends State<_ActivityHub> {
  final DriverDashboardService _service = DriverDashboardService();
  bool _loading = true;
  bool _hasOperator = false;

  @override
  void initState() {
    super.initState();
    _loadDriverInfo();
  }

  Future<void> _loadDriverInfo() async {
    try {
      final info = await _service.getDriverVehicleInfo();
      // If driverData contains operator_name or routes/operator data, treat as having operator
      final operatorName = info['operator_name'] as String?;
      setState(() {
        _hasOperator = operatorName != null && operatorName.trim().isNotEmpty;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _hasOperator = false;
        _loading = false;
      });
    }
  }

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
            const SizedBox(height: 16),
            // Join an Operator: displayed only when driver has NO operator.
            if (_loading || !_hasOperator) ...[
              _buildOptionCard(
                context: context,
                icon: Symbols.handshake_rounded,
                title: 'Join an Operator',
                subtitle: _loading
                    ? 'Checking operator status...'
                    : 'Find and apply to your preferred transport operator.',
                onTap: (_loading || _hasOperator)
                    ? () {}
                    : () {
                        Navigator.of(context).pushNamed('/operator_list');
                      },
              ),
              const SizedBox(height: 16),
            ],
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
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

class DriverActivityPage extends StatelessWidget {
  const DriverActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      initialRoute: '/',
      onGenerateRoute: (settings) {
        late Widget page;
        switch (settings.name) {
          case '/wallet':
            page = const DriverWalletPage();
            break;
          case '/trip_history':
            page = const DriverTripHistoryPage();
            break;
          case '/operator_list':
            page = const OperatorListPage();
            break;
          case '/':
          default:
            page = const _ActivityHub();
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
