import 'package:flutter/foundation.dart';
import '../services/registration_service.dart';
import 'dart:io';

class RegistrationProvider extends ChangeNotifier {
  final RegistrationService _registrationService = RegistrationService();
  
  bool _isLoading = false;
  String? _errorMessage;
  File? _idProofFile;
  File? _driverLicenseFile;
  List<Map<String, dynamic>> _availableRoutes = [];  // ✨ NEW

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  File? get idProofFile => _idProofFile;
  File? get driverLicenseFile => _driverLicenseFile;
  List<Map<String, dynamic>> get availableRoutes => _availableRoutes;  // ✨ NEW
  Map<String, dynamic> get registrationData => _registrationService.getRegistrationData();

  // Step 1: Save role
  void saveRole(String role) {
    _registrationService.saveRole(role);
    _errorMessage = null;
    notifyListeners();
  }

  // Step 2a: Save commuter personal info
  Future<bool> savePersonalInfo({
    required String firstName,
    required String lastName,
    required int age,
    required String sex,
    required String address,
    required String category,
    File? idProofFile,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Store ID proof file reference
      if (idProofFile != null) {
        _idProofFile = idProofFile;
      }

      _registrationService.savePersonalInfo(
        firstName: firstName,
        lastName: lastName,
        age: age,
        sex: sex,
        address: address,
        category: category,
        idProofPath: idProofFile?.path,
      );

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

  // Step 2b: Save driver personal info (UPDATED with vehicle and route)
  Future<bool> saveDriverPersonalInfo({
    required String firstName,
    required String lastName,
    required int age,
    required String sex,
    required String address,
    required String licenseNumber,
    String? assignedOperator,
    required File driverLicenseFile,
    required String vehiclePlate,  // ✨ NEW
    required String routeCode,     // ✨ NEW
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Store driver license file reference
      _driverLicenseFile = driverLicenseFile;

      _registrationService.saveDriverPersonalInfo(
        firstName: firstName,
        lastName: lastName,
        age: age,
        sex: sex,
        address: address,
        licenseNumber: licenseNumber,
        assignedOperator: assignedOperator,
        driverLicensePath: driverLicenseFile.path,
        vehiclePlate: vehiclePlate,  // ✨ NEW
        routeCode: routeCode,        // ✨ NEW
      );

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

  // Step 2c: Save operator personal info
  Future<bool> saveOperatorPersonalInfo({
    required String firstName,
    required String lastName,
    required String companyName,
    required String companyAddress,
    required String contactEmail,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _registrationService.saveOperatorPersonalInfo(
        firstName: firstName,
        lastName: lastName,
        companyName: companyName,
        companyAddress: companyAddress,
        contactEmail: contactEmail,
      );

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

  // Step 3: Save login info
  void saveLoginInfo({
    required String email,
    required String password,
  }) {
    _registrationService.saveLoginInfo(
      email: email,
      password: password,
    );
    notifyListeners();
  }

  // ✨ NEW: Load available routes for dropdown
  Future<void> loadAvailableRoutes() async {
    try {
      _isLoading = true;
      notifyListeners();

      _availableRoutes = await _registrationService.getAvailableRoutes();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load routes: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // NEW: Send email verification OTP (no account created yet)
  Future<Map<String, dynamic>> sendEmailVerificationOTP(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final result = await _registrationService.sendEmailVerificationOTP(email);

      _isLoading = false;
      
      if (!result['success']) {
        _errorMessage = result['message'];
      }
      
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': _errorMessage,
      };
    }
  }

  // NEW: Verify OTP and create account
  Future<Map<String, dynamic>> verifyOTPAndCreateAccount(
    String email,
    String otp,
  ) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final result = await _registrationService.verifyOTPAndCreateAccount(
        email,
        otp,
      );

      _isLoading = false;
      
      if (!result['success']) {
        _errorMessage = result['message'];
      }
      
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': _errorMessage,
      };
    }
  }

  // NEW: Resend OTP
  Future<Map<String, dynamic>> resendOTP(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final result = await _registrationService.resendOTP(email);

      _isLoading = false;
      
      if (!result['success']) {
        _errorMessage = result['message'];
      }
      
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': _errorMessage,
      };
    }
  }

  // Complete registration (Step 4 - after email verification)
  Future<Map<String, dynamic>> completeRegistration() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final result = await _registrationService.completeRegistration();

      _isLoading = false;
      
      if (!result['success']) {
        _errorMessage = result['message'];
      }
      
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': _errorMessage,
      };
    }
  }

  // Clear all registration data
  void clearRegistration() {
    _registrationService.clearRegistrationData();
    _idProofFile = null;
    _driverLicenseFile = null;
    _availableRoutes = [];  // ✨ NEW
    _errorMessage = null;
    notifyListeners();
  }

  // Get specific field from registration data
  String? getField(String key) {
    return registrationData[key]?.toString();
  }
}