import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/operator_card.dart'; // <-- Make sure OperatorCard is in the same folder or adjust import

class OperatorListPage extends StatefulWidget {
  const OperatorListPage({super.key});

  @override
  State<OperatorListPage> createState() => _OperatorListPageState();
}

class _OperatorListPageState extends State<OperatorListPage> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _operators = [
    {
      "name": "El Pardo Transportation",
      "drivers": "37",
      "start": "SM Cebu",
      "end": "Bulacao",
      "code": "10H",
    },
    {
      "name": "Guadalupe Transit Line",
      "drivers": "25",
      "start": "Guadalupe",
      "end": "IT Park",
      "code": "06G",
    },
    {
      "name": "NorthLink Shuttle",
      "drivers": "19",
      "start": "SM Consolacion",
      "end": "Colon",
      "code": "23C",
    },
    {
      "name": "Lapu-Lapu Express",
      "drivers": "42",
      "start": "Mactan",
      "end": "SM City Cebu",
      "code": "17B",
    },
  ];

  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final filteredOperators = _operators.where((operator) {
      final query = _searchQuery.toLowerCase();
      return operator["name"]!.toLowerCase().contains(query) ||
          operator["code"]!.toLowerCase().contains(query) ||
          operator["start"]!.toLowerCase().contains(query) ||
          operator["end"]!.toLowerCase().contains(query);
    }).toList();

    final isSmall = MediaQuery.of(context).size.width < 400;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FF),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Operator List',
          style: GoogleFonts.manrope(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 30, right: 30, bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const SizedBox(height: 10),
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() {
                      _searchQuery = value;
                    }),
                    style: GoogleFonts.nunito(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: "Search by operator, code, or route",
                      hintStyle: GoogleFonts.nunito(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Scrollable Operator List
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: filteredOperators.map((op) {
                        return OperatorCard(
                          operatorName: op["name"]!,
                          activeDrivers: op["drivers"]!,
                          routeStart: op["start"]!,
                          routeEnd: op["end"]!,
                          routeCode: op["code"]!,
                          onApply: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text("Application Submitted"),
                                content: Text(
                                  "You have applied for ${op['name']}.",
                                  style: GoogleFonts.nunito(),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Close"),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
