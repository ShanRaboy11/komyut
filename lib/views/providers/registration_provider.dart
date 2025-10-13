// lib/views/providers/registration_provider.dart
import 'package:flutter/foundation.dart';
import '../services/registration_service.dart';
import 'dart:io';

class RegistrationProvider extends ChangeNotifier {
  final RegistrationService _registrationService = RegistrationService();
  
  bool _isLoading = false;
  String? _errorMessage;
  File? _idProofFile;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  File? get idProofFile => _idProofFile;
  Map<String, dynamic> get registrationData => _registrationService.getRegistrationData();

  // Step 1: Save role
  void saveRole(String role) {
    _registrationService.saveRole(role);
    _errorMessage = null;
    notifyListeners();
  }

  // Step 2: Save personal info
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

  // Step 3: Save login info
  void saveLoginInfo({
    required String email,
    required String password,
    String? phone,
  }) {
    _registrationService.saveLoginInfo(
      email: email,
      password: password,
      phone: phone,
    );
    notifyListeners();
  }

  // Complete registration (Step 4)
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
    _errorMessage = null;
    notifyListeners();
  }

  // Get specific field from registration data
  String? getField(String key) {
    return registrationData[key]?.toString();
  }
}