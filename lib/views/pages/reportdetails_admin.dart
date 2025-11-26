import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import '../models/admin_report.dart';
import '../providers/admin_report.dart';
import '../widgets/role_navbar_wrapper.dart';
import 'home_admin.dart';
import 'admin_activity.dart';
import 'admin_report.dart';
import 'admin_verification.dart';
import 'admin_routes.dart';

class ReportDetailsPage extends StatefulWidget {
  final String name;
  final String? role;
  final String reportId; // This is the Report ID used for the backend update
  final String? reporterId; // The profile id of the reporter (for display)
  final String? priority;
  final String date;
  final String description;
  final List<String> tags;
  final String imagePath;
  final String? status; // Added status to check if we should show the button

  const ReportDetailsPage({
    super.key,
    required this.name,
    this.role,
    required this.reportId,
    this.reporterId,
    this.priority,
    required this.date,
    required this.description,
    required this.tags,
    required this.imagePath,
    this.status,
  });

  @override
  State<ReportDetailsPage> createState() => _ReportDetailsPageState();
}

class _ReportDetailsPageState extends State<ReportDetailsPage> {
  bool _isUpdating = false;

  /// Backend logic to update the report status
  Future<void> _markAsResolved() async {
    setState(() => _isUpdating = true);

    try {
      // Use the typed provider if available to update status
      bool success = false;
      try {
        final provider = context.read<ReportProvider>();
        success = await provider.updateReportStatus(widget.reportId, ReportStatus.resolved);
      } catch (_) {
        success = false;
      }

      if (!success) {
        // Fallback: directly update via Supabase
        final client = Supabase.instance.client;
        await client
            .from('reports')
            .update({
              'status': 'resolved',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', widget.reportId);
        success = true;
      }

      if (mounted) {
        // 2. Show Success Dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Text('Success', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
            content: Text('The report has been marked as resolved.', style: GoogleFonts.manrope()),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogCtx); // Close dialog
                },
                child: Text('OK', style: GoogleFonts.manrope(color: const Color(0xFF8E4CB6))),
              ),
            ],
          ),
        );

        if (!mounted) return;

        // 3. Redirect to Admin nav-wrapped reports page so navbar persists
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (ctx) => AdminNavBarWrapper(
              homePage: AdminDashboardNav(),
              verifiedPage: AdminVerifiedPage(),
              activityPage: const AdminActivityPage(),
              reportsPage: AdminReportsPage(),
              routePage: AdminRoutesPage(),
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating report: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Parse Date
    DateTime originalDate;
    try {
      originalDate = DateFormat('MM/dd/yy').parse(widget.date);
    } catch (e) {
      originalDate = DateTime.now();
    }
    final formattedDate = DateFormat('EEE d MMM yyyy, hh:mma').format(originalDate);

    // Check if report is already resolved/closed to hide the button
    final bool isFinished = widget.status != null && 
        (widget.status!.toLowerCase() == 'resolved' || widget.status!.toLowerCase() == 'closed');

    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFF), 
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header (Back Button and "Reports")
              Center(
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.chevron_left, size: 28, color: Color(0xFF222222)),
                      ),
                    ),
                    Center(
                      child: Text(
                        'Reports',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          color: const Color(0xFF222222),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 2. Report Details Title
              Text(
                'Report Details',
                style: GoogleFonts.manrope(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              // 3. Date and Priority Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formattedDate,
                    style: GoogleFonts.manrope(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.priority != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD8D8), // Light Pink bg
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.priority!,
                        style: GoogleFonts.manrope(
                          color: const Color(0xFFCD0000), // Red text
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // 4. Profile Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFF8E4CB6), width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3F000000),
                      blurRadius: 4,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEADDFF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_outline, color: Color(0xFF4F378B), size: 30),
                    ),
                    const SizedBox(width: 15),
                    // Text Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.name,
                            style: GoogleFonts.manrope(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${widget.role ?? "Commuter"} • ${widget.reporterId ?? ""}',
                            style: GoogleFonts.manrope(
                              color: const Color(0xFF6D6D6D),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // 5. Description
              Text(
                'Description',
                style: GoogleFonts.manrope(
                  color: const Color(0xFF6D6D6D),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                widget.description,
                style: GoogleFonts.manrope(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 20),

              // 6. Tags
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: widget.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9C5FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.manrope(
                        color: const Color(0xFF8E4CB6),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 25),

              // 7. Attachment
              Text(
                'Attachment',
                style: GoogleFonts.manrope(
                  color: const Color(0xFF6D6D6D),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              
              Container(
                width: 162,
                height: 162,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF8E4CB6), width: 1),
                  boxShadow: const [
                     BoxShadow(
                      color: Color(0x3F000000),
                      blurRadius: 4,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Image.network(
                    widget.imagePath.startsWith('http') ? widget.imagePath : "https://placehold.co/162x162",
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        widget.imagePath, 
                        fit: BoxFit.cover,
                        errorBuilder: (c,e,s) => Container(
                          color: Colors.grey[200],
                          child: const Center(child: Icon(Icons.image, color: Colors.grey)),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // 8. Buttons
              if (_isUpdating)
                const Center(child: CircularProgressIndicator(color: Color(0xFF8E4CB6)))
              else ...[
                // --- MARK AS RESOLVED BUTTON (Only shown if pending/open) ---
                if (!isFinished)
                  Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      // Used a slightly different gradient/color to distinguish from "Back" or keep same style
                      color: const Color(0xFF5B53C2), 
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x3F000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          // Confirmation Dialog
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
                          
                          if (confirm == true) {
                            _markAsResolved();
                          }
                        },
                        borderRadius: BorderRadius.circular(50),
                        child: Center(
                          child: Text(
                            'Mark as Resolved',
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // --- BACK TO HOME BUTTON ---
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFB945AA),
                        Color(0xFF8E4CB6),
                        Color(0xFF5B53C2),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x3F000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context, 
                          '/home_admin', 
                          (route) => false
                        );
                      },
                      borderRadius: BorderRadius.circular(50),
                      child: Center(
                        child: Text(
                          'Back to Home',
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}