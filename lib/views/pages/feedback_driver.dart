import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../widgets/feedback_card.dart';
import '../pages/feedbackdetails_driver.dart';
import '../services/driver_report.dart';
import '../models/report.dart';
import 'report_driver.dart';

class DriverFeedbackPage extends StatefulWidget {
  const DriverFeedbackPage({super.key});

  @override
  State<DriverFeedbackPage> createState() => _DriverFeedbackPageState();
}

class _DriverFeedbackPageState extends State<DriverFeedbackPage> {
  final DriverReportService _reportService = DriverReportService();
  List<Report> _reports = [];
  bool _isLoading = false;
  String? _errorMessage;
  String selectedFilter = "Date";

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final reports = await _reportService.getAssignedReports();
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
      _applySorting();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applySorting() {
    if (selectedFilter == "Date") {
      _sortByDate();
    } else if (selectedFilter == "Priority") {
      _sortByPriority();
    }
  }

  void _sortByDate() {
    setState(() {
      _reports.sort((a, b) =>
          (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
    });
  }

  void _sortByPriority() {
    const priorityOrder = {
      ReportSeverity.high: 3,
      ReportSeverity.medium: 2,
      ReportSeverity.low: 1,
    };

    setState(() {
      _reports.sort((a, b) {
        return priorityOrder[b.severity]!.compareTo(priorityOrder[a.severity]!);
      });
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('MM/dd/yy').format(date);
  }

  String _mapSeverityToPriority(ReportSeverity severity) {
    switch (severity) {
      case ReportSeverity.high:
        return "High";
      case ReportSeverity.medium:
        return "Medium";
      case ReportSeverity.low:
        return "Low";
    }
  }

  List<String> _generateTags(Report report) {
    final tags = <String>[];
    
    // Add category as tag
    tags.add(report.category.displayName);
    
    // Add status if not open
    if (report.status != ReportStatus.open) {
      tags.add(report.status.displayName);
    }
    
    return tags;
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = const [
      Color(0xFFB945AA),
      Color(0xFF8E4CB6),
      Color(0xFF5B53C2),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100, right: 10),
        child: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportPage()),
              );
            },
            icon: const Icon(Icons.add_rounded, size: 25, color: Colors.white),
          ),
        ),
      ),
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
                    "Feedback",
                    style: GoogleFonts.manrope(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: gradientColors,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: const Color(0xFF8A56F0),
                        value: selectedFilter,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                        ),
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        items: const [
                          DropdownMenuItem(value: "Date", child: Text("Date")),
                          DropdownMenuItem(
                            value: "Priority",
                            child: Text("Priority"),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          setState(() => selectedFilter = value);
                          _applySorting();
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // --- Reports List ---
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF8E4CB6),
                        ),
                      )
                    : _errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Error loading reports',
                                  style: GoogleFonts.manrope(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 32),
                                  child: Text(
                                    _errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.nunito(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadReports,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF8E4CB6),
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : _reports.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inbox_outlined,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No feedback reports yet',
                                      style: GoogleFonts.manrope(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadReports,
                                child: ListView.builder(
                                  itemCount: _reports.length,
                                  itemBuilder: (context, index) {
                                    final r = _reports[index];

                                    return ReportCard(
                                      name: r.reporterName ?? 'Unknown Reporter',
                                      priority: _mapSeverityToPriority(r.severity),
                                      date: _formatDate(r.createdAt),
                                      description: r.description,
                                      tags: _generateTags(r),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ReportDetailsPage(
                                              name: r.reporterName ?? 'Unknown Reporter',
                                              role: "Commuter",
                                              id: r.reporterProfileId ?? '',
                                              priority: _mapSeverityToPriority(r.severity),
                                              date: _formatDate(r.createdAt),
                                              description: r.description,
                                              tags: _generateTags(r),
                                              imagePath: r.attachmentUrl ?? "assets/images/sample bottle.png",
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}