import 'package:flutter/material.dart';
import '../models/report.dart';
import '../services/driver_report.dart';

class DriverReportProvider extends ChangeNotifier {
  final DriverReportService _reportService = DriverReportService();

  List<Report> _reports = [];
  bool _isLoading = false;
  String? _error;
  Map<String, int> _reportCounts = {};

  List<Report> get reports => _reports;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, int> get reportCounts => _reportCounts;

  // Fetch all assigned reports
  Future<void> fetchAssignedReports() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reports = await _reportService.getAssignedReports();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _reports = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch reports by status
  Future<void> fetchReportsByStatus(ReportStatus status) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reports = await _reportService.getReportsByStatus(status);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _reports = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch reports by severity
  Future<void> fetchReportsBySeverity(ReportSeverity severity) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reports = await _reportService.getReportsBySeverity(severity);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _reports = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch report counts
  Future<void> fetchReportCounts() async {
    try {
      _reportCounts = await _reportService.getReportCounts();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Update report status
  Future<bool> updateReportStatus(
    String reportId,
    ReportStatus newStatus, {
    String? resolutionNotes,
  }) async {
    try {
      final updatedReport = await _reportService.updateReportStatus(
        reportId,
        newStatus,
        resolutionNotes: resolutionNotes,
      );

      // Update the report in the list
      final index = _reports.indexWhere((r) => r.id == reportId);
      if (index != -1) {
        _reports[index] = updatedReport;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Sort reports by date
  void sortByDate({bool ascending = false}) {
    // Use a safe comparison for nullable DateTime fields. When a date is
    // missing, treat it as epoch (1970-01-01) so it sorts consistently.
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    _reports.sort((a, b) {
      final aDate = a.createdAt ?? epoch;
      final bDate = b.createdAt ?? epoch;
      return ascending ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
    });
    notifyListeners();
  }

  // Sort reports by severity (High -> Medium -> Low)
  void sortBySeverity() {
    const severityOrder = {
      ReportSeverity.high: 3,
      ReportSeverity.medium: 2,
      ReportSeverity.low: 1,
    };

    _reports.sort((a, b) {
      return severityOrder[b.severity]!.compareTo(severityOrder[a.severity]!);
    });
    notifyListeners();
  }

  // Filter reports by category
  List<Report> getReportsByCategory(ReportCategory category) {
    return _reports.where((r) => r.category == category).toList();
  }

  // Get report by ID from cached list
  Report? getReportById(String reportId) {
    try {
      return _reports.firstWhere((r) => r.id == reportId);
    } catch (e) {
      return null;
    }
  }

  // Refresh data
  Future<void> refresh() async {
    await fetchAssignedReports();
    await fetchReportCounts();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}