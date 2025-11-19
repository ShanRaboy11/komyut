import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  String? _userRole; // Cache the user role

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  String? get userRole => _userRole;

  AuthProvider() {
    _init();
  }

  void _init() {
    _user = _authService.currentUser;
    
    // Load initial role if user exists
    if (_user != null) {
      _loadUserRole();
    }
    
    _authService.authStateChanges.listen((data) {
      final newUser = data.session?.user;
      
      // Only update if user actually changed
      if (newUser?.id != _user?.id) {
        _user = newUser;
        
        if (_user != null) {
          _loadUserRole();
        } else {
          // Critical: Clear role when user logs out
          _userRole = null;
        }
        
        notifyListeners();
      }
    });
  }

  // Load user role from database
  Future<void> _loadUserRole() async {
    try {
      if (_user == null) return;
      
      final response = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('user_id', _user!.id)
          .single();
      
      _userRole = response['role'] as String?;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user role: $e');
      _userRole = null;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _authService.signUp(
        email: email,
        password: password,
        metadata: metadata,
      );

      _user = response.user;
      
      // Load role for new user
      if (_user != null) {
        await _loadUserRole();
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _authService.signIn(
        email: email,
        password: password,
      );

      _user = response.user;
      
      // Load role immediately after sign in
      if (_user != null) {
        await _loadUserRole();
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      
      // CRITICAL: Clear all user-related state
      _user = null;
      _userRole = null;
      _errorMessage = null;
      _isLoading = false;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error during sign out: $e');
      // Still clear state even if sign out fails
      _user = null;
      _userRole = null;
      notifyListeners();
    }
  }

  // Method to manually refresh user role (call this after profile updates)
  Future<void> refreshUserRole() async {
    await _loadUserRole();
  }

  // Clear all state (useful for debugging or forced logout)
  void clearState() {
    _user = null;
    _userRole = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}