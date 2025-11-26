// lib/services/report_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_report.dart';

class ReportService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all reports with optional filtering
  Future<List<Report>> getReports({
    ReportSeverity? severity,
    ReportStatus? status,
  }) async {
    try {
        dynamic query = _supabase
          .from('reports')
          .select('''
            *,
            reporter:reporter_profile_id(
              first_name,
              last_name,
              role
            ),
            attachment:attachment_id(
              url,
              path
            )
          ''')
          .order('created_at', ascending: false);

      if (severity != null) {
        query = query.eq('severity', severity.value);
      }

      if (status != null) {
        query = query.eq('status', status.value);
      }

      final response = await query;
      
      return (response as List).map((json) {
        // Flatten the nested reporter data
        final reporterData = json['reporter'] as Map<String, dynamic>?;
        final attachmentData = json['attachment'] as Map<String, dynamic>?;
        
        return Report.fromJson({
          ...json,
          'reporter_name': reporterData != null 
              ? '${reporterData['first_name']} ${reporterData['last_name']}'
              : null,
          'reporter_role': reporterData?['role'] as String?,
          'attachment_url': attachmentData?['url'] as String?,
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch reports: $e');
    }
  }

  /// Get a single report by ID
  Future<Report?> getReportById(String reportId) async {
    try {
      final response = await _supabase
          .from('reports')
          .select('''
            *,
            reporter:reporter_profile_id(
              first_name,
              last_name,
              role
            ),
            attachment:attachment_id(
              url,
              path
            )
          ''')
          .eq('id', reportId)
          .maybeSingle();

      if (response == null) return null;

      final reporterData = response['reporter'] as Map<String, dynamic>?;
      final attachmentData = response['attachment'] as Map<String, dynamic>?;

      return Report.fromJson({
        ...response,
        'reporter_name': reporterData != null 
            ? '${reporterData['first_name']} ${reporterData['last_name']}'
            : null,
        'reporter_role': reporterData?['role'] as String?,
        'attachment_url': attachmentData?['url'] as String?,
      });
    } catch (e) {
      throw Exception('Failed to fetch report: $e');
    }
  }

  /// Update report status
  Future<void> updateReportStatus(
    String reportId,
    ReportStatus newStatus, {
    String? resolutionNotes,
    String? assignedToProfileId,
  }) async {
    try {
      final updateData = {
        'status': newStatus.value,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (resolutionNotes != null) {
        updateData['resolution_notes'] = resolutionNotes;
      }

      if (assignedToProfileId != null) {
        updateData['assigned_to_profile_id'] = assignedToProfileId;
      }

      await _supabase
          .from('reports')
          .update(updateData)
          .eq('id', reportId);
    } catch (e) {
      throw Exception('Failed to update report status: $e');
    }
  }

  /// Update report severity
  Future<void> updateReportSeverity(
    String reportId,
    ReportSeverity newSeverity,
  ) async {
    try {
      await _supabase
          .from('reports')
          .update({
            'severity': newSeverity.value,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', reportId);
    } catch (e) {
      throw Exception('Failed to update report severity: $e');
    }
  }

  /// Delete a report
  Future<void> deleteReport(String reportId) async {
    try {
      await _supabase
          .from('reports')
          .delete()
          .eq('id', reportId);
    } catch (e) {
      throw Exception('Failed to delete report: $e');
    }
  }

  /// Get reports count by status
  Future<Map<String, int>> getReportsCountByStatus() async {
    try {
      final response = await _supabase
          .from('reports')
          .select('status')
          .order('created_at', ascending: false);

      final counts = <String, int>{};
      for (final status in ReportStatus.values) {
        counts[status.value] = 0;
      }

      for (final item in (response as List)) {
        final status = item['status'] as String;
        counts[status] = (counts[status] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      throw Exception('Failed to get report counts: $e');
    }
  }

  /// Subscribe to real-time report updates
  RealtimeChannel subscribeToReports(void Function(Report report) onNewReport) {
    return _supabase
        .channel('reports_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'reports',
          callback: (payload) async {
            final reportId = payload.newRecord['id'] as String;
            final report = await getReportById(reportId);
            if (report != null) {
              onNewReport(report);
            }
          },
        )
        .subscribe();
  }
}