import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/admin_verification.dart';
import 'admin_pending.dart';

class AdminVerifiedPage extends StatefulWidget {
  final String defaultStatus;

  const AdminVerifiedPage({
    super.key,
    bool? onlyVerified,
    String? defaultStatus,
  }) : defaultStatus = defaultStatus ?? (onlyVerified == null ? 'approved' : (onlyVerified ? 'approved' : 'pending'));

  @override
  State<AdminVerifiedPage> createState() => _AdminVerifiedPageState();
}

class _AdminVerifiedPageState extends State<AdminVerifiedPage> with SingleTickerProviderStateMixin {
  static const LinearGradient _kGradient = LinearGradient(
    colors: [Color(0xFF5B53C2), Color(0xFFB945AA)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  String _statusFilter = '';
  String _roleFilter = 'All';
  String _searchQuery = '';
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    // Set default filter
    _statusFilter = widget.defaultStatus;
    
    // Load verifications when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminVerificationProvider>().loadVerifications();
    });
    _shimmerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Widget _buildShimmer({required Widget child}) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, shimmerChild) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.grey[300]!, Colors.grey[100]!, Colors.grey[300]!],
              stops: [
                _shimmerController.value - 0.3,
                _shimmerController.value,
                _shimmerController.value + 0.3,
              ],
            ).createShader(bounds);
          },
          child: shimmerChild,
        );
      },
      child: child,
    );
  }

  Widget _buildListSkeleton() {
    return _buildShimmer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: List.generate(6, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Container(width: 48, height: 48, decoration: const BoxDecoration(color: Color(0xFFF2EAFF), shape: BoxShape.circle)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 12, width: double.infinity, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(height: 10, width: 150, color: Colors.white),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(height: 20, width: 60, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      body: SafeArea(
        child: Consumer<AdminVerificationProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return _buildListSkeleton();
            }
            // Apply filters
            var displayItems = provider.applyFilters(
              status: _statusFilter,
              role: _roleFilter,
              searchQuery: _searchQuery,
            );

            // Exclude admin users
            displayItems = displayItems
                .where((v) => v.role.toLowerCase() != 'admin')
                .toList();

            return Column(
              children: [
                // --- Header ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.02),
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
                          color: Color(0xFF5B53C2),
                          size: 22,
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
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
                          color: Color.fromRGBO(0, 0, 0, 0.03),
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
                        hintStyle:
                            GoogleFonts.nunito(color: Colors.grey.shade500),
                        prefixIcon: const Icon(Icons.search,
                            color: Color(0xFF5B53C2)),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 15),
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
                              const SizedBox(width: 10),
                              _buildStatusChip('Lacking'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.05),
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
                          },
                          offset: const Offset(0, 45),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                                value: 'All', child: Text('All Users')),
                            const PopupMenuItem(
                                value: 'Driver', child: Text('Drivers')),
                            const PopupMenuItem(
                                value: 'Commuter',
                                child: Text('Commuters')),
                            const PopupMenuItem(
                                value: 'Operator',
                                child: Text('Operators')),
                          ],
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _roleFilter == 'All'
                                  ? Colors.white
                                  : const Color(0xFF5B53C2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.tune_rounded,
                              size: 20,
                              color: _roleFilter == 'All'
                                  ? Colors.grey.shade700
                                  : Colors.white,
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
                        style: GoogleFonts.nunito(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                // --- Loading / Error / List ---
                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : provider.errorMessage != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline,
                                      size: 48, color: Colors.red),
                                  const SizedBox(height: 16),
                                  Text(
                                    provider.errorMessage!,
                                    style: GoogleFonts.manrope(
                                        color: Colors.red),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () =>
                                        provider.loadVerifications(),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : displayItems.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.inbox_outlined, 
                                          size: 64, 
                                          color: Colors.grey.shade400),
                                      const SizedBox(height: 16),
                                      Text(
                                        "No users found",
                                        style: GoogleFonts.manrope(
                                            fontSize: 16,
                                            color: Colors.grey.shade600),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _statusFilter.isNotEmpty 
                                            ? "Try selecting a different status filter"
                                            : "No verification records available",
                                        style: GoogleFonts.nunito(
                                            fontSize: 12,
                                            color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: () =>
                                      provider.loadVerifications(),
                                  child: ListView.separated(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    itemCount: displayItems.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      return VerificationCard(
                                        item: displayItems[index],
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  AdminPending(
                                                verificationId:
                                                    displayItems[index].id,
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label) {
    final isSelected = _statusFilter.toLowerCase() == label.toLowerCase();
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

// --- Verification Card Widget ---
class VerificationCard extends StatelessWidget {
  final VerificationListItem item;
  final VoidCallback onTap;

  const VerificationCard({
    super.key,
    required this.item,
    required this.onTap,
  });


  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Color.fromRGBO(156, 39, 176, 0.5), width: 1),
          ),
          child: Row(
            children: [
              // Initials avatar (consistent with trip details and pending UI)
              Builder(builder: (_) {
                String initials = 'U';
                try {
                  final parts = item.userName
                      .split(RegExp(r'\s+'))
                      .where((s) => s.isNotEmpty)
                      .toList();
                  if (parts.isEmpty) {
                    initials = 'U';
                  } else if (parts.length == 1) {
                    initials = parts[0][0].toUpperCase();
                  } else {
                    initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
                  }
                } catch (_) {
                  initials = 'U';
                }

                return Container(
                  height: 45,
                  width: 45,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF2EAFF),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: GoogleFonts.manrope(
                      color: const Color(0xFF9C6BFF),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                );
              }),
              const SizedBox(width: 22),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.userName,
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
                          item.roleCapitalized,
                          style: GoogleFonts.manrope(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: Colors.black87,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Text(
                          item.timeAgo,
                          style: GoogleFonts.manrope(
                              color: Colors.black87, fontSize: 12),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              
            ],
          ),
        ),
      ),
    );
  }
}