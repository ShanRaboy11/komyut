import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../widgets/commutercard_report.dart';
import '../widgets/button.dart';
import '../providers/operator_report.dart';
import '../models/report.dart';
import 'report_operator.dart';

class ReportDetailsPage extends StatefulWidget {
  final String name;
  final String? role;
  final String id;
  final String? priority;
  final String date;
  final String description;
  final List<String> tags;
  final String? attachmentId; // ID in attachments table (nullable)
  final String? initialAttachmentUrl; // optional already-fetched URL
  final String? driverName;
  final String? vehiclePlate;
  final String? routeCode;
  final String? status;
  final Future<void> Function()? onResolved;

  const ReportDetailsPage({
    super.key,
    required this.name,
    this.role,
    required this.id,
    this.priority,
    required this.date,
    required this.description,
    required this.tags,
    this.attachmentId,
    this.initialAttachmentUrl,
    this.driverName,
    this.vehiclePlate,
    this.routeCode,
    this.status,
    this.onResolved,
  });

  @override
  State<ReportDetailsPage> createState() => _ReportDetailsPageState();
}

class _ReportDetailsPageState extends State<ReportDetailsPage> {
  String? _attachmentUrl;
  String? _attachmentContentType;
  bool _loadingAttachment = false;
  bool _updatingStatus = false;

  bool _isImage() {
    final ct = _attachmentContentType ?? '';
    if (ct.startsWith('image/')) return true;
    final url = _attachmentUrl?.toLowerCase() ?? '';
    return url.endsWith('.jpg') ||
        url.endsWith('.jpeg') ||
        url.endsWith('.png') ||
        url.endsWith('.gif') ||
        url.endsWith('.webp');
  }

  @override
  void initState() {
    super.initState();
    // Logic to handle attachment fetching or URL signing
    if (widget.initialAttachmentUrl != null &&
        widget.initialAttachmentUrl!.isNotEmpty) {
      _attachmentUrl = widget.initialAttachmentUrl;
      _attachmentContentType = null;
      if ((_attachmentUrl == null || _attachmentUrl!.isEmpty) &&
          widget.attachmentId != null &&
          widget.attachmentId!.isNotEmpty) {
        _fetchAttachment(widget.attachmentId!);
      }
    } else if (widget.attachmentId != null && widget.attachmentId!.isNotEmpty) {
      _fetchAttachment(widget.attachmentId!);
    }
  }

  Future<void> _fetchAttachment(String attachmentId) async {
    try {
      setState(() => _loadingAttachment = true);
      final client = Supabase.instance.client;
      final resp = await client
          .from('attachments')
          .select('id, url, content_type, path, bucket')
          .eq('id', attachmentId)
          .maybeSingle();

      if (resp is Map<String, dynamic>) {
        final url = resp['url'] as String?;
        final contentType = resp['content_type'] as String?;
        final path = resp['path'] as String?;
        final bucket = resp['bucket'] as String? ?? 'attachments';

        if (url != null && url.isNotEmpty) {
          setState(() {
            _attachmentUrl = url;
            _attachmentContentType = contentType;
          });
        } else if (path != null && path.isNotEmpty) {
          try {
            final signed =
                await client.storage.from(bucket).createSignedUrl(path, 60);
            if (signed.isNotEmpty) {
              setState(() {
                _attachmentUrl = signed;
                _attachmentContentType = contentType;
              });
            }
          } catch (e) {
            debugPrint('Failed to create signed URL: $e');
          }
        }
      }
    } catch (e) {
      // ignore errors; leave _attachmentUrl null
    } finally {
      if (mounted) setState(() => _loadingAttachment = false);
    }
  }

