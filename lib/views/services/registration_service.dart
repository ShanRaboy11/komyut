// lib/views/services/registration_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

class RegistrationService {
  static const String _baseUrl = 'YOUR_API_BASE_URL'; // Update with your API URL
  
  // Store registration data temporarily
  final Map<String, dynamic> _registrationData = {};

  Map<String, dynamic> getRegistrationData() => Map.from(_registrationData);

  // Step 1: Save role
  void saveRole(String role) {
    // Store role as lowercase to match ENUM in database
    _registrationData['role'] = role.toLowerCase();
  }

  // Step 2a: Save commuter personal info
  void savePersonalInfo({
    required String firstName,
    required String lastName,
    required int age,
    required String sex,
    required String address,
    required String category,
    String? idProofPath,
  }) {
    _registrationData['first_name'] = firstName;
    _registrationData['last_name'] = lastName;
    _registrationData['age'] = age;
    _registrationData['sex'] = sex;
    _registrationData['address'] = address;
    
    // Map UI category to database enum: 'Regular' -> 'regular', 'Discounted' -> handle subcategories
    // For now, defaulting 'Discounted' to 'student' - you may want to add more granular selection
    if (category.toLowerCase() == 'regular') {
      _registrationData['category'] = 'regular';
    } else {
      // If discounted, you might want to add a field to select senior/student/pwd
      _registrationData['category'] = 'student'; // Default to student for now
    }
    
    if (idProofPath != null) {
      _registrationData['id_proof_path'] = idProofPath;
    }
  }

  // Step 2b: Save driver personal info
  void saveDriverPersonalInfo({
    required String firstName,
    required String lastName,
    required int age,
    required String sex,
    required String address,
    required String licenseNumber,
    String? assignedOperator,
    required String driverLicensePath,
  }) {
    _registrationData['first_name'] = firstName;
    _registrationData['last_name'] = lastName;
    _registrationData['age'] = age;
    _registrationData['sex'] = sex;
    _registrationData['address'] = address;
    _registrationData['license_number'] = licenseNumber;
    _registrationData['driver_license_path'] = driverLicensePath;
    
    if (assignedOperator != null && assignedOperator.isNotEmpty) {
      _registrationData['operator_name'] = assignedOperator;
    }
  }

  // Step 2c: Save operator personal info
  // Step 2c: Save operator personal info
void saveOperatorPersonalInfo({
  required String firstName,
  required String lastName,
  required String companyName,
  required String companyAddress,
  required String contactEmail,
}) {
  _registrationData['first_name'] = firstName;
  _registrationData['last_name'] = lastName;
  _registrationData['company_name'] = companyName;
  _registrationData['company_address'] = companyAddress;
  _registrationData['contact_email'] = contactEmail;
}

  // Step 3: Save login info
  void saveLoginInfo({
    required String email,
    required String password,
  }) {
    _registrationData['email'] = email;
    _registrationData['password'] = password;
  }

  // Step 4: Complete registration and send to backend
  Future<Map<String, dynamic>> completeRegistration() async {
    try {
      // Prepare multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/auth/register'),
      );

      final role = _registrationData['role'];

      // Add common fields
      request.fields['email'] = _registrationData['email'];
      request.fields['password'] = _registrationData['password'];
      request.fields['role'] = role;
      request.fields['first_name'] = _registrationData['first_name'];
      request.fields['last_name'] = _registrationData['last_name'];
      request.fields['age'] = _registrationData['age'].toString();
      request.fields['sex'] = _registrationData['sex'];
      request.fields['address'] = _registrationData['address'];

      // Add role-specific fields and files
      if (role == 'commuter') {
        request.fields['category'] = _registrationData['category'];
        
        // Upload ID proof if category is not regular (senior, student, pwd)
        if (_registrationData['category'] != 'regular' && 
            _registrationData['id_proof_path'] != null) {
          final idProofFile = File(_registrationData['id_proof_path']);
          if (await idProofFile.exists()) {
            request.files.add(
              await http.MultipartFile.fromPath(
                'id_proof',
                idProofFile.path,
              ),
            );
          }
        }
      } else if (role == 'driver') {
        request.fields['license_number'] = _registrationData['license_number'];
        
        if (_registrationData['operator_name'] != null) {
          request.fields['operator_name'] = _registrationData['operator_name'];
        }
        
        // Upload driver license (required)
        if (_registrationData['driver_license_path'] != null) {
          final licenseFile = File(_registrationData['driver_license_path']);
          if (await licenseFile.exists()) {
            request.files.add(
              await http.MultipartFile.fromPath(
                'license_image',
                licenseFile.path,
              ),
            );
          }
        }
      } else if (role == 'operator') {
        if (_registrationData['company_name'] != null) {
          request.fields['company_name'] = _registrationData['company_name'];
        }
        if (_registrationData['company_address'] != null) {
          request.fields['company_address'] = _registrationData['company_address'];
        }
        if (_registrationData['contact_phone'] != null) {
          request.fields['contact_phone'] = _registrationData['contact_phone'];
        }
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        clearRegistrationData(); // Clear data after successful registration
        
        return {
          'success': true,
          'message': 'Registration successful',
          'data': responseData,
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Clear all registration data
  void clearRegistrationData() {
    _registrationData.clear();
  }
}