import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/admin_verification.dart';
import '../services/admin_verification.dart';

/// Enhanced Admin Verification Details Page
class AdminPending extends StatefulWidget {
  final String verificationId;

  const AdminPending({super.key, required this.verificationId});

  @override
  State<AdminPending> createState() => _AdminPendingState();
}

class _AdminPendingState extends State<AdminPending>
    with SingleTickerProviderStateMixin {
  final TextEditingController _notesController = TextEditingController();
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminVerificationProvider>().loadVerificationDetail(
        widget.verificationId,
      );
    });
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _notesController.dispose();
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
              colors: [Colors.grey[200]!, Colors.grey[50]!, Colors.grey[200]!],
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

  Widget _buildDetailSkeleton() {
    return _buildShimmer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Status card skeleton (avatar + two lines)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF2EAFF),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 14, width: 200, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(height: 12, width: 120, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // User info skeleton (two-column layout)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 14, width: 180, color: Colors.white),
                        const SizedBox(height: 12),
                        Container(
                          height: 12,
                          width: double.infinity,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              height: 12,
                              width: 80,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Container(
                              height: 12,
                              width: 80,
                              color: Colors.white,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(height: 12, width: 140, color: Colors.white),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 12,
                          width: double.infinity,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 12,
                          width: double.infinity,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        Container(height: 12, width: 120, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Documents skeleton (button + preview)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 12, width: 160, color: Colors.white),
                  const SizedBox(height: 12),
                  Container(height: 14, width: 120, color: Colors.white),
                  const SizedBox(height: 12),
                  Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                ],
              ),
            ),

            // Action buttons skeleton (two small + one large)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            child: const Icon(
              Icons.chevron_left_rounded,
              size: 28,
              color: Color(0xFF2D3436),
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Verification Details',
          style: GoogleFonts.manrope(
            color: const Color(0xFF2D3436),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<AdminVerificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingDetail) {
            return _buildDetailSkeleton();
          }

          if (provider.detailErrorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red[400],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Something went wrong',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2D3436),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.detailErrorMessage!,
                      style: GoogleFonts.manrope(
                        color: const Color(0xFF636E72),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => provider.loadVerificationDetail(
                        widget.verificationId,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Retry',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final verification = provider.currentVerificationDetail;
          if (verification == null) {
            return Center(
              child: Text(
                'No verification found',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  color: const Color(0xFF636E72),
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _EnhancedStatusCard(verification: verification),
                const SizedBox(height: 16),
                _EnhancedUserInfoCard(verification: verification),
                const SizedBox(height: 16),
                if (!(verification.role == 'commuter' &&
                    (verification.commuterCategory?.toLowerCase() ==
                        'regular'))) ...[
                  _EnhancedDocumentsCard(verification: verification),
                  const SizedBox(height: 24),
                ],
                _EnhancedActionButtons(
                  verification: verification,
                  notesController: _notesController,
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Enhanced Status Card
class _EnhancedStatusCard extends StatelessWidget {
  final VerificationDetail verification;

  const _EnhancedStatusCard({required this.verification});

  Color _getStatusColor() {
    switch (verification.status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFA726);
      case 'approved':
        return const Color(0xFF66BB6A);
      case 'rejected':
        return const Color(0xFFEF5350);
      case 'lacking':
        return const Color(0xFFFF7043);
      default:
        return const Color(0xFF78909C);
    }
  }

  @override
  Widget build(BuildContext context) {
    String initials = 'U';
    try {
      final parts = verification.userName
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B53C2), Color(0xFF8E4CB6), Color(0xFFB945AA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6A1B9A).withAlpha((0.3 * 255).round()),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.1 * 255).round()),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: GoogleFonts.manrope(
                color: const Color(0xFF6A1B9A),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verification.userName,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((0.2 * 255).round()),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        verification.roleCapitalized,
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.white.withAlpha((0.8 * 255).round()),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      verification.timeAgo,
                      style: GoogleFonts.manrope(
                        color: Colors.white.withAlpha((0.9 * 255).round()),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _getStatusColor(),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _getStatusColor().withAlpha((0.3 * 255).round()),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              verification.status.toUpperCase(),
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Enhanced User Info Card
class _EnhancedUserInfoCard extends StatelessWidget {
  final VerificationDetail verification;

  const _EnhancedUserInfoCard({required this.verification});

  String _formatCommuterCategory(String? raw) {
    if (raw == null) return 'Regular';
    final val = raw.toLowerCase();
    switch (val) {
      case 'regular':
        return 'Regular';
      case 'senior':
        return 'Senior Citizen';
      case 'student':
        return 'Student';
      case 'pwd':
        return 'PWD';
      case 'discounted':
        return 'Discounted';
      default:
        return val.isEmpty
            ? 'Regular'
            : '${val[0].toUpperCase()}${val.substring(1)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Prepare operator attachments (if any) for rendering below
    final opAttachments = (verification.roleSpecificData != null && verification.roleSpecificData!['attachments'] != null)
        ? List<Map<String, dynamic>>.from(verification.roleSpecificData!['attachments'] as List)
        : <Map<String, dynamic>>[];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person,
                  size: 20,
                  color: Color(0xFF6A1B9A),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'User Information',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2D3436),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _InfoRow(
            label: 'Full Name',
            value: verification.userName,
            icon: Icons.badge,
          ),
          const SizedBox(height: 16),
          _InfoRow(
            label: 'Address',
            value: verification.address ?? 'Not provided',
            icon: Icons.location_on,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InfoRow(
                  label: 'Age',
                  value: verification.age?.toString() ?? 'N/A',
                  icon: Icons.cake,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoRow(
                  label: 'Sex',
                  value: verification.sex?.toUpperCase() ?? 'N/A',
                  icon: Icons.wc,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(
            label: 'User Type',
            value: verification.roleCapitalized,
            icon: Icons.verified_user,
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.grey[300], thickness: 1),
          const SizedBox(height: 20),
          if (verification.role == 'driver') ...[
            _InfoRow(
              label: 'License Number',
              value: verification.licenseNumber ?? 'Not provided',
              icon: Icons.credit_card,
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Vehicle Plate',
              value: verification.vehiclePlate ?? 'Not provided',
              icon: Icons.local_shipping,
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'PUV Type',
              value: verification.puvType ?? 'Not provided',
              icon: Icons.directions_bus,
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Operator',
              value: verification.operatorName ?? 'Not assigned',
              icon: Icons.business,
            ),
          ] else if (verification.role == 'commuter') ...[
            _InfoRow(
              label: 'Category',
              value: _formatCommuterCategory(verification.commuterCategory),
              icon: Icons.category,
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'ID Verified',
              value: verification.isIdVerified == true ? 'Yes' : 'No',
              icon: Icons.verified,
            ),
          ] else if (verification.role == 'operator') ...[
            _InfoRow(
              label: 'Company Name',
              value: verification.companyName ?? 'Not provided',
              icon: Icons.business,
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Contact Email',
              value: verification.contactEmail ?? 'Not provided',
              icon: Icons.email,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF636E72)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.manrope(
                  color: const Color(0xFF636E72),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.nunito(
                  color: const Color(0xFF2D3436),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Enhanced Documents Card
class _EnhancedDocumentsCard extends StatelessWidget {
  final VerificationDetail verification;

  const _EnhancedDocumentsCard({required this.verification});

  @override
  Widget build(BuildContext context) {
    // Prepare operator attachments (if any) for rendering below
    final opAttachments = (verification.roleSpecificData != null && verification.roleSpecificData!['attachments'] != null)
        ? List<Map<String, dynamic>>.from(verification.roleSpecificData!['attachments'] as List)
        : <Map<String, dynamic>>[];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.description,
                  size: 20,
                  color: Color(0xFF1976D2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Document',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2D3436),
                ),
              ),
            ],
          ),
            const SizedBox(height: 20),

            if (opAttachments.isNotEmpty) ...[
            // Render each operator attachment as a tappable card
            for (final att in opAttachments) ...[
              GestureDetector(
                onTap: () {
                  final url = att['url'] as String?;
                  if (url == null) return;
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      backgroundColor: Colors.black,
                      insetPadding: const EdgeInsets.all(20),
                      child: Stack(
                        children: [
                          InteractiveViewer(
                            child: Center(
                              child: Image.network(
                                url,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(
                                      Icons.error_outline,
                                      size: 48,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            top: 16,
                            right: 16,
                            child: IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5B53C2), Color(0xFFB945AA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF6A1B9A).withAlpha((0.3 * 255).round()),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.image,
                          size: 24,
                          color: Color(0xFFFF6B9A),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              att['type'] as String? ?? 'Document',
                              style: GoogleFonts.manrope(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap to view full image',
                              style: GoogleFonts.manrope(
                                color: Colors.white.withAlpha((0.9 * 255).round()),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((0.2 * 255).round()),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.visibility,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Show thumbnails grid
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[200]!, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: opAttachments.map((att) {
                    final url = att['url'] as String?;
                    return GestureDetector(
                      onTap: () {
                        if (url == null) return;
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            backgroundColor: Colors.black,
                            insetPadding: const EdgeInsets.all(20),
                            child: InteractiveViewer(
                              child: Image.network(url, fit: BoxFit.contain),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 120,
                        height: 80,
                        color: Colors.grey[100],
                        child: url != null
                            ? Image.network(url, fit: BoxFit.cover)
                            : Center(child: Icon(Icons.broken_image, color: Colors.grey[400])),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ] else if (verification.imageUrl != null) ...[
            // Single verification image (drivers and other roles)
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    backgroundColor: Colors.black,
                    insetPadding: const EdgeInsets.all(20),
                    child: Stack(
                      children: [
                        InteractiveViewer(
                          child: Center(
                            child: Image.network(
                              verification.imageUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(Icons.error_outline, size: 48, color: Colors.white),
                                );
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          top: 16,
                          right: 16,
                          child: IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[200]!, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Image.network(
                    verification.imageUrl!,
                    height: 240,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 240,
                        color: Colors.grey[100],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'Failed to load image',
                              style: GoogleFonts.manrope(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!, width: 2),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No document uploaded',
                      style: GoogleFonts.manrope(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Enhanced Action Buttons
class _EnhancedActionButtons extends StatelessWidget {
  final VerificationDetail verification;
  final TextEditingController notesController;

  const _EnhancedActionButtons({
    required this.verification,
    required this.notesController,
  });

  // We capture navigators/providers before awaiting; suppress the lint here.
  Future<void> _handleAction(BuildContext context, String action) async {
    // Capture provider, navigators, and messenger before any async gaps
    final provider = context.read<AdminVerificationProvider>();
    final navigator = Navigator.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);

    if (action == 'reject' || action == 'lacking') {
      // Use a captured context (navigator.context) so we don't hold onto
      // the original BuildContext across an async gap.
      final notes = await _showNotesDialog(navigator.context, action);
      if (notes == null) return;
      notesController.text = notes;
    }

    bool success = false;

    // If approving a commuter who isn't regular, prompt for category first
    if (action == 'approve' && verification.role == 'commuter' &&
        (verification.commuterCategory == null ||
            verification.commuterCategory!.toLowerCase() != 'regular')) {
      final selected = await _showCommuterCategoryDialog(navigator.context);
      if (selected == null) return; // user cancelled

      // Show progress dialog on root navigator so it can be popped reliably
      showDialog(
        context: rootNavigator.context,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (dialogCtx) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const CircularProgressIndicator(),
          ),
        ),
      );

      try {
        // Update commuter category before approving
        await AdminVerificationService()
            .updateCommuterCategory(verification.profileId, selected);
      } catch (e) {
        try {
          rootNavigator.pop();
        } catch (_) {}
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update commuter category: $e',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }
    } else {
      // Show progress dialog on root navigator so it can be popped reliably
      showDialog(
        context: rootNavigator.context,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (dialogCtx) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const CircularProgressIndicator(),
          ),
        ),
      );
    }

    try {
      switch (action) {
        case 'approve':
          success = await provider.approveVerification(
            verification.id,
            verification.profileId,
            notesController.text.isNotEmpty ? notesController.text : null,
          );
          break;
        case 'reject':
          success = await provider.rejectVerification(
            verification.id,
            notesController.text,
          );
          break;
        case 'lacking':
          success = await provider.markAsLacking(
            verification.id,
            notesController.text,
          );
          break;
      }

      // Close the progress dialog shown on the root navigator
      rootNavigator.pop();

      if (success) {
        if (action == 'approve') {
          await showDialog<void>(
            context: navigator.context,
            barrierDismissible: false,
            builder: (dialogCtx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.all(24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 48,
                      color: Color(0xFF66BB6A),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Success!',
                    style: GoogleFonts.manrope(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2D3436),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Verification approved successfully',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: const Color(0xFF636E72),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF66BB6A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'OK',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
          navigator.pop();
        } else {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'Verification ${action}ed successfully',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
          navigator.pop();
        }
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Failed to $action verification',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      try {
        // Ensure we attempt to pop the root progress dialog first
        rootNavigator.pop();
      } catch (_) {}

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<String?> _showNotesDialog(BuildContext context, String action) async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: action == 'reject'
                    ? const Color(0xFFFFEBEE)
                    : const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                action == 'reject' ? Icons.cancel : Icons.warning,
                color: action == 'reject'
                    ? const Color(0xFFEF5350)
                    : const Color(0xFFFFA726),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                action == 'reject' ? 'Rejection Reason' : 'Missing Documents',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: const Color(0xFF2D3436),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              action == 'reject'
                  ? 'Please provide a clear reason for rejecting this verification:'
                  : 'Please list the missing or incorrect documents:',
              style: GoogleFonts.manrope(
                color: const Color(0xFF636E72),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              autofocus: true,
              decoration: InputDecoration(
                hintText: action == 'reject'
                    ? 'E.g., Document is blurry and unreadable'
                    : 'E.g., Valid ID is missing, license has expired',
                hintStyle: GoogleFonts.manrope(
                  fontSize: 13,
                  color: Colors.grey[400],
                ),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: action == 'reject'
                        ? const Color(0xFFEF5350)
                        : const Color(0xFFFFA726),
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF636E72),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Please provide notes',
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                    ),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
                return;
              }
              Navigator.pop(context, controller.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'reject'
                  ? const Color(0xFFEF5350)
                  : const Color(0xFFFFA726),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              action == 'reject' ? 'Reject' : 'Mark as Lacking',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _showCommuterCategoryDialog(BuildContext context) async {
    String? selected;

    // Use the app's purple -> pink gradient and green confirm color
    const gradientColors = [Color(0xFF5B53C2), Color(0xFF8E4CB6), Color(0xFFB945AA)];
    const confirmColor = Color(0xFF66BB6A);

    return showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    gradient: const LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.category, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Select Commuter Category',
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CategoryOption(
                        label: 'Senior Citizen',
                        value: 'senior',
                        selected: selected,
                        onTap: (v) => setState(() => selected = v),
                      ),
                      const SizedBox(height: 12),
                      _CategoryOption(
                        label: 'PWD',
                        value: 'pwd',
                        selected: selected,
                        onTap: (v) => setState(() => selected = v),
                      ),
                      const SizedBox(height: 12),
                      _CategoryOption(
                        label: 'Student',
                        value: 'student',
                        selected: selected,
                        onTap: (v) => setState(() => selected = v),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Cancel', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (selected == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Please select a category', style: GoogleFonts.manrope()),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            Navigator.pop(context, selected);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: confirmColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text('Confirm', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (verification.status.toLowerCase() != 'pending') {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey[100]!, Colors.grey[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[300]!, width: 2),
        ),
        child: Column(
          children: [
            Icon(Icons.lock_outline, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No Actions Available',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF636E72),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'This verification has already been processed.',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  size: 20,
                  color: Color(0xFFFFA726),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Admin Actions',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2D3436),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Reject',
                  color: const Color(0xFFEF5350),
                  onTap: () => _handleAction(context, 'reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  label: 'Lacking',
                  color: const Color(0xFFFFA726),
                  onTap: () => _handleAction(context, 'lacking'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ActionButton(
            label: 'Approve Verification',
            color: const Color(0xFF66BB6A),
            onTap: () => _handleAction(context, 'approve'),
            isPrimary: true,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: isPrimary
                ? LinearGradient(
                    colors: [color, color.withAlpha((0.8 * 255).round())],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isPrimary ? null : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: isPrimary
                ? null
                : Border.all(
                    color: color.withAlpha((0.3 * 255).round()),
                    width: 2,
                  ),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(((isPrimary ? 0.3 : 0.1) * 255).round()),
                blurRadius: isPrimary ? 12 : 8,
                offset: Offset(0, isPrimary ? 4 : 2),
              ),
            ],
          ),
          child: Container(
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // No icon - text-only button for admin actions
                const SizedBox(width: 0),
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    color: isPrimary ? Colors.white : color,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
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

// Small option card for commuter categories
class _CategoryOption extends StatelessWidget {
  final String label;
  final String value;
  final String? selected;
  final void Function(String) onTap;

  const _CategoryOption({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selected == value;

    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5B53C2).withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF5B53C2) : Colors.grey[200]!,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.04 : 0.02),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2D3436),
                ),
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF5B53C2) : Colors.white,
                border: Border.all(
                  color: isSelected ? const Color(0xFF5B53C2) : Colors.grey[300]!,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}