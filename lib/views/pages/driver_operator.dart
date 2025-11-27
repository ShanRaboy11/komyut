import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../providers/operator_drivers.dart';
import 'driverlist_operator.dart';
import '../widgets/drivercard_operator.dart';
import 'driverdetails_operator.dart';

class OperatorDriversPage extends StatefulWidget {
  const OperatorDriversPage({super.key});

  @override
  State<OperatorDriversPage> createState() => _OperatorDriversPageState();
}

class _OperatorDriversPageState extends State<OperatorDriversPage> {
  String rangeFilter = "Weekly";
  String metricFilter = "Top Earners";
  DateTime currentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Load drivers when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OperatorProvider>().loadDrivers();
    });
  }

  // Dummy data variations - TODO: Replace with actual analytics from backend
  final Map<String, List<Map<String, dynamic>>> dummyData = {
    "Top Earners": [
      {"name": "Gio", "value": 1500},
      {"name": "James", "value": 1000},
      {"name": "Noel", "value": 900},
      {"name": "Brent", "value": 400},
      {"name": "Dean", "value": 100},
    ],
    "Top Ratings": [
      {"name": "Noel", "value": 4.9},
      {"name": "James", "value": 4.7},
      {"name": "Gio", "value": 4.6},
      {"name": "Dean", "value": 4.2},
      {"name": "Brent", "value": 3.9},
    ],
    "Top Trips": [
      {"name": "James", "value": 320},
      {"name": "Gio", "value": 250},
      {"name": "Brent", "value": 150},
      {"name": "Noel", "value": 120},
      {"name": "Dean", "value": 60},
    ],
  };

  // --------- DATE LABEL LOGIC ----------
  String getFormattedDate() {
    switch (rangeFilter) {
      case "Daily":
        return "${currentDate.month}/${currentDate.day}/${currentDate.year}";
      case "Weekly":
        final start = currentDate.subtract(
          Duration(days: currentDate.weekday - 1),
        );
        final end = start.add(const Duration(days: 6));
        return "${start.month}/${start.day} - ${end.month}/${end.day}";
      case "Monthly":
        return "${_monthName(currentDate.month)} ${currentDate.year}";
      case "Yearly":
        return "${currentDate.year}";
    }
    return "";
  }

  String _monthName(int m) {
    const names = [
      "",
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return names[m];
  }

  // --------- NAVIGATION ---------
  void goPrevious() {
    setState(() {
      switch (rangeFilter) {
        case "Daily":
          currentDate = currentDate.subtract(const Duration(days: 1));
          break;
        case "Weekly":
          currentDate = currentDate.subtract(const Duration(days: 7));
          break;
        case "Monthly":
          currentDate = DateTime(currentDate.year, currentDate.month - 1, 1);
          break;
        case "Yearly":
          currentDate = DateTime(currentDate.year - 1, 1, 1);
          break;
      }
    });
  }

  void goNext() {
    setState(() {
      switch (rangeFilter) {
        case "Daily":
          currentDate = currentDate.add(const Duration(days: 1));
          break;
        case "Weekly":
          currentDate = currentDate.add(const Duration(days: 7));
          break;
        case "Monthly":
          currentDate = DateTime(currentDate.year, currentDate.month + 1, 1);
          break;
        case "Yearly":
          currentDate = DateTime(currentDate.year + 1, 1, 1);
          break;
      }
    });
  }

  String _formatDate(DateTime date) {
    const months = [
      "",
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    return "${months[date.month]} ${date.day}, ${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    // Analytics data will be computed inside the Consumer where provider is available

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      body: SafeArea(
        child: Consumer<OperatorProvider>(
          builder: (context, provider, child) {
            // Use all fetched drivers as active drivers for display
            final activeDrivers = List.from(provider.drivers);

            // Prepare analytics data: when metric is "Top Earners" use driver list
            final List<Map<String, dynamic>> analyticsData =
                metricFilter == 'Top Earners'
                    ? (() {
                        final list = List.of(provider.drivers);
                        // sort by createdAt desc to pick a deterministic ordering
                        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                        return list.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final drv = entry.value;
                          // synthetic score so the chart has variation
                          final score = (list.length - idx) * 100;
                          return {'name': drv.fullName, 'value': score};
                        }).toList();
                      })()
                    : dummyData[metricFilter]!;

            final maxValue = analyticsData.isNotEmpty
                ? analyticsData
                    .map((e) => (e['value'] as num).toDouble())
                    .reduce((a, b) => math.max(a, b))
                : 1.0;

            // Show loading indicator on initial load
            if (provider.isLoading && provider.drivers.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8E4CB6)),
                ),
              );
            }

            // Show error state
            if (provider.error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading drivers',
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        provider.error!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => provider.refreshDrivers(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8E4CB6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => provider.refreshDrivers(),
              color: const Color(0xFF8E4CB6),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Row + Range Filter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Analytics",
                          style: GoogleFonts.manrope(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFB945AA),
                                Color(0xFF8E4CB6),
                                Color(0xFF5B53C2),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: DropdownButton<String>(
                            value: rangeFilter,
                            dropdownColor: const Color(0xFF8A56F0),
                            underline: const SizedBox(),
                            iconEnabledColor: Colors.white,
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            onChanged: (v) => setState(() => rangeFilter = v!),
                            items: ["Daily", "Weekly", "Monthly", "Yearly"]
                                .map(
                                  (e) => DropdownMenuItem(value: e, child: Text(e)),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // MAIN ANALYTICS CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(
                        top: 18,
                        bottom: 18,
                        left: 20,
                        right: 20,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFB945AA),
                            Color(0xFF8E4CB6),
                            Color(0xFF5B53C2),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Metric Filter + Date Navigation
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              DropdownButton<String>(
                                value: metricFilter,
                                dropdownColor: const Color(0xFF8E4CB6),
                                underline: const SizedBox(),
                                iconEnabledColor: Colors.white,
                                style: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                onChanged: (v) => setState(() => metricFilter = v!),
                                items: ["Top Earners", "Top Ratings", "Top Trips"]
                                    .map(
                                      (e) =>
                                          DropdownMenuItem(value: e, child: Text(e)),
                                    )
                                    .toList(),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: goPrevious,
                                    icon: const Icon(
                                      Icons.chevron_left,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    getFormattedDate(),
                                    style: GoogleFonts.nunito(
                                      color: Colors.white70,
                                      fontSize: 9,
                                    ),
                                  ),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: goNext,
                                    icon: const Icon(
                                      Icons.chevron_right,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                          Column(
                            children: analyticsData.asMap().entries.map((entry) {
                              final i = entry.key;
                              final item = entry.value;
                              final name = item["name"];
                              final value = item["value"];
                              final barFactor = (value.toDouble() / maxValue)
                                  .clamp(0.05, 1.0);

                              // Dynamic label formats
                              String displayValue() {
                                if (metricFilter == "Top Ratings") {
                                  return "$value ★";
                                }

                                if (metricFilter == "Top Trips") {
                                  return "$value trips";
                                }

                                return "PHP $value";
                              }

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Text(
                                      "${i + 1}.  ",
                                      style: GoogleFonts.nunito(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Expanded(
                                      child: Stack(
                                        alignment: Alignment.centerLeft,
                                        children: [
                                          Container(
                                            height: 25,
                                            decoration: BoxDecoration(
                                              color: Colors.white24,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                          ),
                                          FractionallySizedBox(
                                            widthFactor: barFactor,
                                            child: Container(
                                              height: 25,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(
                                                  alpha: 0.4,
                                                ),
                                                borderRadius: BorderRadius.circular(
                                                  20,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            child: Text(
                                              "$name • ${displayValue()}",
                                              style: GoogleFonts.nunito(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Active Drivers Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Active Drivers",
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 30),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const DriverListPage(showPendingOnly: false),
                              ),
                            );
                          },
                          child: Text(
                            "View All",
                            style: GoogleFonts.nunito(
                              color: const Color.fromARGB(255, 42, 42, 42),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    if (activeDrivers.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            "No Active Drivers",
                            style: GoogleFonts.nunito(
                              fontSize: 20,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: activeDrivers.length,
                        itemBuilder: (context, index) {
                          final driver = activeDrivers[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: DriverCard(
                              name: driver.fullName,
                              puvType: driver.puvType ?? 'Modern',
                              plate: driver.vehiclePlate ?? 'N/A',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DriverDetailsPage(
                                      name: driver.fullName,
                                      puvType: driver.puvType ?? 'Modern',
                                      plate: driver.vehiclePlate ?? 'N/A',
                                      registeredDate: _formatDate(driver.createdAt),
                                      status: 'active',
                                      inactiveDate: null,
                                      suspensionDate: null,
                                      returnDate: null,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}