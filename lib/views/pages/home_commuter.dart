import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:komyut/views/pages/qr_scan.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';
import '../widgets/button.dart';
import '../widgets/navbar.dart';
import '../providers/commuter_dashboard.dart';
import 'profile.dart';
import 'notification_commuter.dart';
import 'wallet.dart';
import 'wallet_history.dart';
import 'otc.dart';
import 'otc_confirm.dart';
import 'otc_instructions.dart';
import 'otc_success.dart';
import 'activity_commuter.dart';
import 'wt.dart';
import 'wt_confirm.dart';
import 'wt_success.dart';
import 'dw.dart';
import 'dw_payment_method.dart';
import 'dw_payment_source.dart';
import 'dw_confirm.dart';
import 'dw_success.dart';

class CommuterDashboardNav extends StatefulWidget {
  const CommuterDashboardNav({super.key});

  @override
  State<CommuterDashboardNav> createState() => _CommuterDashboardNavState();
}

class _CommuterDashboardNavState extends State<CommuterDashboardNav> {
  int _currentIndex = 0;
  final GlobalKey<NotificationPageState> notificationKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return AnimatedBottomNavBar(
      pages: [
        const HomeTabNavigator(),
        const TripsPage(),
        const Center(child: Text("✍️ QR Scan")),
        NotificationPage(key: notificationKey),
        const ProfilePage(),
      ],
      items: const [
        NavItem(icon: Icons.home_rounded, label: 'Home'),
        NavItem(icon: Symbols.overview_rounded, label: 'Activity'),
        NavItem(icon: Symbols.qr_code_scanner_rounded, label: 'QR Scan'),
        NavItem(icon: Icons.notifications_rounded, label: 'Notification'),
        NavItem(icon: Icons.person_rounded, label: 'Profile'),
      ],
      initialIndex: _currentIndex,
      onItemSelected: (index) {
        if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QRScannerScreen(
                onScanComplete: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Boarding successful!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          );
        } else {
          setState(() => _currentIndex = index);
        }
      },
    );
  }
}

class HomeTabNavigator extends StatelessWidget {
  const HomeTabNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      initialRoute: '/',
      onGenerateRoute: (RouteSettings settings) {
        WidgetBuilder builder;
        switch (settings.name) {
          case '/wallet':
            builder = (BuildContext context) => const WalletPage();
            break;
          case '/history':
            final type = settings.arguments as HistoryType;
            builder = (BuildContext context) =>
                TransactionHistoryPage(type: type);
            break;
          case '/otc':
            builder = (BuildContext context) => const OverTheCounterPage();
            break;
          case '/otc_confirmation':
            final amount = settings.arguments as String;
            builder = (BuildContext context) =>
                OtcConfirmationPage(amount: amount);
            break;
          case '/otc_instructions':
            final transaction = settings.arguments as Map<String, dynamic>;
            builder = (BuildContext context) =>
                OtcInstructionsPage(transaction: transaction);
            break;
          case '/payment_success':
            builder = (BuildContext context) => const PaymentSuccessPage();
            break;
          case '/redeem_tokens':
            builder = (BuildContext context) => const RedeemTokensPage();
            break;
          case '/token_confirmation':
            final amount = settings.arguments as String;
            builder = (BuildContext context) =>
                TokenConfirmationPage(tokenAmount: amount);
            break;
          case '/token_success':
            builder = (BuildContext context) => const TokenSuccessPage();
            break;
          case '/digital_wallet':
            builder = (BuildContext context) => const DigitalWalletPage();
            break;
          case '/dw_payment_method':
            final args = settings.arguments as Map<String, String>;
            builder = (BuildContext context) => DwPaymentMethodPage(
              name: args['name']!,
              email: args['email']!,
              amount: args['amount']!,
            );
            break;
          case '/dw_payment_source':
            final args = settings.arguments as Map<String, String>;
            builder = (BuildContext context) => DwSourceSelectionPage(
              name: args['name']!,
              email: args['email']!,
              amount: args['amount']!,
              paymentMethod: args['paymentMethod']!,
            );
            break;
          case '/dw_confirmation':
            final args = settings.arguments as Map<String, String>;
            builder = (BuildContext context) => DwConfirmationPage(
              name: args['name']!,
              email: args['email']!,
              amount: args['amount']!,
              source: args['source']!,
            );
            break;
          case '/dw_success':
            builder = (BuildContext context) => const DwSuccessPage();
            break;
          default:
            builder = (BuildContext context) => const CommuterDashboardPage();
            break;
        }
        return MaterialPageRoute(builder: builder, settings: settings);
      },
    );
  }
}

// =================== DASHBOARD PAGE ===================
class CommuterDashboardPage extends StatefulWidget {
  const CommuterDashboardPage({super.key});

  @override
  State<CommuterDashboardPage> createState() => _CommuterDashboardPageState();
}

class _CommuterDashboardPageState extends State<CommuterDashboardPage> {
  bool showWallet = true;
  bool _isBalanceVisible = true;
  bool _isTokensVisible = true;

  final gradientColors = const [
    Color(0xFFB945AA),
    Color(0xFF8E4CB6),
    Color(0xFF5B53C2),
  ];
  final gradientColors1 = const [Color(0xFFB945AA), Color(0xFF8E4CB6)];
  final gradientColors2 = const [Color(0xFF8E4CB6), Color(0xFF5B53C2)];

