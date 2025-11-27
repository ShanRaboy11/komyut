import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/report.dart';
import 'package:provider/provider.dart';
import '../widgets/commutercard_report.dart';
import '../providers/driver_reports.dart';
import '../services/driver_report.dart';
import '../widgets/role_navbar_wrapper.dart';
import 'home_driver.dart';
import 'activity_driver.dart';
import 'profile.dart';
import 'notification_commuter.dart';
import 'feedback_driver.dart';

class ReportDetailsPage extends StatefulWidget {
  final String name;
  final String role;
  final String reporterId; // profile id of the reporter (for display)
  final String reportId; // the actual report id used for backend updates
  final String? priority;
  final String date;
  final String description;
  final List<String> tags;
  final String? imagePath;
  final String? attachmentId;

  const ReportDetailsPage({
    super.key,
    required this.name,
    required this.role,
    required this.reporterId,
    required this.reportId,
    this.priority,
    required this.date,
    required this.description,
    required this.tags,
    this.imagePath,
    this.attachmentId,
  });

  @override
  State<ReportDetailsPage> createState() => _ReportDetailsPageState();
}

class _ReportDetailsPageState extends State<ReportDetailsPage> {
  bool _isUpdating = false;

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFFF6B6B);
      case 'medium':
        return const Color(0xFFFFB84D);
      case 'low':
        return const Color(0xFF6BCB77);
      default:
        return Colors.grey;
    }
  }

  // TODO: hide mark-as-resolved if report status is already resolved/closed.

  Future<void> _markAsResolved() async {
    // Confirm then update via provider/service
    if (!mounted) return;
    setState(() => _isUpdating = true);
    try {
      final provider = Provider.of<DriverReportProvider>(context, listen: false);
      bool success = false;
      try {
        success = await provider.updateReportStatus(widget.reportId, ReportStatus.resolved);
      } catch (_) {
        success = false;
      }

      if (!success) {
        // Fallback to direct service call
        final svc = DriverReportService();
        await svc.updateReportStatus(widget.reportId, ReportStatus.resolved);
        success = true;
      }

      if (mounted && success) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Report marked as resolved.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );

        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (ctx) => const DriverNavBarWrapper(
              homePage: DriverDashboardNav(),
              activityPage: DriverActivityPage(),
              feedbackPage: DriverFeedbackPage(),
              notificationsPage: NotificationPage(),
              profilePage: ProfilePage(),
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update report: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final originalDate = DateFormat('MM/dd/yy').parse(widget.date);
    final formattedDate = DateFormat('EEE, d MMM. yyyy').format(originalDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date and Priority
            Stack(
              alignment: Alignment.center,
              children: [
                // Back button (aligned to the left)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.black87,
                    ),
                  ),
                ),

                // Centered title
                Text(
                  "Reports",
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
            Text(
              "Report Details",
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedDate,
                  style: GoogleFonts.manrope(
                    color: Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (widget.priority != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(
                        widget.priority!,
                      ).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.priority!,
                      style: GoogleFonts.manrope(
                        color: _getPriorityColor(widget.priority!),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Profile Card
            ProfileCard(name: widget.name, role: widget.role, id: widget.reporterId),

            const SizedBox(height: 20),

            // Description Label
            Text(
              "Description",
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // Description Text
            Text(
              widget.description,
              style: GoogleFonts.manrope(
                fontSize: 12,
                height: 1.4,
                color: Colors.black87.withValues(alpha: 0.8),
              ),
            ),

            const SizedBox(height: 16),

            // Tags
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: widget.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBD9FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                    child: Text(
                    tag,
                    style: GoogleFonts.manrope(
                      color: const Color(0xFF7A3DB8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 25),

            // Attachment Label
            Text(
              "Attachment",
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),

            // Image Attachment
            if (widget.imagePath != null && widget.imagePath!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  widget.imagePath!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.image_not_supported, size: 36, color: Colors.grey[600]),
                      const SizedBox(height: 8),
                      Text('No attachment', style: GoogleFonts.manrope(color: Colors.grey[600])),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Mark as Resolved Button
            if (_isUpdating)
              const Center(child: CircularProgressIndicator(color: Color(0xFF8E4CB6)))
            else
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B53C2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  ),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirm'),
                        content: const Text('Are you sure you want to mark this report as resolved?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
                        ],
                      ),
                    );

                    if (confirm == true) await _markAsResolved();
                  },
                  child: Text('Mark as Resolved', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
