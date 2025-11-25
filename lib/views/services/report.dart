import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../models/report.dart';

class ReportService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Create a new report
  Future<Report> createReport({
    required List<ReportCategory> categories,
    required ReportSeverity severity,
    required String description,
    File? attachmentFile,
    String? reportedEntityType,
    String? reportedEntityId,
  }) async {
    try {
      // Get current user's profile ID
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

      String? attachmentId;

      // Upload attachment if provided
      if (attachmentFile != null) {
        attachmentId = await _uploadAttachment(attachmentFile, profileId);
      }

      // Create reports for each selected category
      final List<Report> createdReports = [];
      
      for (final category in categories) {
        final reportData = {
          'reporter_profile_id': profileId,
          'category': category.value,
          'severity': severity.value,
          'description': description,
          'status': 'open',
          if (attachmentId != null) 'attachment_id': attachmentId,
          if (reportedEntityType != null) 'reported_entity_type': reportedEntityType,
          if (reportedEntityId != null) 'reported_entity_id': reportedEntityId,
        };

        final response = await _supabase
            .from('reports')
            .insert(reportData)
            .select()
            .single();

        createdReports.add(Report.fromJson(response));
      }

      // Return the first created report (or you can return all if needed)
      return createdReports.first;
    } catch (e) {
      throw Exception('Failed to create report: $e');
    }
  }

  // Upload attachment to Supabase Storage
  Future<String> _uploadAttachment(File file, String profileId) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final filePath = 'reports/$profileId/$fileName';

      // Upload to storage
      await _supabase.storage
          .from('attachments')
          .upload(filePath, file);

      // Get public URL
      final publicUrl = _supabase.storage
          .from('attachments')
          .getPublicUrl(filePath);

      // Create attachment record
      final attachmentData = {
        'owner_profile_id': profileId,
        'bucket': 'attachments',
        'path': filePath,
        'url': publicUrl,
        'content_type': _getContentType(file.path),
        'size_bytes': await file.length(),
      };

      final response = await _supabase
          .from('attachments')
          .insert(attachmentData)
          .select()
          .single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Failed to upload attachment: $e');
    }
  }

  // Get content type from file extension
  String _getContentType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  // Get all reports for current user
  Future<List<Report>> getMyReports() async {
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
          .select()
          .eq('reporter_profile_id', profileId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Report.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch reports: $e');
    }
  }

  // Get a specific report by ID
  Future<Report?> getReportById(String reportId) async {
    try {
      final response = await _supabase
          .from('reports')
          .select()
          .eq('id', reportId)
          .single();

      return Report.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch report: $e');
    }
  }

  // Update report status (for admin use)
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
          .select()
          .single();

      return Report.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update report status: $e');
    }
  }

  // Delete a report (only if in 'open' status)
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

  // Get reports by status
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
          .select()
          .eq('reporter_profile_id', profileId)
          .eq('status', status.value)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Report.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch reports by status: $e');
    }
  }
}