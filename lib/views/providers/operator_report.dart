import 'package:flutter/material.dart';
import '../models/report.dart';
import '../models/operator_report.dart';
import '../services/operator_report.dart';

class OperatorReportProvider with ChangeNotifier {
  final OperatorReportService _service = OperatorReportService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<OperatorReport> _reports = [];
  List<OperatorReport> get reports => _reports;

  OperatorReport? _selectedReport;
  OperatorReport? get selectedReport => _selectedReport;

  Map<ReportSeverity, int> _severityCounts = {};
  Map<ReportSeverity, int> get severityCounts => _severityCounts;

  Map<ReportStatus, int> _statusCounts = {};
  Map<ReportStatus, int> get statusCounts => _statusCounts;

  ReportSeverity? _filterSeverity;
  ReportSeverity? get filterSeverity => _filterSeverity;

  ReportStatus? _filterStatus;
  ReportStatus? get filterStatus => _filterStatus;

  /// Fetch all reports for operator's drivers
  Future<void> fetchReports({
    ReportSeverity? severity,
    ReportStatus? status,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _filterSeverity = severity;
    _filterStatus = status;
    notifyListeners();

    try {
      _reports = await _service.getOperatorReports(
        filterBySeverity: severity,
        filterByStatus: status,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch report counts by severity
  Future<void> fetchSeverityCounts() async {
    try {
      _severityCounts = await _service.getReportCountsBySeverity();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Fetch report counts by status
  Future<void> fetchStatusCounts() async {
    try {
      _statusCounts = await _service.getReportCountsByStatus();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Fetch a specific report by ID
  Future<void> fetchReportById(String reportId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedReport = await _service.getReportById(reportId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update report status
  Future<bool> updateReportStatus(
    String reportId,
    ReportStatus newStatus, {
    String? resolutionNotes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedReport = await _service.updateReportStatus(
        reportId,
        newStatus,
        resolutionNotes: resolutionNotes,
      );

      _selectedReport = updatedReport;

      // Update in the list
      final index = _reports.indexWhere((r) => r.report.id == reportId);
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

  /// Filter reports by severity
  List<OperatorReport> getReportsBySeverity(ReportSeverity severity) {
    return _reports
        .where((report) => report.report.severity == severity)
        .toList();
  }

  /// Filter reports by status
  List<OperatorReport> getReportsByStatus(ReportStatus status) {
    return _reports
        .where((report) => report.report.status == status)
        .toList();
  }

  /// Get reports for a specific driver
  List<OperatorReport> getReportsByDriver(String driverProfileId) {
    return _reports
        .where((report) => report.report.assignedToProfileId == driverProfileId)
        .toList();
  }

  /// Get count of reports by severity
  int getCountBySeverity(ReportSeverity severity) {
    return _severityCounts[severity] ?? 0;
  }

  /// Get count of reports by status
  int getCountByStatus(ReportStatus status) {
    return _statusCounts[status] ?? 0;
  }

  /// Get total open reports count
  int get openReportsCount {
    return getCountByStatus(ReportStatus.open);
  }

  /// Get total in-review reports count
  int get inReviewReportsCount {
    return getCountByStatus(ReportStatus.inReview);
  }

  /// Get total resolved reports count
  int get resolvedReportsCount {
    return getCountByStatus(ReportStatus.resolved);
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear selected report
  void clearSelectedReport() {
    _selectedReport = null;
    notifyListeners();
  }

  /// Set filter severity
  Future<void> setFilterSeverity(ReportSeverity? severity) async {
    await fetchReports(severity: severity, status: _filterStatus);
  }

  /// Set filter status
  Future<void> setFilterStatus(ReportStatus? status) async {
    await fetchReports(severity: _filterSeverity, status: status);
  }

  /// Clear all filters
  Future<void> clearFilters() async {
    await fetchReports();
  }

  /// Refresh all data
  Future<void> refresh() async {
    await Future.wait([
      fetchReports(severity: _filterSeverity, status: _filterStatus),
      fetchSeverityCounts(),
      fetchStatusCounts(),
    ]);
  }
}