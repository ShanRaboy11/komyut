import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/report.dart';
import 'package:provider/provider.dart';
import 'dart:io';
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
      final provider = Provider.of<DriverReportProvider>(
        context,
        listen: false,
      );
      bool success = false;
      try {
        success = await provider.updateReportStatus(
          widget.reportId,
          ReportStatus.resolved,
        );
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
          builder:
              (dialogCtx) => AlertDialog(
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
            builder:
                (ctx) => const DriverNavBarWrapper(
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update report: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  late final Future<String?> _attachmentUrlFuture;

  @override
  void initState() {
    super.initState();
    _attachmentUrlFuture = _resolveAttachmentUrl();
  }

  Future<String?> _resolveAttachmentUrl() async {
    if (widget.imagePath != null && widget.imagePath!.isNotEmpty) {
      return widget.imagePath!;
    }
    if (widget.attachmentId != null && widget.attachmentId!.isNotEmpty) {
      try {
        final svc = DriverReportService();
        final report = await svc.getReportById(widget.reportId);
        return report?.attachmentUrl;
      } catch (_) {
        return null;
      }
    }
    return null;
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
            ProfileCard(
              name: widget.name,
              role: widget.role,
              id: widget.reporterId,
            ),

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
              children:
                  widget.tags.map((tag) {
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

            // Image Attachment (resolved via imagePath or attachmentId)
            FutureBuilder<String?>(
              future: _attachmentUrlFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    width: double.infinity,
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF8E4CB6),
                      ),
                    ),
                  );
                }

                final path = snapshot.data;
                if (path != null && path.isNotEmpty) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 220,
                      child: Builder(
                        builder: (ctx) {
                          if (path.startsWith('http')) {
                            return Image.network(
                              path,
                              width: double.infinity,
                              height: 220,
                              fit: BoxFit.cover,
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF8E4CB6),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.broken_image,
                                        size: 96,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Unable to load image',
                                        style: GoogleFonts.manrope(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          } else if (path.startsWith('/') ||
                              path.startsWith('file:')) {
                            try {
                              final filePath =
                                  path.startsWith('file://')
                                      ? path.replaceFirst('file://', '')
                                      : path;
                              return Image.file(
                                File(filePath),
                                width: double.infinity,
                                height: 220,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.broken_image,
                                          size: 96,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Unable to load image',
                                          style: GoogleFonts.manrope(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            } catch (e) {
                              return Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      size: 96,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Unable to load image',
                                      style: GoogleFonts.manrope(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          } else {
                            return Image.asset(
                              path,
                              width: double.infinity,
                              height: 220,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.broken_image,
                                        size: 96,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Unable to load image',
                                        style: GoogleFonts.manrope(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          }
                        },
                      ),
                    ),
                  );
                }

                return Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          size: 96,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No attachment',
                          style: GoogleFonts.manrope(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 35),

            // Mark as Resolved Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUpdating ? null : _markAsResolved,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8E4CB6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isUpdating
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : Text(
                          "Mark as Resolved",
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}