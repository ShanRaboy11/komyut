import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/report.dart';
import '../models/operator_report.dart';

class OperatorReportService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all reports assigned to drivers under the current operator
  Future<List<OperatorReport>> getOperatorReports({
    ReportSeverity? filterBySeverity,
    ReportStatus? filterByStatus,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get operator's profile ID
      final profileResponse = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .eq('role', 'operator')
          .single();

      final profileId = profileResponse['id'] as String;

      // Get operator record
      final operatorResponse = await _supabase
          .from('operators')
          .select('id')
          .eq('profile_id', profileId)
          .single();

      final operatorId = operatorResponse['id'] as String;

      // Build query to get reports assigned to operator's drivers
      var query = _supabase
          .from('reports')
          .select('''
            *,
            reporter:profiles!reports_reporter_profile_id_fkey(
              id,
              first_name,
              last_name,
              role
            ),
            assigned_driver:profiles!reports_assigned_to_profile_id_fkey(
              id,
              first_name,
              last_name,
              role,
              drivers(
                id,
                license_number,
                vehicle_plate,
                operator_id,
                routes:route_id (
                  code
                )
              )
            ),
            attachment:attachments(
              id,
              url,
              content_type
            )
          ''')
          .eq('assigned_driver.drivers.operator_id', operatorId)
          .order('created_at', ascending: false);

      final response = await query;

      // Filter out reports where the driver doesn't belong to this operator
      var filteredReports = (response as List).where((reportJson) {
        final assignedDriver = reportJson['assigned_driver'];
        if (assignedDriver == null) return false;
        
        final drivers = assignedDriver['drivers'];
        if (drivers == null) return false;
        
        // For single driver record
        if (drivers is Map) {
          return drivers['operator_id'] == operatorId;
        }
        
        // For list of drivers (shouldn't happen but handle it)
        if (drivers is List && drivers.isNotEmpty) {
          return drivers.first['operator_id'] == operatorId;
        }
        
        return false;
      }).toList();

      // Apply optional severity/status filters on the client side (workaround for postgrest builder differences)
      if (filterBySeverity != null) {
        filteredReports = filteredReports.where((r) => (r['severity'] as String?) == filterBySeverity.value).toList();
      }

      if (filterByStatus != null) {
        filteredReports = filteredReports.where((r) => (r['status'] as String?) == filterByStatus.value).toList();
      }

      return filteredReports
          .map((json) => OperatorReport.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch operator reports: $e');
    }
  }

  /// Get report counts by severity for the operator's drivers
  Future<Map<ReportSeverity, int>> getReportCountsBySeverity() async {
    try {
      final reports = await getOperatorReports();
      
      final counts = <ReportSeverity, int>{
        ReportSeverity.low: 0,
        ReportSeverity.medium: 0,
        ReportSeverity.high: 0,
      };

      for (final report in reports) {
        counts[report.report.severity] = (counts[report.report.severity] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      throw Exception('Failed to get report counts: $e');
    }
  }

  /// Get report counts by status for the operator's drivers
  Future<Map<ReportStatus, int>> getReportCountsByStatus() async {
    try {
      final reports = await getOperatorReports();
      
      final counts = <ReportStatus, int>{};

      for (final report in reports) {
        counts[report.report.status] = (counts[report.report.status] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      throw Exception('Failed to get status counts: $e');
    }
  }

  /// Get a specific report with full details
  Future<OperatorReport?> getReportById(String reportId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final profileResponse = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .eq('role', 'operator')
          .single();

      final profileId = profileResponse['id'] as String;

      final operatorResponse = await _supabase
          .from('operators')
          .select('id')
          .eq('profile_id', profileId)
          .single();

      final operatorId = operatorResponse['id'] as String;

      final response = await _supabase
          .from('reports')
          .select('''
            *,
            reporter:profiles!reports_reporter_profile_id_fkey(
              id,
              first_name,
              last_name,
              role
            ),
            assigned_driver:profiles!reports_assigned_to_profile_id_fkey(
              id,
              first_name,
              last_name,
              role,
              drivers(
                id,
                license_number,
                vehicle_plate,
                operator_id,
                routes:route_id (
                  code,
                  name
                )
              )
            ),
            attachment:attachments(
              id,
              url,
              content_type
            )
          ''')
          .eq('id', reportId)
          .single();

      // Verify the report is assigned to one of operator's drivers
      final assignedDriver = response['assigned_driver'];
      if (assignedDriver != null) {
        final drivers = assignedDriver['drivers'];
        if (drivers != null) {
          final driverOperatorId = drivers is Map 
              ? drivers['operator_id'] 
              : (drivers as List).first['operator_id'];
          
          if (driverOperatorId == operatorId) {
            return OperatorReport.fromJson(response);
          }
        }
      }

      return null;
    } catch (e) {
      throw Exception('Failed to fetch report: $e');
    }
  }

  /// Update report status (operator can update status)
  Future<OperatorReport> updateReportStatus(
    String reportId,
    ReportStatus newStatus, {
    String? resolutionNotes,
  }) async {
    try {
      final updateData = {
        'status': newStatus.value,
        if (resolutionNotes != null) 'resolution_notes': resolutionNotes,
      };

      await _supabase
          .from('reports')
          .update(updateData)
          .eq('id', reportId);

      final updatedReport = await getReportById(reportId);
      if (updatedReport == null) {
        throw Exception('Report not found after update');
      }

      return updatedReport;
    } catch (e) {
      throw Exception('Failed to update report status: $e');
    }
  }
}