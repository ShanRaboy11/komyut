import 'package:flutter/material.dart';
import 'dart:io';
import '../models/report.dart';
import '../services/report.dart';

class ReportProvider with ChangeNotifier {
  final ReportService _reportService = ReportService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<Report> _reports = [];
  List<Report> get reports => _reports;

  Report? _currentReport;
  Report? get currentReport => _currentReport;

  // Submit a new report
  Future<bool> submitReport({
    required List<ReportCategory> categories,
    required ReportSeverity severity,
    required String description,
    File? attachmentFile,
    String? reportedEntityType,
    String? reportedEntityId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final report = await _reportService.createReport(
        categories: categories,
        severity: severity,
        description: description,
        attachmentFile: attachmentFile,
        reportedEntityType: reportedEntityType,
        reportedEntityId: reportedEntityId,
      );

      _currentReport = report;
      
      // Refresh the reports list
      await fetchMyReports();

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

  // Fetch all reports for the current user
  Future<void> fetchMyReports() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _reports = await _reportService.getMyReports();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch a specific report by ID
  Future<void> fetchReportById(String reportId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentReport = await _reportService.getReportById(reportId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update report status
  Future<bool> updateReportStatus(
    String reportId,
    ReportStatus newStatus, {
    String? resolutionNotes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedReport = await _reportService.updateReportStatus(
        reportId,
        newStatus,
        resolutionNotes: resolutionNotes,
      );

      _currentReport = updatedReport;

      // Update the report in the list
      final index = _reports.indexWhere((r) => r.id == reportId);
      if (index != -1) {
        _reports[index] = updatedReport;
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

  // Delete a report
  Future<bool> deleteReport(String reportId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _reportService.deleteReport(reportId);

      // Remove from local list
      _reports.removeWhere((r) => r.id == reportId);

      if (_currentReport?.id == reportId) {
        _currentReport = null;
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

  // Fetch reports by status
  Future<void> fetchReportsByStatus(ReportStatus status) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _reports = await _reportService.getReportsByStatus(status);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear current report
  void clearCurrentReport() {
    _currentReport = null;
    notifyListeners();
  }

  // Get reports by category
  List<Report> getReportsByCategory(ReportCategory category) {
    return _reports.where((report) => report.category == category).toList();
  }

  // Get reports by severity
  List<Report> getReportsBySeverity(ReportSeverity severity) {
    return _reports.where((report) => report.severity == severity).toList();
  }

  // Get open reports count
  int get openReportsCount {
    return _reports.where((report) => report.status == ReportStatus.open).length;
  }

  // Get resolved reports count
  int get resolvedReportsCount {
    return _reports.where((report) => report.status == ReportStatus.resolved).length;
  }
}