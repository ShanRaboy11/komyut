// lib/providers/report_provider.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_report.dart';
import '../services/admin_report.dart';

class ReportProvider with ChangeNotifier {
  final ReportService _reportService = ReportService();
  
  List<Report> _reports = [];
  bool _isLoading = false;
  String? _error;
  RealtimeChannel? _realtimeSubscription;

  List<Report> get reports => _reports;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ReportProvider() {
    _subscribeToReports();
  }

  /// Subscribe to real-time updates
  void _subscribeToReports() {
    _realtimeSubscription = _reportService.subscribeToReports((newReport) {
      _reports.insert(0, newReport);
      notifyListeners();
    });
  }

  /// Load reports with optional filters
  Future<void> loadReports({
    ReportSeverity? severity,
    ReportStatus? status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reports = await _reportService.getReports(
        severity: severity,
        status: status,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      _reports = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get filtered reports (client-side filtering for better performance)
  List<Report> getFilteredReports({
    ReportSeverity? severity,
    ReportStatus? status,
  }) {
    var filtered = _reports;

    if (severity != null) {
      filtered = filtered.where((r) => r.severity == severity).toList();
    }

    if (status != null) {
      filtered = filtered.where((r) => r.status == status).toList();
    }

    return filtered;
  }

  /// Update report status
  Future<bool> updateReportStatus(
    String reportId,
    ReportStatus newStatus, {
    String? resolutionNotes,
    String? assignedToProfileId,
  }) async {
    try {
      await _reportService.updateReportStatus(
        reportId,
        newStatus,
        resolutionNotes: resolutionNotes,
        assignedToProfileId: assignedToProfileId,
      );

      // Update local state
      final index = _reports.indexWhere((r) => r.id == reportId);
      if (index != -1) {
        _reports[index] = _reports[index].copyWith(
          status: newStatus,
          resolutionNotes: resolutionNotes ?? _reports[index].resolutionNotes,
          assignedToProfileId: assignedToProfileId ?? _reports[index].assignedToProfileId,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update report severity
  Future<bool> updateReportSeverity(
    String reportId,
    ReportSeverity newSeverity,
  ) async {
    try {
      await _reportService.updateReportSeverity(reportId, newSeverity);

      // Update local state
      final index = _reports.indexWhere((r) => r.id == reportId);
      if (index != -1) {
        _reports[index] = _reports[index].copyWith(
          severity: newSeverity,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete a report
  Future<bool> deleteReport(String reportId) async {
    try {
      await _reportService.deleteReport(reportId);

      // Remove from local state
      _reports.removeWhere((r) => r.id == reportId);
      notifyListeners();

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get report by ID
  Future<Report?> getReportById(String reportId) async {
    try {
      return await _reportService.getReportById(reportId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _realtimeSubscription?.unsubscribe();
    super.dispose();
  }
}