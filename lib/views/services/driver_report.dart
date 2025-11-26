import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/report.dart';

class DriverReportService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all reports assigned to the current driver
  Future<List<Report>> getAssignedReports() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get driver's profile ID
      final profileResponse = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .single();

      final profileId = profileResponse['id'] as String;

      // Get reports assigned to this driver with reporter info and attachment
      final response = await _supabase
          .from('reports')
          .select('''
            *,
            reporter:reporter_profile_id(first_name, last_name),
            attachment:attachment_id(url)
          ''')
          .eq('assigned_to_profile_id', profileId)
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        final report = Report.fromJson(json);
        
        // Add reporter name if available
        if (json['reporter'] != null) {
          final reporter = json['reporter'] as Map<String, dynamic>;
          report.reporterName = 
              '${reporter['first_name']} ${reporter['last_name']}';
        }
        
        // Add attachment URL if available
        if (json['attachment'] != null) {
          final attachment = json['attachment'] as Map<String, dynamic>;
          report.attachmentUrl = attachment['url'] as String?;
        }
        
        return report;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch assigned reports: $e');
    }
  }

  // Get reports filtered by status
  Future<List<Report>> getReportsByStatus(ReportStatus status) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final profileResponse = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .single();

      final profileId = profileResponse['id'] as String;

      final response = await _supabase
          .from('reports')
          .select('''
            *,
            reporter:reporter_profile_id(first_name, last_name),
            attachment:attachment_id(url)
          ''')
          .eq('assigned_to_profile_id', profileId)
          .eq('status', status.value)
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        final report = Report.fromJson(json);
        
        if (json['reporter'] != null) {
          final reporter = json['reporter'] as Map<String, dynamic>;
          report.reporterName = 
              '${reporter['first_name']} ${reporter['last_name']}';
        }
        
        if (json['attachment'] != null) {
          final attachment = json['attachment'] as Map<String, dynamic>;
          report.attachmentUrl = attachment['url'] as String?;
        }
        
        return report;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch reports by status: $e');
    }
  }

  // Get reports filtered by severity
  Future<List<Report>> getReportsBySeverity(ReportSeverity severity) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final profileResponse = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .single();

      final profileId = profileResponse['id'] as String;

      final response = await _supabase
          .from('reports')
          .select('''
            *,
            reporter:reporter_profile_id(first_name, last_name),
            attachment:attachment_id(url)
          ''')
          .eq('assigned_to_profile_id', profileId)
          .eq('severity', severity.value)
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        final report = Report.fromJson(json);
        
        if (json['reporter'] != null) {
          final reporter = json['reporter'] as Map<String, dynamic>;
          report.reporterName = 
              '${reporter['first_name']} ${reporter['last_name']}';
        }
        
        if (json['attachment'] != null) {
          final attachment = json['attachment'] as Map<String, dynamic>;
          report.attachmentUrl = attachment['url'] as String?;
        }
        
        return report;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch reports by severity: $e');
    }
  }

  // Get a specific report by ID
  Future<Report?> getReportById(String reportId) async {
    try {
      final response = await _supabase
          .from('reports')
          .select('''
            *,
            reporter:reporter_profile_id(first_name, last_name),
            attachment:attachment_id(url)
          ''')
          .eq('id', reportId)
          .single();

      final report = Report.fromJson(response);
      
      if (response['reporter'] != null) {
        final reporter = response['reporter'] as Map<String, dynamic>;
        report.reporterName = 
            '${reporter['first_name']} ${reporter['last_name']}';
      }
      
      if (response['attachment'] != null) {
        final attachment = response['attachment'] as Map<String, dynamic>;
        report.attachmentUrl = attachment['url'] as String?;
      }
      
      return report;
    } catch (e) {
      throw Exception('Failed to fetch report: $e');
    }
  }

  // Update report status (driver can mark as in_review or add notes)
  Future<Report> updateReportStatus(
    String reportId,
    ReportStatus newStatus, {
    String? resolutionNotes,
  }) async {
    try {
      final updateData = {
        'status': newStatus.value,
        if (resolutionNotes != null) 'resolution_notes': resolutionNotes,
      };

      final response = await _supabase
          .from('reports')
          .update(updateData)
          .eq('id', reportId)
          .select('''
            *,
            reporter:reporter_profile_id(first_name, last_name),
            attachment:attachment_id(url)
          ''')
          .single();

      final report = Report.fromJson(response);
      
      if (response['reporter'] != null) {
        final reporter = response['reporter'] as Map<String, dynamic>;
        report.reporterName = 
            '${reporter['first_name']} ${reporter['last_name']}';
      }
      
      if (response['attachment'] != null) {
        final attachment = response['attachment'] as Map<String, dynamic>;
        report.attachmentUrl = attachment['url'] as String?;
      }
      
      return report;
    } catch (e) {
      throw Exception('Failed to update report status: $e');
    }
  }

  // Get report counts by status (for dashboard)
  Future<Map<String, int>> getReportCounts() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final profileResponse = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .single();

      final profileId = profileResponse['id'] as String;

      final response = await _supabase
          .from('reports')
          .select('status')
          .eq('assigned_to_profile_id', profileId);

      final counts = <String, int>{
        'open': 0,
        'in_review': 0,
        'resolved': 0,
        'dismissed': 0,
        'closed': 0,
      };

      for (final report in response as List) {
        final status = report['status'] as String;
        counts[status] = (counts[status] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      throw Exception('Failed to fetch report counts: $e');
    }
  }
}