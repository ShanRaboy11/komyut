import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnalyticsCard extends StatefulWidget {
  const AnalyticsCard({super.key});

  @override
  State<AnalyticsCard> createState() => _AnalyticsCardState();
}

class _AnalyticsCardState extends State<AnalyticsCard> {
  String rangeFilter = "Weekly";
  String metricFilter = "Top Earners";
  DateTime currentDate = DateTime.now();

  // Dummy data variations
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
    "Top Trips Completed": [
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

  @override
  Widget build(BuildContext context) {
    final data = dummyData[metricFilter]!;
    final maxValue = data.first["value"].toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB945AA), Color(0xFF8E4CB6), Color(0xFF5B53C2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Filter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Analytics",
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              DropdownButton<String>(
                value: rangeFilter,
                dropdownColor: const Color(0xFF8E4CB6),
                underline: const SizedBox(),
                iconEnabledColor: Colors.white,
                style: GoogleFonts.nunito(color: Colors.white),
                onChanged: (v) => setState(() => rangeFilter = v!),
                items: ["Daily", "Weekly", "Monthly", "Yearly"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Metric Filter + Date Nav
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DropdownButton<String>(
                value: metricFilter,
                dropdownColor: const Color(0xFF8E4CB6),
                underline: const SizedBox(),
                iconEnabledColor: Colors.white,
                style: GoogleFonts.nunito(color: Colors.white),
                onChanged: (v) => setState(() => metricFilter = v!),
                items: ["Top Earners", "Top Ratings", "Top Trips Completed"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: goPrevious,
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                  ),
                  Text(
                    getFormattedDate(),
                    style: GoogleFonts.nunito(color: Colors.white70),
                  ),
                  IconButton(
                    onPressed: goNext,
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Data Bars
          Column(
            children: data.map((item) {
              final barWidth = (item["value"].toDouble() / maxValue).clamp(
                0.1,
                1.0,
              );

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Text(
                      "${data.indexOf(item) + 1}. ${item["name"]}",
                      style: GoogleFonts.nunito(color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: FractionallySizedBox(
                          widthFactor: barWidth,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "PHP ${item["value"]}",
                      style: GoogleFonts.nunito(color: Colors.white70),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
