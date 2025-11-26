// lib/pages/admin_reports_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/admin_report.dart';
import '../providers/admin_report.dart';
import '../widgets/feedback_card.dart';
import 'reportdetails_admin.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  // --- State & Logic ---
  final List<Map<String, dynamic>> priorityTabs = [
    {"label": "Low", "value": ReportSeverity.low},
    {"label": "Medium", "value": ReportSeverity.medium},
    {"label": "High", "value": ReportSeverity.high},
  ];

  ReportSeverity activePriority = ReportSeverity.low;

  // Status tabs: 0 = Pending (open/in_review), 1 = Resolved (resolved/closed/dismissed)
  int activeStatusTab = 0;

  @override
  void initState() {
    super.initState();
    // Load reports on page initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().loadReports();
    });
  }

  // Gradient for active state
  static const LinearGradient _kGradient = LinearGradient(
    colors: [Color(0xFFB945AA), Color(0xFF5B53C2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Determine if a report status is "pending" for UI purposes
  bool _isPendingStatus(ReportStatus status) {
    return status == ReportStatus.open || status == ReportStatus.inReview;
  }

  /// Determine if a report status is "resolved" for UI purposes
  bool _isResolvedStatus(ReportStatus status) {
    return status == ReportStatus.resolved ||
        status == ReportStatus.closed ||
        status == ReportStatus.dismissed;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 420;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      body: SafeArea(
        child: Consumer<ReportProvider>(
          builder: (context, reportProvider, child) {
            // Filter logic: first by severity, then by status tab
            final filteredReports = reportProvider.reports
                .where((r) => r.severity == activePriority)
                .where((r) {
                  if (activeStatusTab == 0) {
                    return _isPendingStatus(r.status);
                  } else {
                    return _isResolvedStatus(r.status);
                  }
                })
                .toList();

            return Column(
              children: [
                // --- Header Section ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Title and Count
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reports',
                                  style: GoogleFonts.manrope(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Manage feedback',
                                  style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Count Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: _kGradient,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${filteredReports.length} Items',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          // (status toggle moved below priority tabs)
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Priority Tabs
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F0FA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: priorityTabs
                              .map(
                                (tab) => _buildPillTab(
                                  tab["label"] as String,
                                  tab["value"] as ReportSeverity,
                                  activePriority == tab["value"],
                                  isSmall,
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Status Toggle (Pending / Resolved) placed below priority pills,
                      // right-aligned to match header layout.
                      Row(
                        children: [
                          const Spacer(),
                          ToggleButtons(
                            isSelected: [activeStatusTab == 0, activeStatusTab == 1],
                            onPressed: (index) {
                              setState(() => activeStatusTab = index);
                            },
                            borderColor: const Color(0xFF7A3DB8),
                            selectedBorderColor: const Color(0xFF7A3DB8),
                            fillColor: const Color(0xFF7A3DB8),
                            selectedColor: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            constraints: const BoxConstraints(minHeight: 30, minWidth: 78),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
                                child: Text('Pending', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
                                child: Text('Resolved', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // --- Reports List ---
                Expanded(
                  child: reportProvider.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF7A3DB8),
                          ),
                        )
                      : reportProvider.error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Failed to load reports',
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  reportProvider.loadReports();
                                },
                                child: Text(
                                  'Retry',
                                  style: GoogleFonts.manrope(
                                    color: const Color(0xFF7A3DB8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : filteredReports.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No reports found',
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => reportProvider.loadReports(),
                          color: const Color(0xFF7A3DB8),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            itemCount: filteredReports.length,
                            itemBuilder: (context, index) {
                              final report = filteredReports[index];

                              return ReportCard(
                                name: report.reporterName ?? 'Unknown',
                                priority: report.severity.displayName,
                                role: report.reporterRole ?? 'Commuter',
                                date: _formatDate(report.createdAt),
                                description: report.description,
                                tags: report.tags,
                                showPriority: false,
                                onTap: () async {
                                  // Make this async to wait for the result
                                  final bool? result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ReportDetailsPage(
                                        name: report.reporterName ?? 'Unknown',
                                        role: report.reporterRole ?? 'Commuter',
                                        reportId: report.id,
                                        reporterId: report.reporterProfileId,
                                        priority: report.severity.displayName,
                                        date: _formatDate(report.createdAt),
                                        description: report.description,
                                        tags: report.tags,
                                        imagePath: report.attachmentUrl ?? '',
                                      ),
                                    ),
                                  );

                                  // Refresh if update happened
                                  if (result == true && context.mounted) {
                                    context
                                        .read<ReportProvider>()
                                        .loadReports();
                                  }
                                },
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Format DateTime to MM/DD/YY
  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.year.toString().substring(2)}';
  }

  // --- Tab Builder ---
  Widget _buildPillTab(
    String label,
    ReportSeverity value,
    bool isActive,
    bool isSmall,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => activePriority = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: EdgeInsets.symmetric(vertical: isSmall ? 10 : 12),
          decoration: BoxDecoration(
            gradient: isActive ? _kGradient : null,
            color: isActive ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: isActive ? Colors.white : Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
