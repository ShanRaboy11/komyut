import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminVerifiedPage extends StatefulWidget {
  const AdminVerifiedPage({super.key});

  @override
  State<AdminVerifiedPage> createState() => _AdminVerifiedPageState();
}

class _AdminVerifiedPageState extends State<AdminVerifiedPage> {
  // --- Constants from Reference ---
  static const LinearGradient _kGradient = LinearGradient(
    colors: [Color(0xFF5B53C2), Color(0xFFB945AA)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  
  // --- State Variables ---
  String _selectedFilter = 'All';
  
  // Mock Data
  final List<VerificationItem> _allItems = [
    VerificationItem(name: 'Driver name', role: 'Driver', day: 'Jan 10, 2025', status: Status.pending),
    VerificationItem(name: 'Commuter name', role: 'Commuter', day: 'Jan 11, 2025', status: Status.approved),
    VerificationItem(name: 'Driver name', role: 'Driver', day: 'Jan 12, 2025', status: Status.rejected),
    VerificationItem(name: 'Driver name', role: 'Driver', day: 'Jan 13, 2025', status: Status.pending),
    VerificationItem(name: 'Commuter name', role: 'Commuter', day: 'Jan 14, 2025', status: Status.approved),
    VerificationItem(name: 'Driver name', role: 'Driver', day: 'Jan 15, 2025', status: Status.rejected),
  ];

  @override
  Widget build(BuildContext context) {
    // Filter Logic
    final displayItems = _selectedFilter == 'All'
        ? _allItems
        : _allItems.where((item) {
            if (_selectedFilter == 'Drivers') return item.role == 'Driver';
            final statusString = item.status.toString().split('.').last;
            return statusString.toLowerCase() == _selectedFilter.toLowerCase();
          }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF), // Light purple background
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
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F4FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.verified_user_outlined, 
                      color: Color(0xFF5B53C2)
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verification',
                          style: GoogleFonts.manrope(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF222222),
                          ),
                        ),
                        Text(
                          'Manage requests',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: _kGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5B53C2).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${displayItems.length} Items',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // --- Search Bar ---
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search users...',
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF5B53C2)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF5B53C2), width: 1.5),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- Filter Chips ---
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All'),
                        const SizedBox(width: 10),
                        _buildFilterChip('Approved'),
                        const SizedBox(width: 10),
                        _buildFilterChip('Pending'),
                        const SizedBox(width: 10),
                        _buildFilterChip('Rejected'),
                        const SizedBox(width: 10),
                        _buildFilterChip('Drivers'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- Section Title ---
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: _kGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.history, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Recent Verifications',
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF222222),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // --- List Items ---
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return VerificationCard(item: displayItems[index]);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? _kGradient : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? const Color(0xFF5B53C2).withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: isSelected ? null : Border.all(color: Colors.grey.shade200),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// --- Data Model ---
enum Status { approved, pending, rejected }

class VerificationItem {
  final String name;
  final String role;
  final String day;
  final Status status;

  VerificationItem({
    required this.name,
    required this.role,
    required this.day,
    required this.status,
  });
}

// --- Verification Card Widget ---
class VerificationCard extends StatelessWidget {
  final VerificationItem item;

  const VerificationCard({super.key, required this.item});

  Color getStatusColor() {
    switch (item.status) {
      case Status.approved: return const Color(0xFF33AF5B);
      case Status.pending: return const Color(0xFFFFBF00);
      case Status.rejected: return const Color(0xFFE64646);
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.purple.shade50),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F4FF),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.purple.shade100),
            ),
            child: Center(
              child: Text(
                item.name[0], 
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF5B53C2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF222222),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F4FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.role,
                        style: GoogleFonts.nunito(
                          color: const Color(0xFF5B53C2), 
                          fontSize: 10,
                          fontWeight: FontWeight.w700
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      item.day,
                      style: GoogleFonts.nunito(color: Colors.grey.shade600, fontSize: 11),
                    ),
                  ],
                )
              ],
            ),
          ),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: getStatusColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: getStatusColor().withValues(alpha: 0.2)),
            ),
            child: Text(
              getStatusText(),
              style: GoogleFonts.manrope(
                color: getStatusColor(),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}