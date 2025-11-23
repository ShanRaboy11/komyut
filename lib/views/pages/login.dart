import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/button.dart';
import '../widgets/shake_widget.dart';

import '../providers/auth_provider.dart';
import '../../utils/toast_utils.dart';
import 'create_account.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  double _sheetHeight = 0;
  double _sheetOpacity = 0;
  double _logoOpacity = 0.0;

  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late FocusNode _emailFocusNode;
  late FocusNode _passwordFocusNode;

  final _emailShakeKey = GlobalKey<ShakeWidgetState>();
  final _passwordShakeKey = GlobalKey<ShakeWidgetState>();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _emailFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();

    _emailFocusNode.addListener(() => setState(() {}));
    _passwordFocusNode.addListener(() => setState(() {}));
    _emailController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenSize = MediaQuery.of(context).size; // ✅ FIXED
      setState(() {
        _sheetHeight = screenSize.height * 0.75;
        _sheetOpacity = 1.0; // ✅ Now valid
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _logoOpacity = 1.0; // fade in logo
      });
    });
  }

  void _collapseSheet() {
    setState(() {
      _sheetHeight = 0;
      _sheetOpacity = 0;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  String _getHomeRouteForRole(String? userRole) {
    if (userRole == null || userRole.isEmpty) {
      debugPrint('⚠️ User role is null or empty, defaulting to commuter');
      return '/home_commuter';
    }

    switch (userRole.toLowerCase()) {
      case 'admin':
        return '/home_admin';
      case 'commuter':
        return '/home_commuter';
      case 'driver':
        return '/home_driver';
      case 'operator':
        return '/home_operator';
      default:
        debugPrint('⚠️ Unknown user role: $userRole, defaulting to commuter');
        return '/home_commuter';
    }
  }

  Future<String?> _fetchUserRole() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        debugPrint('⚠️ No authenticated user found');
        return null;
      }

      debugPrint('🔍 Fetching profile for user ID: $userId');

      try {
        final response = await supabase
            .from('profiles')
            .select('role')
            .eq('id', userId)
            .maybeSingle();

        if (response != null && response['role'] != null) {
          final role = response['role'] as String;
          debugPrint('✅ User role fetched (using id): $role');
          return role;
        }
      } catch (e) {
        debugPrint('⚠️ Failed to fetch with "id" column, trying "user_id": $e');
      }

      try {
        final response = await supabase
            .from('profiles')
            .select('role')
            .eq('user_id', userId)
            .maybeSingle();

        if (response != null && response['role'] != null) {
          final role = response['role'] as String;
          debugPrint('✅ User role fetched (using user_id): $role');
          return role;
        }
      } catch (e) {
        debugPrint('⚠️ Failed to fetch with "user_id" column: $e');
      }

      final profileCheck = await supabase
          .from('profiles')
          .select('id, user_id')
          .limit(1);

      debugPrint('📊 Profile table structure check: $profileCheck');
      debugPrint('❌ No profile found for user ID: $userId');

      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching user role: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _emailShakeKey.currentState?.shake();
      _passwordShakeKey.currentState?.shake();

      ToastUtils.showCustomToast(
        context,
        'Please fill in both email and password.',
        Colors.redAccent,
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signIn(email: email, password: password);

    if (!mounted) return;

    if (success) {
      await Future.delayed(const Duration(milliseconds: 500));

      final userRole = await _fetchUserRole();

      if (!mounted) return;

      if (userRole == null) {
        ToastUtils.showCustomToast(
          context,
          'Unable to retrieve your profile. Please contact support.',
          Colors.orangeAccent,
        );
        Navigator.pushReplacementNamed(context, '/home_commuter');
        return;
      }

      final homeRoute = _getHomeRouteForRole(userRole);
      debugPrint('🏠 Redirecting to: $homeRoute for role: $userRole');

      ToastUtils.showCustomToast(context, 'Login Successful!', Colors.green);

      Navigator.pushReplacementNamed(context, homeRoute);
    } else {
      _emailShakeKey.currentState?.shake();
      _passwordShakeKey.currentState?.shake();

      String errorMsg;
      final error = authProvider.errorMessage?.toLowerCase() ?? '';

      if (error.contains('user-not-found')) {
        errorMsg = 'No account found with this email.';
      } else if (error.contains('wrong-password')) {
        errorMsg = 'Incorrect password. Please try again.';
      } else if (error.contains('invalid-email')) {
        errorMsg = 'Please enter a valid email address.';
      } else if (error.contains('network-request-failed')) {
        errorMsg = 'Network error. Please check your internet connection.';
      } else if (error.contains('too-many-requests')) {
        errorMsg = 'Too many failed attempts. Please try again later.';
      } else {
        errorMsg = 'Login failed. Please check your credentials and try again.';
      }

      ToastUtils.showCustomToast(context, errorMsg, Colors.redAccent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: AnimatedOpacity(
          opacity: _logoOpacity,
          duration: const Duration(milliseconds: 2000),
          curve: Curves.easeOut,
          child: IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: Colors.black),
            onPressed: () async {
              _collapseSheet();

              await Future.delayed(const Duration(milliseconds: 200));

              if (!context.mounted) return;

              Navigator.of(context).pop();
            },
          ),
        ),
        title: AnimatedOpacity(
          opacity: _logoOpacity,
          duration: const Duration(milliseconds: 2000),
          curve: Curves.easeOut,
          child: Text(
            'Back',
            style: GoogleFonts.nunito(color: Colors.black, fontSize: 16),
          ),
        ),
      ),

      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFDFDFF), Color(0xFFF1F0FA)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 39,
                left: 172,
                child: Image.asset("assets/images/Ellipse 1.png"),
              ),
              Positioned(
                top: -134,
                left: 22,
                child: Image.asset("assets/images/Ellipse 3.png"),
              ),
              Positioned(
                top: screenSize.height * 0.12,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _sheetOpacity,
                    duration: const Duration(milliseconds: 2000),
                    curve: Curves.easeOut,
                    child: Image.asset(
                      'assets/images/komyut small logo.png',
                      width: screenSize.width * 0.5,
                    ),
                  ),
                ),
              ),

              AnimatedPositioned(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                bottom: 0,
                left: 0,
                right: 0,
                height: _sheetHeight,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 600),
                  opacity: _sheetHeight == 0 ? 0 : 1,
                  curve: Curves.easeOutCubic,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    decoration: const ShapeDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(0.50, 0.00),
                        end: Alignment(0.50, 1.00),
                        colors: [
                          Color(0xFFB945AA),
                          Color(0xFF8E4CB6),
                          Color(0xFF5B53C2),
                        ],
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(60),
                          topRight: Radius.circular(60),
                        ),
                      ),
                      shadows: [
                        BoxShadow(
                          color: Color(0x3F000000),
                          blurRadius: 4,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        26.0,
                        50.0,
                        26.0,
                        30.0,
                      ),
                      child: SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: screenSize.height * 0.78 - 80,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "Welcome Back",
                                style: GoogleFonts.manrope(
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Column(
                                children: [
                                  Text(
                                    'Ready to make your rides smoother and smarter?',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.nunito(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      height: 1.5,
                                    ),
                                  ),
                                  Text(
                                    'Your next trip starts here.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.nunito(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 30),
                              ShakeWidget(
                                key: _emailShakeKey,
                                child: TextFormField(
                                  controller: _emailController,
                                  focusNode: _emailFocusNode,
                                  style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Email Address',
                                    hintStyle: GoogleFonts.nunito(
                                      color: Colors.white.withAlpha(204),
                                    ),
                                    filled: true,
                                    fillColor: _emailFocusNode.hasFocus
                                        ? Colors.white.withAlpha(26)
                                        : Colors.transparent,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 15,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        width: 1,
                                        color: Color(0xFFC6C7C7),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        width: 1.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ShakeWidget(
                                key: _passwordShakeKey,
                                child: TextFormField(
                                  controller: _passwordController,
                                  focusNode: _passwordFocusNode,
                                  obscureText: !_isPasswordVisible,
                                  style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Password',
                                    hintStyle: GoogleFonts.nunito(
                                      color: Colors.white.withAlpha(204),
                                    ),
                                    filled: true,
                                    fillColor: _passwordFocusNode.hasFocus
                                        ? Colors.white.withAlpha(26)
                                        : Colors.transparent,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 15,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        width: 1,
                                        color: Color(0xFFC6C7C7),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        width: 1.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                    suffixIcon: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isPasswordVisible =
                                              !_isPasswordVisible;
                                        });
                                      },
                                      child: Icon(
                                        _isPasswordVisible
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: Checkbox(
                                            value: _rememberMe,
                                            onChanged: (value) {
                                              setState(() {
                                                _rememberMe = value ?? false;
                                              });
                                            },
                                            activeColor: Colors.white,
                                            checkColor: const Color(0xFFB945AA),
                                            side: const BorderSide(
                                              color: Colors.white,
                                              width: 1.5,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _rememberMe = !_rememberMe;
                                            });
                                          },
                                          child: Text(
                                            'Remember me',
                                            style: GoogleFonts.nunito(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    GestureDetector(
                                      onTap: () {},
                                      child: Text(
                                        'Forgot password?',
                                        style: GoogleFonts.nunito(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 30),

                              // Log In Button
                              CustomButton(
                                text: "Log In",
                                isFilled: true,
                                fillColor: Colors.white,
                                textColor: const Color(0xFFB945AA),
                                onPressed: authProvider.isLoading
                                    ? () {}
                                    : _handleLogin,
                                width: screenSize.width * 0.87,
                                height: 45,
                                fontSize: 16,
                              ),

                              const SizedBox(height: 40),

                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const CreateAccountPage(),
                                    ),
                                  );
                                },
                                child: RichText(
                                  text: TextSpan(
                                    text: "Don't have an account? ",
                                    style: GoogleFonts.nunito(
                                      fontSize: 14,
                                      color: Colors.white.withAlpha(204),
                                    ),
                                    children: const [
                                      TextSpan(
                                        text: "Sign up",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