  // 👇 ADD THIS - Load data when page opens
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommuterDashboardProvider>().loadDashboardData();
    });
  }

  void _switchTab(bool goWallet) {
    setState(() {
      showWallet = goWallet;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400;

    return Consumer<CommuterDashboardProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(30, 30, 30, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SvgPicture.asset(
                    'assets/images/logo.svg',
                    height: 80,
                    width: 80,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Hi, ${provider.firstName.isEmpty ? "User" : provider.firstName}',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        'Welcome back!',
                        style: GoogleFonts.manrope(
                          color: const Color(0xFF8E4CB6),
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  _buildTabButton('Wallet', true),
                  _buildTabButton('Tokens', false),
                ],
              ),

              // Wallet / Tokens Animated Card
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradientColors),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final inFromRight = !showWallet;

                      final offsetAnimation =
                          Tween<Offset>(
                            begin: Offset(inFromRight ? 1.0 : -1.0, 0.0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeInOutCubic,
                            ),
                          );

                      final fadeAnimation = CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      );

                      return ClipRect(
                        child: SlideTransition(
                          position: offsetAnimation,
                          child: FadeTransition(
                            opacity: fadeAnimation,
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      key: ValueKey<bool>(showWallet),
                      child: showWallet
                          ? _buildWalletCard(isSmallScreen, provider)
                          : _buildTokensCard(isSmallScreen, provider),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              _buildAnalyticsSection(isSmallScreen, provider),
              const SizedBox(height: 20),
              _buildPromoCard(),
              const SizedBox(height: 20),
              _buildQuickActions(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabButton(String title, bool isWallet) {
    final isSelected = showWallet == isWallet;
    final currentGradientColors = isWallet ? gradientColors1 : gradientColors2;

    return Expanded(
      child: GestureDetector(
        onTap: () => _switchTab(isWallet),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? null : Colors.grey[200],
            gradient: isSelected
                ? LinearGradient(colors: currentGradientColors)
                : null,
            borderRadius: isWallet
                ? const BorderRadius.only(topLeft: Radius.circular(10))
                : const BorderRadius.only(topRight: Radius.circular(10)),
          ),
          child: Center(
            child: Text(
              title,
              style: GoogleFonts.manrope(
                color: isSelected ? Colors.white : Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWalletCard(
    bool isSmallScreen,
    CommuterDashboardProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Balance',
          style: GoogleFonts.manrope(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  _isBalanceVisible
                      ? '₱${provider.balance.toStringAsFixed(2)}'
                      : '₱•••',
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () =>
                      setState(() => _isBalanceVisible = !_isBalanceVisible),
                  child: Icon(
                    _isBalanceVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
            CustomButton(
              text: 'Cash In',
              icon: Icons.add_rounded,
              onPressed: () {
                Navigator.of(context).pushNamed('/wallet');
              },
              isFilled: true,
              fillColor: Colors.white,
              textColor: const Color(0xFF5B53C2),
              iconColor: const Color(0xFF5B53C2),
              width: 120,
              height: 45,
              borderRadius: 30,
              hasShadow: false,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTokensCard(
    bool isSmallScreen,
    CommuterDashboardProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tokens', style: GoogleFonts.manrope(color: Colors.white70)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/wheel token.png',
                  height: 32,
                  width: 32,
                ),
                const SizedBox(width: 8),
                Text(
                  _isTokensVisible ? provider.wheelTokens.toString() : '•••',
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () =>
                      setState(() => _isTokensVisible = !_isTokensVisible),
                  child: Icon(
                    _isTokensVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
            CustomButton(
              text: 'Redeem',
              onPressed: () {
                Navigator.of(context).pushNamed('/wallet');
              },
              isFilled: true,
              fillColor: Colors.white,
              textColor: const Color(0xFFB945AA),
              iconColor: const Color(0xFFB945AA),
              width: 120,
              height: 45,
              borderRadius: 30,
              hasShadow: false,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              imagePath: 'assets/images/redeem.svg',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalyticsSection(
    bool isSmallScreen,
    CommuterDashboardProvider provider,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF8E4CB6)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Commute Analytics',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    'This week',
                    style: GoogleFonts.nunito(color: const Color(0xFF8E4CB6)),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {},
                icon: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8E4CB6), Color(0xFF5B53C2)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAnalyticsItem(
                Icons.directions_bus,
                'Trips',
                '${provider.totalTripsCount} trips', // 👈 DYNAMIC TRIPS COUNT
                subtitle:
                    '12.6 mi', // Keep this static or calculate from trip data
              ),
              _buildAnalyticsItem(
                Icons.account_balance_wallet_outlined,
                'Spend',
                '₱${provider.totalSpent.toStringAsFixed(0)} total', // 👈 DYNAMIC TOTAL SPENT
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsItem(
    IconData icon,
    String title,
    String value, {
    String? subtitle,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF8E4CB6)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
            Text(value, style: GoogleFonts.nunito(color: Colors.black87)),
            if (subtitle != null)
              Text(subtitle, style: GoogleFonts.nunito(color: Colors.black54)),
          ],
        ),
      ],
    );
  }

  // ---------------- Promo ----------------
  Widget _buildPromoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Symbols.featured_seasonal_and_gifts_rounded,
            color: Color(0xFFB3A11B),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              'Get 50% off your next ride!\nUse Code: KOMYUTIE50',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w500),
            ),
          ),
          CustomButton(
            text: 'Claim',
            fontSize: 13,
            onPressed: () {},
            isFilled: true,
            fillColor: const Color(0xFF8E4CB6),
            textColor: Colors.white,
            width: 70,
            height: 35,
            borderRadius: 20,
            hasShadow: false,
          ),
        ],
      ),
    );
  }

  // ---------------- Quick Actions ----------------
  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildActionButton('Find Route', Icons.route),
          const SizedBox(height: 10),
          _buildActionButton('Report an issue', Icons.report_problem_outlined),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(
          title,
          style: GoogleFonts.manrope(color: Colors.white, fontSize: 18),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white,
          size: 12,
        ),
        leading: Icon(icon, color: Colors.white),
        onTap: () {},
      ),
    );
  }
}