import 'package:flutter/material.dart';
import '../services/admin_verification.dart';

class AdminVerificationProvider extends ChangeNotifier {
  final AdminVerificationService _service = AdminVerificationService();

  // State for verification list
  List<VerificationListItem> _verifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  // State for verification detail
  VerificationDetail? _currentVerificationDetail;
  bool _isLoadingDetail = false;
  String? _detailErrorMessage;

  // Getters
  List<VerificationListItem> get verifications => _verifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  VerificationDetail? get currentVerificationDetail => _currentVerificationDetail;
  bool get isLoadingDetail => _isLoadingDetail;
  String? get detailErrorMessage => _detailErrorMessage;

  /// Load all verification requests
  Future<void> loadVerifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _service.fetchVerifications();
      _verifications = data
          .map((item) => VerificationListItem.fromJson(item))
          .toList();

      debugPrint('✅ Loaded ${_verifications.length} verifications');
    } catch (e) {
      _errorMessage = 'Failed to load verifications: $e';
      debugPrint('❌ Error in loadVerifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load detailed information for a specific verification
  Future<void> loadVerificationDetail(String verificationId) async {
    _isLoadingDetail = true;
    _detailErrorMessage = null;
    _currentVerificationDetail = null;
    notifyListeners();

    try {
      final data = await _service.fetchVerificationDetail(verificationId);
      _currentVerificationDetail = VerificationDetail.fromJson(data);

      debugPrint('✅ Loaded verification detail for: $verificationId');
    } catch (e) {
      _detailErrorMessage = 'Failed to load verification details: $e';
      debugPrint('❌ Error in loadVerificationDetail: $e');
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  /// Approve a verification
  Future<bool> approveVerification(String verificationId, String profileId, String? notes) async {
    try {
      await _service.approveVerification(verificationId, profileId, notes);
      
      // Reload verifications to reflect changes
      await loadVerifications();
      
      return true;
    } catch (e) {
      _errorMessage = 'Failed to approve verification: $e';
      notifyListeners();
      return false;
    }
  }

  /// Reject a verification
  Future<bool> rejectVerification(String verificationId, String notes) async {
    try {
      await _service.rejectVerification(verificationId, notes);
      
      // Reload verifications to reflect changes
      await loadVerifications();
      
      return true;
    } catch (e) {
      _errorMessage = 'Failed to reject verification: $e';
      notifyListeners();
      return false;
    }
  }

  /// Mark verification as lacking documents
  Future<bool> markAsLacking(String verificationId, String notes) async {
    try {
      await _service.markAsLacking(verificationId, notes);
      
      // Reload verifications to reflect changes
      await loadVerifications();
      
      return true;
    } catch (e) {
      _errorMessage = 'Failed to mark as lacking: $e';
      notifyListeners();
      return false;
    }
  }

  /// Filter verifications by status, role, and search query
  List<VerificationListItem> applyFilters({
    String status = '',
    String role = 'All',
    String searchQuery = '',
  }) {
    var filtered = _verifications;

    // Filter by role
    if (role != 'All') {
      filtered = filtered
          .where((v) => v.role.toLowerCase() == role.toLowerCase())
          .toList();
    }

    // Filter by status
    if (status.isNotEmpty) {
      filtered = filtered
          .where((v) => v.status.toLowerCase() == status.toLowerCase())
          .toList();
    }

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      final lowerQuery = searchQuery.toLowerCase();
      filtered = filtered
          .where((v) => v.userName.toLowerCase().contains(lowerQuery))
          .toList();
    }

    return filtered;
  }

  /// Clear current verification detail
  void clearCurrentDetail() {
    _currentVerificationDetail = null;
    _detailErrorMessage = null;
    notifyListeners();
  }
}

/// Model for verification list item
class VerificationListItem {
  final String id;
  final String profileId;
  final String userName;
  final String role;
  final bool isVerified;
  final String verificationType;
  final String status;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  VerificationListItem({
    required this.id,
    required this.profileId,
    required this.userName,
    required this.role,
    this.isVerified = false,
    required this.verificationType,
    required this.status,
    this.imageUrl,
    required this.createdAt,
    this.reviewedAt,
  });

  factory VerificationListItem.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    final attachment = json['attachments'] as Map<String, dynamic>?;

    final firstName = profile?['first_name'] ?? '';
    final lastName = profile?['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();

    return VerificationListItem(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      userName: fullName.isNotEmpty ? fullName : 'Unknown User',
      role: profile?['role'] as String? ?? 'unknown',
      isVerified: profile?['is_verified'] as bool? ?? false,
      verificationType: json['verification_type'] as String? ?? 'ID Verification',
      status: json['status'] as String,
      imageUrl: attachment?['url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
    );
  }

  /// Get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Get capitalized status
  String get statusCapitalized {
    return status[0].toUpperCase() + status.substring(1);
  }

  /// Get capitalized role
  String get roleCapitalized {
    return role[0].toUpperCase() + role.substring(1);
  }
}

/// Model for detailed verification information
class VerificationDetail {
  final String id;
  final String profileId;
  final String userName;
  final String role;
  final String verificationType;
  final String status;
  final String? imageUrl;
  final String? reviewerNotes;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  // Profile information
  final String? phone;
  final String? address;
  final int? age;
  final String? sex;

  // Role-specific data
  final Map<String, dynamic>? roleSpecificData;

  VerificationDetail({
    required this.id,
    required this.profileId,
    required this.userName,
    required this.role,
    required this.verificationType,
    required this.status,
    this.imageUrl,
    this.reviewerNotes,
    required this.createdAt,
    this.reviewedAt,
    this.phone,
    this.address,
    this.age,
    this.sex,
    this.roleSpecificData,
  });

  factory VerificationDetail.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    final attachment = json['attachments'] as Map<String, dynamic>?;

    final firstName = profile?['first_name'] ?? '';
    final lastName = profile?['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();

    return VerificationDetail(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      userName: fullName.isNotEmpty ? fullName : 'Unknown User',
      role: profile?['role'] as String? ?? 'unknown',
      verificationType: json['verification_type'] as String? ?? 'ID Verification',
      status: json['status'] as String,
      imageUrl: attachment?['url'] as String?,
      reviewerNotes: json['reviewer_notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      phone: profile?['phone'] as String?,
      address: profile?['address'] as String?,
      age: profile?['age'] as int?,
      sex: profile?['sex'] as String?,
      roleSpecificData: json['role_specific_data'] as Map<String, dynamic>?,
    );
  }

  /// Get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Get capitalized status
  String get statusCapitalized {
    return status[0].toUpperCase() + status.substring(1);
  }

  /// Get capitalized role
  String get roleCapitalized {
    return role[0].toUpperCase() + role.substring(1);
  }

  /// Get driver-specific data
  String? get licenseNumber => roleSpecificData?['license_number'] as String?;
  String? get vehiclePlate => roleSpecificData?['vehicle_plate'] as String?;
  String? get puvType => roleSpecificData?['puv_type'] as String?;
  String? get operatorName => roleSpecificData?['operator_name'] as String?;

  /// Get commuter-specific data
  String? get commuterCategory => roleSpecificData?['category'] as String?;
  bool? get isIdVerified => roleSpecificData?['id_verified'] as bool?;

  /// Get operator-specific data
  String? get companyName => roleSpecificData?['company_name'] as String?;
  String? get companyAddress => roleSpecificData?['company_address'] as String?;
  String? get contactEmail => roleSpecificData?['contact_email'] as String?;
  String? get contactPhone => roleSpecificData?['contact_phone'] as String?;
}