  Future<void> _updateReportStatus(ReportStatus newStatus) async {
    setState(() => _updatingStatus = true);
    try {
      final provider = context.read<OperatorReportProvider>();
      
      // 1. Update Database
      final success = await provider.updateReportStatus(widget.id, newStatus);

      if (success) {
        // 2. Refresh Provider Data Immediately
        // This ensures the data is fresh in memory before we even leave this page
        try {
          await provider.fetchReports(
            severity: provider.filterSeverity,
            status: provider.filterStatus,
          );
          await provider.fetchSeverityCounts();
          await provider.fetchStatusCounts();
        } catch (_) {}

        // 3. Callback (if parent passed one)
        if (widget.onResolved != null) {
          try {
            await widget.onResolved!();
          } catch (_) {}
        }

        if (mounted) {
          // 4. Show Success Dialog
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Success'),
              content:
                  Text('Report Marked as ${ReportStatus.resolved.displayName}.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );

            // 5. CRITICAL: Navigate to the Reports list with a fresh provider
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (ctx) => ChangeNotifierProvider<OperatorReportProvider>(
                    create: (_) {
                      final p = OperatorReportProvider();
                      // Kick off an initial fetch immediately
                      p.fetchReports();
                      p.fetchSeverityCounts();
                      p.fetchStatusCounts();
                      return p;
                    },
                    child: OperatorReportsPage(),
                  ),
                ),
                (route) => false,
              );
            }
        }
      } else {
        if (mounted) {
          await showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Error'),
              content: const Text('Failed to update report.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('OK'),
                )
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to update report: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              )
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingStatus = false);
    }
  }

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

  void _openFullScreenImage(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        final maxW = MediaQuery.of(context).size.width * 0.95;
        final maxH = MediaQuery.of(context).size.height * 0.85;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Center(
            child: Hero(
              tag: 'attachment_${widget.attachmentId ?? _attachmentUrl}',
              child: Container(
                constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F4FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF7A3DB8), width: 2),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: InteractiveViewer(
                        panEnabled: true,
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Image.network(
                          url,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.broken_image,
                                    color: Colors.grey, size: 48),
                                const SizedBox(height: 8),
                                Text('Failed to load image',
                                    style: GoogleFonts.manrope(
                                        color: Colors.grey[700])),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF7A3DB8)),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final originalDate = DateFormat('MM/dd/yy').parse(widget.date);
    final formattedDate = DateFormat('EEE, d MMM. yyyy').format(originalDate);

    // Determine if the report is already finished
    final bool isResolvedOrClosed = widget.status != null &&
        (widget.status!.toLowerCase() == 'resolved' ||
            widget.status!.toLowerCase() == 'closed' ||
            widget.status!.toLowerCase() == 'dismissed');

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
                    fontSize: 14,
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
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ProfileCard(
                name: widget.name,
                role: widget.role ?? "Unknown",
                id: widget.id),
            const SizedBox(height: 20),
            Text(
              "Description",
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.description,
              style: GoogleFonts.manrope(
                fontSize: 14,
                height: 1.4,
                color: Colors.black87.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: widget.tags.map((tag) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2EAFE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.manrope(
                      color: const Color(0xFF7A3DB8),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 25),
            if (widget.driverName != null ||
                widget.vehiclePlate != null ||
                widget.routeCode != null ||
                widget.status != null) ...[
              Text(
                "Driver Details",
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              if (widget.driverName != null)
                Text('Driver: ${widget.driverName}',
                    style: GoogleFonts.manrope(fontSize: 14)),
              if (widget.vehiclePlate != null)
                Text('Vehicle Plate: ${widget.vehiclePlate}',
                    style: GoogleFonts.manrope(fontSize: 14)),
              if (widget.routeCode != null)
                Text('Route: ${widget.routeCode}',
                    style: GoogleFonts.manrope(fontSize: 14)),
              if (widget.status != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Status: ${widget.status}',
                      style: GoogleFonts.manrope(fontSize: 14)),
                ),
              const SizedBox(height: 16),
            ],
            Text(
              "Attachment",
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            if (_loadingAttachment) ...[
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: (MediaQuery.of(context).size.width * 0.86)
                          .clamp(0, 420),
                      height: 220,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border:
                            Border.all(color: Colors.grey.shade300, width: 2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 140,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_attachmentUrl != null &&
                _attachmentUrl!.isNotEmpty) ...[
              if (_isImage()) ...[
                InkWell(
                  onTap: () {
                    if (_attachmentUrl != null && _attachmentUrl!.isNotEmpty) {
                      _openFullScreenImage(_attachmentUrl!);
                    }
                  },
                  child: Hero(
                    tag: 'attachment_${widget.attachmentId ?? _attachmentUrl}',
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: const Color(0xFF7A3DB8), width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          _attachmentUrl!,
                          width: (MediaQuery.of(context).size.width * 0.86)
                              .clamp(0, 420),
                          height: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: double.infinity,
                            height: 180,
                            color: Colors.grey.shade200,
                            child: Center(
                              child: Text('Failed to load attachment',
                                  style: GoogleFonts.manrope(
                                      color: Colors.grey[600])),
                            ),
                          ),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              width: double.infinity,
                              height: 180,
                              color: Colors.grey.shade100,
                              child: const Center(
                                  child: CircularProgressIndicator()),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'View attachment',
                          style: GoogleFonts.manrope(
                              fontSize: 14, color: Colors.black87),
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final url = _attachmentUrl;
                          if (url != null && url.isNotEmpty) {
                            await showDialog<void>(
                              context: context,
                              builder: (d) => AlertDialog(
                                title: const Text('Attachment URL'),
                                content: SelectableText(url),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.of(d).pop(),
                                      child: const Text('Close')),
                                ],
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.open_in_new),
                      ),
                    ],
                  ),
                ),
              ],
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
                      Icon(Icons.image_not_supported,
                          size: 36, color: Colors.grey[600]),
                      const SizedBox(height: 8),
                      Text('No attachment',
                          style: GoogleFonts.manrope(color: Colors.grey[600])),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            
            // Only show the "Mark as Resolved" button if it's not already resolved/closed
            if (!_updatingStatus && !isResolvedOrClosed)
              CustomButton(
                text: 'Mark as Resolved',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Confirm'),
                      content: const Text('Mark this report as resolved?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.of(c).pop(false),
                            child: const Text('Cancel')),
                        TextButton(
                            onPressed: () => Navigator.of(c).pop(true),
                            child: const Text('Yes')),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await _updateReportStatus(ReportStatus.resolved);
                  }
                },
                isFilled: true,
                fillColor: const Color(0xFF5B53C2),
                textColor: Colors.white,
                height: 48,
              ),
            if (_updatingStatus) ...[
              const SizedBox(height: 12),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.broken_image,
                        color: Colors.white, size: 48),
                    const SizedBox(height: 8),
                    Text('Failed to load image',
                        style: GoogleFonts.manrope(color: Colors.white)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}