import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../widgets/button.dart';
import '../widgets/social_button.dart';
import '../pages/create_account.dart';
import '../widgets/shake_widget.dart';
import '../../utils/toast_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // State for password visibility and checkbox
  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  // Controllers and FocusNodes for TextFields
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late FocusNode _emailFocusNode;
  late FocusNode _passwordFocusNode;

  // NEW: Create separate keys for each text field to shake them individually
  final _emailShakeKey = GlobalKey<ShakeWidgetState>();
  final _passwordShakeKey = GlobalKey<ShakeWidgetState>();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _emailFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();

    // Add listeners to rebuild the UI when focus or text changes
    _emailFocusNode.addListener(() => setState(() {}));
    _passwordFocusNode.addListener(() => setState(() {}));
    _emailController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    // Dispose controllers and focus nodes to prevent memory leaks
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // Helper method to get the correct home route based on user role
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

  // Fetch user role from Supabase profiles table
  Future<String?> _fetchUserRole() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        debugPrint('⚠️ No authenticated user found');
        return null;
      }

      debugPrint('🔍 Fetching profile for user ID: $userId');

      final response = await supabase
          .from('profiles')
          .select('role')
          .eq('user_id', userId)
          .single();

      final role = response['role'] as String?;
      debugPrint('✅ User role fetched: $role');
      
      return role;
    } catch (e) {
      debugPrint('❌ Error fetching user role: $e');
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
      // Fetch user role from database
      final userRole = await _fetchUserRole();
      
      if (!mounted) return;

      if (userRole == null) {
        ToastUtils.showCustomToast(
          context,
          'Unable to retrieve user role. Please try again.',
          Colors.redAccent,
        );
        return;
      }

      // Get the appropriate route based on role
      final homeRoute = _getHomeRouteForRole(userRole);
      debugPrint('🏠 Redirecting to: $homeRoute for role: $userRole');

      ToastUtils.showCustomToast(
        context,
        'Login Successful!',
        Colors.green,
      );

      // Navigate to role-specific dashboard
      Navigator.pushReplacementNamed(context, homeRoute);
    } else {
      _emailShakeKey.currentState?.shake();
      _passwordShakeKey.currentState?.shake();

      ToastUtils.showCustomToast(
        context,
        authProvider.errorMessage ?? 'An unknown error occurred.',
        Colors.redAccent,
      );
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Back', style: TextStyle(color: Colors.black)),
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
                top: screenSize.height * 0.10,
                left: 0,
                right: 0,
                child: Center(
                  child: Image.asset(
                    'assets/images/komyut small logo.png',
                    width: screenSize.width * 0.5,
                  ),
                ),
              ),

              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: screenSize.height * 0.78,
                child: Container(
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
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(26.0, 50.0, 26.0, 30.0),
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: screenSize.height * 0.78 - 80,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              "Welcome Back",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Manrope',
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Column(
                              children: [
                                Text(
                                  'Ready to make your rides smoother and smarter?',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontFamily: 'Nunito',
                                    fontWeight: FontWeight.w400,
                                    height: 1.5,
                                  ),
                                ),
                                Text(
                                  'Your next trip starts here.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontFamily: 'Nunito',
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
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Nunito',
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Email Address',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withAlpha(204),
                                    fontFamily: 'Nunito',
                                  ),
                                  filled: true,
                                  fillColor: _emailFocusNode.hasFocus
                                      ? Colors.white.withAlpha(26)
                                      : Colors.transparent,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 20,
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
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Nunito',
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withAlpha(204),
                                    fontFamily: 'Nunito',
                                  ),
                                  filled: true,
                                  fillColor: _passwordFocusNode.hasFocus
                                      ? Colors.white.withAlpha(26)
                                      : Colors.transparent,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 20,
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
                                            borderRadius: BorderRadius.circular(
                                              5,
                                            ),
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
                                        child: const Text(
                                          'Remember me',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontFamily: 'Nunito',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      // Handle forgot password
                                    },
                                    child: const Text(
                                      'Forgot password?',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontFamily: 'Nunito',
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
                              height: 60,
                            ),
                            const SizedBox(height: 65),

                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.white.withAlpha(100),
                                    thickness: 1,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.0,
                                  ),
                                  child: Text(
                                    "Sign in with",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontFamily: 'Nunito',
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.white.withAlpha(100),
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SocialButton(
                                  imagePath: 'assets/images/facebook.png',
                                  onPressed: () {},
                                ),
                                const SizedBox(width: 20),
                                SocialButton(
                                  imagePath: 'assets/images/google.png',
                                  onPressed: () {},
                                ),
                              ],
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
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withAlpha(204),
                                    fontFamily: 'Nunito',
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
            ],
          ),
        ),
      ),
    );
  }
}