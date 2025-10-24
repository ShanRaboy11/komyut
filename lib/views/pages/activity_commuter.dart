import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/trip_card.dart';

class TripsPage extends StatefulWidget {
  const TripsPage({super.key});

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  String selectedRange = 'Weekly';
  int currentIndex = 0;

  final gradientColors = const [
    Color(0xFFB945AA),
    Color(0xFF8E4CB6),
    Color(0xFF5B53C2),
  ];
  // Simulated ranges
  List<String> weeklyRanges = [
    'Sep 29 - Oct 5',
    'Oct 6 - Oct 12',
    'Oct 13 - Oct 19',
    'Oct 20 - Oct 26',
  ];
  List<String> monthlyRanges = [
    'September 2025',
    'October 2025',
    'November 2025',
  ];
  List<String> yearlyRanges = ['2024', '2025', '2026'];
  List<String> allTimeRanges = ['2022 - 2023', '2023 - 2024', '2024 - 2025'];

  String getCurrentRange() {
    switch (selectedRange) {
      case 'Weekly':
        return weeklyRanges[currentIndex % weeklyRanges.length];
      case 'Monthly':
        return monthlyRanges[currentIndex % monthlyRanges.length];
      case 'Yearly':
        return yearlyRanges[currentIndex % yearlyRanges.length];
      case 'All Trips':
        return allTimeRanges[currentIndex % allTimeRanges.length];
      default:
        return '';
    }
  }

  List<String> getXLabels() {
    switch (selectedRange) {
      case 'Weekly':
        return ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
      case 'Monthly':
        return ['W1', 'W2', 'W3', 'W4'];
      case 'Yearly':
        return ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'];
      case 'All Trips':
        return ['2022', '2023', '2024', '2025'];
      default:
        return [];
    }
  }

  List<FlSpot> getData() {
    switch (selectedRange) {
      case 'Weekly':
        return [
          FlSpot(0, 3),
          FlSpot(1, 4),
          FlSpot(2, 2),
          FlSpot(3, 5),
          FlSpot(4, 4),
          FlSpot(5, 6),
          FlSpot(6, 3),
        ];
      case 'Monthly':
        return [FlSpot(0, 12), FlSpot(1, 8), FlSpot(2, 15), FlSpot(3, 10)];
      case 'Yearly':
        return List.generate(
          12,
          (i) => FlSpot(i.toDouble(), (5 + (i % 4) * 2).toDouble()),
        );
      case 'All Trips':
        return [FlSpot(0, 20), FlSpot(1, 35), FlSpot(2, 50), FlSpot(3, 70)];
      default:
        return [];
    }
  }

  final Map<String, Map<String, String>> analyticsData = {
    'Weekly': {'trips': '12', 'distance': '45 km', 'spent': '₱650'},
    'Monthly': {'trips': '54', 'distance': '230 km', 'spent': '₱2,400'},
    'Yearly': {'trips': '620', 'distance': '3,200 km', 'spent': '₱28,000'},
    'All Trips': {
      'trips': '2,430',
      'distance': '12,540 km',
      'spent': '₱95,000',
    },
  };

  void prevRange() {
    setState(() {
      currentIndex = (currentIndex - 1).clamp(0, 999);
    });
  }

  void nextRange() {
    setState(() {
      currentIndex = (currentIndex + 1).clamp(0, 999);
    });
  }

  @override
  Widget build(BuildContext context) {
    final labels = getXLabels();
    final data = getData();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Color(0xFFF7F4FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Dropdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Activity",
                    style: GoogleFonts.manrope(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
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
                        value: selectedRange,
                        iconEnabledColor: Colors.white,
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        items: ['Weekly', 'Monthly', 'Yearly', 'All Trips']
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedRange = value!;
                            currentIndex = 0; // reset when switching
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Analytics Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, // start at the top
                    end: Alignment.bottomCenter, // end at the bottom
                    colors: gradientColors,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + Range + Navigation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Analytic Summary",
                          style: GoogleFonts.nunito(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: prevRange,
                              icon: const Icon(
                                Icons.chevron_left,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              getCurrentRange(),
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            IconButton(
                              onPressed: nextRange,
                              icon: const Icon(
                                Icons.chevron_right,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Line Chart
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left side: analytics card
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(top: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Total Trips",
                                  style: GoogleFonts.manrope(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFFF0D7FF),
                                  ),
                                ),
                                Text(
                                  analyticsData[selectedRange]!['trips']
                                      .toString(),
                                  style: GoogleFonts.manrope(
                                    fontSize: 45,
                                    fontWeight: FontWeight.w600,
                                    color: const Color.fromARGB(
                                      255,
                                      255,
                                      255,
                                      255,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(
                          width: 20,
                        ), // space between card and chart
                        // Right side: chart
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: size.height * 0.15,
                            child: LineChart(
                              LineChartData(
                                gridData: const FlGridData(show: false),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 1,
                                      getTitlesWidget: (value, meta) {
                                        int index = value.toInt();
                                        if (index < 0 ||
                                            index >= labels.length) {
                                          return const SizedBox();
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Text(
                                            labels[index],
                                            style: GoogleFonts.nunito(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: data,
                                    isCurved: true,
                                    color: Colors.white,
                                    barWidth: 2,
                                    dotData: const FlDotData(show: false),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _analyticsCard(
                          "Distance",
                          analyticsData[selectedRange]!['distance']!,
                        ),
                        const SizedBox(width: 20),
                        _analyticsCard(
                          "Amount Spent",
                          analyticsData[selectedRange]!['spent']!,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Recent Trips Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Recent Trips",
                    style: GoogleFonts.manrope(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 30),
                  Text(
                    "View All",
                    style: GoogleFonts.nunito(
                      color: const Color.fromARGB(255, 42, 42, 42),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Status Legend
              Row(
                children: [
                  Text(
                    "Status",
                    style: GoogleFonts.nunito(
                      color: const Color.fromARGB(255, 0, 0, 0),
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(width: 20),
                  _buildStatusDot(Colors.yellow, "Ongoing"),
                  const SizedBox(width: 16),
                  _buildStatusDot(Colors.green, "Completed"),
                  const SizedBox(width: 16),
                  _buildStatusDot(Colors.red, "Cancelled"),
                ],
              ),
              const SizedBox(height: 16),

              // Recent Trips List
              TripsCard(
                date: "September 11, 2025",
                time: "04:26 PM",
                from: "SM Cebu",
                to: "Colon",
                tripCode: "01K",
                status: "ongoing",
              ),
              TripsCard(
                date: "September 10, 2025",
                time: "03:15 PM",
                from: "Ayala",
                to: "IT Park",
                tripCode: "02C",
                status: "completed",
              ),
              TripsCard(
                date: "September 09, 2025",
                time: "06:45 PM",
                from: "Colon",
                to: "Talamban",
                tripCode: "03B",
                status: "cancelled",
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.nunito(color: Colors.white70, fontSize: 14),
        ),
        Text(
          value,
          style: GoogleFonts.manrope(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.nunito(fontSize: 14)),
      ],
    );
  }

  Widget _analyticsCard(String title, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFD999FF).withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 18,
                color: Color(0xFFF0D7FF),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: const Color.fromARGB(255, 255, 255, 255),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
