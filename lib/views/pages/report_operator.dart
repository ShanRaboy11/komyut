import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import '../widgets/feedback_card.dart';
import '../pages/reportdetails_operator.dart';
import '../providers/operator_report.dart';
import '../models/report.dart';

class OperatorReportsPage extends StatefulWidget {
  const OperatorReportsPage({super.key});

  @override
  State<OperatorReportsPage> createState() => _OperatorReportsPageState();
}

class _OperatorReportsPageState extends State<OperatorReportsPage> {
  final List<Map<String, dynamic>> priorityTabs = [
    {"label": "Low", "value": 1},
    {"label": "Medium", "value": 2},
    {"label": "High", "value": 3},
  ];

  int activePriority = 1;

  ReportSeverity _getSeverityFromValue(int value) {
    switch (value) {
      case 1:
        return ReportSeverity.low;
      case 2:
        return ReportSeverity.medium;
      case 3:
        return ReportSeverity.high;
      default:
        return ReportSeverity.low;
    }
  }

  @override
  void initState() {
    super.initState();
    // Fetch reports when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<OperatorReportProvider>();
      provider.fetchReports(severity: _getSeverityFromValue(activePriority));
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 420;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header Row: Title + Sort Dropdown ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Reports",
                    style: GoogleFonts.manrope(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Color(0xFF9C6BFF).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: priorityTabs
                      .map(
                        (tab) => _buildPillTab(
                          tab["label"],
                          tab["value"],
                          activePriority == tab["value"],
                          isSmall,
                        ),
                      )
                      .toList(),
                ),
              ),

              const SizedBox(height: 16),

              // --- Reports List ---
              Expanded(
                child: Consumer<OperatorReportProvider>(
                  builder: (context, provider, child) {
                    // Show shimmer skeleton while loading and no data yet
                    if (provider.isLoading && provider.reports.isEmpty) {
                      return _buildShimmerSkeleton(isSmall);
                    }

                    // Get filtered reports based on active priority
                    final filteredReports = provider.reports
                        .where((operatorReport) {
                          final severity = operatorReport.report.severity;
                          return (severity == ReportSeverity.low && activePriority == 1) ||
                                 (severity == ReportSeverity.medium && activePriority == 2) ||
                                 (severity == ReportSeverity.high && activePriority == 3);
                        })
                        .toList();

                    // Show empty state if no reports
                    if (filteredReports.isEmpty) {
                      return Center(
                        child: Text(
                          'No reports found',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredReports.length,
                      itemBuilder: (context, index) {
                        final operatorReport = filteredReports[index];
                        final report = operatorReport.report;
                        final reporter = operatorReport.reporter;
                        final driver = operatorReport.assignedDriver;

                        // Format date
                        String formattedDate = 'Unknown';
                        if (report.createdAt != null) {
                          final date = report.createdAt!;
                          formattedDate = '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year.toString().substring(2)}';
                        }

                        // Build tags
                        List<String> tags = [report.category.displayName];
                        if (driver?.driverDetails?.vehiclePlate != null) {
                          tags.add('Plate: ${driver!.driverDetails!.vehiclePlate}');
                        }

                        return ReportCard(
                          name: reporter?.fullName ?? 'Unknown Reporter',
                          priority: report.severity.displayName,
                          role: reporter?.role.toUpperCase() ?? 'COMMUTER',
                          date: formattedDate,
                          description: report.description,
                          tags: tags,
                          showPriority: false,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReportDetailsPage(
                                  name: reporter?.fullName ?? 'Unknown Reporter',
                                  role: reporter?.role.toUpperCase() ?? 'COMMUTER',
                                  id: report.id ?? '123456789',
                                  priority: report.severity.displayName,
                                  date: formattedDate,
                                  description: report.description,
                                  tags: tags,
                                  imagePath: operatorReport.attachment?.url ?? "assets/images/sample bottle.png",
                                  driverName: driver?.fullName,
                                  vehiclePlate: driver?.driverDetails?.vehiclePlate,
                                  routeCode: driver?.driverDetails?.routeCode,
                                  status: report.status.displayName,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillTab(String label, int value, bool isActive, bool isSmall) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => activePriority = value);
          // Fetch reports for the selected severity
          context.read<OperatorReportProvider>().fetchReports(
            severity: _getSeverityFromValue(value),
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: isSmall ? 10 : 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: isActive ? Color(0xFF8E4CB6) : Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerSkeleton(bool isSmall) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pill tabs skeleton
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: List.generate(3, (i) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    height: isSmall ? 36 : 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 16),

          // List skeleton
          Expanded(
            child: ListView.separated(
              itemCount: 6,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // avatar placeholder
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 14,
                              width: double.infinity,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 12,
                              width: MediaQuery.of(context).size.width * 0.5,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  height: 10,
                                  width: 60,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  height: 10,
                                  width: 40,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}