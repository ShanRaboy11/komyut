import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../widgets/commutercard_report.dart';

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
  });

  @override
  State<ReportDetailsPage> createState() => _ReportDetailsPageState();

  }

class _ReportDetailsPageState extends State<ReportDetailsPage> {
  String? _attachmentUrl;
  String? _attachmentContentType;
  bool _loadingAttachment = false;

  bool _isImage() {
    final ct = _attachmentContentType ?? '';
    if (ct.startsWith('image/')) return true;
    final url = _attachmentUrl?.toLowerCase() ?? '';
    return url.endsWith('.jpg') || url.endsWith('.jpeg') || url.endsWith('.png') || url.endsWith('.gif') || url.endsWith('.webp');
  }

  @override
  void initState() {
    super.initState();
    // If we have an attachmentId, fetch its record (to get path/bucket/url).
    // We always fetch when attachmentId is present so we can generate a signed URL
    // when the storage bucket is private. If only initialAttachmentUrl is provided
    // (no id), use it directly.
    // Prefer any already-fetched URL provided by the report query to avoid
    // issuing a separate SELECT on the `attachments` table (which may be
    // blocked by RLS). Only fetch the attachment row when we don't already
    // have a usable URL.
    if (widget.initialAttachmentUrl != null && widget.initialAttachmentUrl!.isNotEmpty) {
      _attachmentUrl = widget.initialAttachmentUrl;
      _attachmentContentType = null; // content type unknown from initial URL
      // Still attempt to fetch metadata only if there's an attachmentId and
      // we need to generate a signed URL later (i.e. _attachmentUrl empty).
      if ((_attachmentUrl == null || _attachmentUrl!.isEmpty) && widget.attachmentId != null && widget.attachmentId!.isNotEmpty) {
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

        // If there's a stored URL, use it. Otherwise, try to generate a signed URL
        if (url != null && url.isNotEmpty) {
          debugPrint('Attachment fetched (url): $url');
          setState(() {
            _attachmentUrl = url;
            _attachmentContentType = contentType;
          });
        } else if (path != null && path.isNotEmpty) {
          try {
            debugPrint('No public url found; creating signed URL for path: $path');
            final signed = await client.storage.from(bucket).createSignedUrl(path, 60);
            if (signed.isNotEmpty) {
              debugPrint('Signed URL created: $signed');
              setState(() {
                _attachmentUrl = signed;
                _attachmentContentType = contentType;
              });
            } else {
              debugPrint('createSignedUrl returned null/empty');
            }
          } catch (e) {
            debugPrint('Failed to create signed URL: $e');
          }
        } else {
          debugPrint('Attachment row found but no url/path available');
        }
      }
    } catch (e) {
      // ignore errors; leave _attachmentUrl null
    } finally {
      if (mounted) setState(() => _loadingAttachment = false);
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
    // Show a centered dialog sized to the image (not covering entire screen).
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
                                const Icon(Icons.broken_image, color: Colors.grey, size: 48),
                                const SizedBox(height: 8),
                                Text('Failed to load image', style: GoogleFonts.manrope(color: Colors.grey[700])),
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

            // Profile Card
            ProfileCard(name: widget.name, role: widget.role ?? "Unknown", id: widget.id),

            const SizedBox(height: 20),

            // Description Label
            Text(
              "Description",
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // Description Text
            Text(
              widget.description,
              style: GoogleFonts.manrope(
                fontSize: 14,
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

            if (widget.driverName != null || widget.vehiclePlate != null || widget.routeCode != null || widget.status != null) ...[
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
                Text('Driver: ${widget.driverName}', style: GoogleFonts.manrope(fontSize: 14)),
              if (widget.vehiclePlate != null)
                Text('Vehicle Plate: ${widget.vehiclePlate}', style: GoogleFonts.manrope(fontSize: 14)),
              if (widget.routeCode != null)
                Text('Route: ${widget.routeCode}', style: GoogleFonts.manrope(fontSize: 14)),
              if (widget.status != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Status: ${widget.status}', style: GoogleFonts.manrope(fontSize: 14)),
                ),
              const SizedBox(height: 16),
            ],

            // Attachment Label
            Text(
              "Attachment",
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),

            // Attachment: fetched from attachments table using attachmentId
            if (_loadingAttachment) ...[
              // Detailed shimmer skeleton for the attachment area
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image placeholder with border shape matching final UI
                    Container(
                      width: (MediaQuery.of(context).size.width * 0.86).clamp(0, 420),
                      height: 220,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // small metadata lines
                    Container(
                      width: 140,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 220,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: List.generate(3, (i) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Container(
                          width: 70,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      )),
                    )
                  ],
                ),
              ),
            ] else if (_attachmentUrl != null && _attachmentUrl!.isNotEmpty) ...[
              if (_isImage()) ...[
                // Thumbnail with tap-to-open viewer. Keep it slightly narrower
                // and add a colored border to match the app palette.
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
                        border: Border.all(color: const Color(0xFF7A3DB8), width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          _attachmentUrl!,
                          width: (MediaQuery.of(context).size.width * 0.86).clamp(0, 420),
                          height: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: double.infinity,
                            height: 180,
                            color: Colors.grey.shade200,
                            child: Center(
                              child: Text('Failed to load attachment', style: GoogleFonts.manrope(color: Colors.grey[600])),
                            ),
                          ),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              width: double.infinity,
                              height: 180,
                              color: Colors.grey.shade100,
                              child: const Center(child: CircularProgressIndicator()),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Non-image attachment (show download link or placeholder)
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
                          style: GoogleFonts.manrope(fontSize: 14, color: Colors.black87),
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final url = _attachmentUrl;
                          if (url == null || url.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No attachment URL')),
                            );
                            return;
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Attachment URL: $url')),
                          );
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
                      Icon(Icons.image_not_supported, size: 36, color: Colors.grey[600]),
                      const SizedBox(height: 8),
                      Text('No attachment', style: GoogleFonts.manrope(color: Colors.grey[600])),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Full-screen image viewer for attachments. Uses `InteractiveViewer` to
/// allow pinch-zoom and pan. Navigates back on AppBar close or back button.
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
                    const Icon(Icons.broken_image, color: Colors.white, size: 48),
                    const SizedBox(height: 8),
                    Text('Failed to load image', style: GoogleFonts.manrope(color: Colors.white)),
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
