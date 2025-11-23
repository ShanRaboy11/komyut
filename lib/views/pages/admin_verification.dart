import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:developer' as devtools; 
import 'admin_pending.dart'; 
import 'admin_approved.dart'; 
import 'admin_rejected.dart'; // Added import for the rejected page

class AdminVerifiedPage extends StatefulWidget {
  const AdminVerifiedPage({super.key});

  @override
  State<AdminVerifiedPage> createState() => _AdminVerifiedPageState();
}

class _AdminVerifiedPageState extends State<AdminVerifiedPage> {
  // --- Constants ---
  static const LinearGradient _kGradient = LinearGradient(
    colors: [Color(0xFF5B53C2), Color(0xFFB945AA)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // --- State Variables ---
  String _statusFilter = ''; // '' = All statuses
  String _roleFilter = 'All'; // 'All', 'Driver', or 'Commuter'
  String _searchQuery = ''; 

  final List<VerificationItem> _allItems = [
    VerificationItem(name: 'Driver name', role: 'Driver', timeAgo: '5m ago', status: Status.pending),
    VerificationItem(name: 'Commuter name', role: 'Commuter', timeAgo: '10m ago', status: Status.approved),
    VerificationItem(name: 'Driver name', role: 'Driver', timeAgo: '5m ago', status: Status.rejected),
    VerificationItem(name: 'Driver name', role: 'Driver', timeAgo: '5m ago', status: Status.pending),
    VerificationItem(name: 'Commuter name', role: 'Commuter', timeAgo: '10m ago', status: Status.approved),
    VerificationItem(name: 'Driver name', role: 'Driver', timeAgo: '5m ago', status: Status.rejected),
    VerificationItem(name: 'Driver name', role: 'Driver', timeAgo: '5m ago', status: Status.pending),
    VerificationItem(name: 'Commuter name', role: 'Commuter', timeAgo: '10m ago', status: Status.approved),
  ];

  @override
  Widget build(BuildContext context) {
    // --- Filter Logic ---
    final displayItems = _allItems.where((item) {
      // 1. Filter by Role
      if (_roleFilter != 'All' && item.role != _roleFilter) {
        return false;
      }

      // 2. Filter by Status
      if (_statusFilter.isNotEmpty) {
        final statusString = item.status.toString().split('.').last;
        final statusCapitalized = statusString[0].toUpperCase() + statusString.substring(1);
        if (statusCapitalized != _statusFilter) {
          return false;
        }
      }

      // 3. Filter by Search Query
      if (_searchQuery.isNotEmpty) {
        if (!item.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }
      
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      body: SafeArea(
        child: Column(
          children: [
            // --- Header ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Shield Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F4FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.verified_user_outlined,
                      color: Color(0xFF5B53C2),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title & Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verification',
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF222222),
                          ),
                        ),
                        Text(
                          'Manage requests',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Items Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: _kGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${displayItems.length} Items',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- Search Bar ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    hintStyle: GoogleFonts.nunito(color: Colors.grey.shade500),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF5B53C2)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- Controls Row ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // 1. Status Chips
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildStatusChip('Approved'),
                          const SizedBox(width: 10),
                          _buildStatusChip('Pending'),
                          const SizedBox(width: 10),
                          _buildStatusChip('Rejected'),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),

                  // 2. Role Filter Button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                         BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: PopupMenuButton<String>(
                      tooltip: "Filter by Role",
                      onSelected: (value) {
                        setState(() {
                          _roleFilter = value;
                        });
                        devtools.log('Role filter changed to: $value', name: 'AdminVerify');
                      },
                      offset: const Offset(0, 45),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'Driver', child: Text('Drivers Only')),
                        const PopupMenuItem(value: 'Commuter', child: Text('Commuters Only')),
                      ],
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _roleFilter == 'All' ? Colors.white : const Color(0xFF5B53C2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          size: 20,
                          color: _roleFilter == 'All' ? Colors.grey.shade700 : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_roleFilter != 'All')
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "Showing: $_roleFilter",
                    style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // --- List Items ---
            Expanded(
              child: displayItems.isEmpty 
              ? Center(child: Text("No items found", style: GoogleFonts.manrope(color: Colors.grey)))
              : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: displayItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = displayItems[index];
                  return VerificationCard(
                    item: item,
                    onTap: () {
                      if (item.status == Status.pending) {
                        // Navigate to Pending Page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminPending(),
                          ),
                        );
                      } else if (item.status == Status.approved) {
                        // Navigate to Approved Page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminApprovePage(),
                          ),
                        );
                      } else if (item.status == Status.rejected) {
                        // Navigate to Rejected Page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminRejectPage(),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label) {
    final isSelected = _statusFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _statusFilter = ''; 
          } else {
            _statusFilter = label; 
          }
        });
      },
      child: Container(
        constraints: const BoxConstraints(minWidth: 80),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? _kGradient : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade400,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.manrope(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// --- Data Models ---
enum Status { approved, pending, rejected }

class VerificationItem {
  final String name;
  final String role;
  final String timeAgo;
  final Status status;

  VerificationItem({
    required this.name,
    required this.role,
    required this.timeAgo,
    required this.status,
  });
}

// --- Verification Card Widget ---
class VerificationCard extends StatelessWidget {
  final VerificationItem item;
  final VoidCallback onTap;

  const VerificationCard({
    super.key, 
    required this.item, 
    required this.onTap
  });

  Color getStatusColor() {
    switch (item.status) {
      case Status.approved: return const Color(0xFF2ECC71);
      case Status.pending: return const Color(0xFFFFC107);
      case Status.rejected: return const Color(0xFFE74C3C);
    }
  }

  String getStatusText() {
    switch (item.status) {
      case Status.approved: return 'Approved';
      case Status.pending: return 'Pending';
      case Status.rejected: return 'Rejected';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 0.5), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 45, height: 45,
                decoration: const BoxDecoration(
                  color: Color(0xFFE0E0E0),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: GoogleFonts.manrope(
                        color: Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          item.role,
                          style: GoogleFonts.manrope(
                            color: Colors.black54, 
                            fontSize: 12,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Container(
                            width: 4, height: 4,
                            decoration: const BoxDecoration(
                              color: Colors.black87,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Text(
                          item.timeAgo,
                          style: GoogleFonts.manrope(
                            color: Colors.black87, 
                            fontSize: 12
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: getStatusColor(),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  getStatusText(),
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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