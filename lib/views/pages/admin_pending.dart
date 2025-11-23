import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/admin_verification.dart';

/// Local styles for the Admin Pending page.
/// Kept here for simplicity so this file is self-contained.
class AdminPendingStyles {
  static const Color primaryPurple = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF6A1B9A);
  static const Color primaryPink = Color(0xFFFF6B9A);
  static const Color textBlack = Color(0xFF111111);
  static const Color secondaryYellow = Color(0xFFFFC857);
  static const Color borderColor = Color(0xFFE6E6E6);
  static const Color greyText = Color(0xFF8A8A8A);
}

class AdminPending extends StatefulWidget {
  final String verificationId;

  const AdminPending({
    super.key,
    required this.verificationId,
  });

  // Brand Colors (kept here for backwards compatibility)
  static const Color primaryPurple = AdminPendingStyles.primaryPurple;
  static const Color primaryDark = AdminPendingStyles.primaryDark;
  static const Color primaryPink = AdminPendingStyles.primaryPink;
  static const Color textBlack = AdminPendingStyles.textBlack;
  static const Color secondaryYellow = AdminPendingStyles.secondaryYellow;
  static const Color borderColor = AdminPendingStyles.borderColor;
  static const Color greyText = AdminPendingStyles.greyText;

  @override
  State<AdminPending> createState() => _AdminPendingState();
}

class _AdminPendingState extends State<AdminPending> with SingleTickerProviderStateMixin {
  final TextEditingController _notesController = TextEditingController();
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    // Load verification details when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminVerificationProvider>().loadVerificationDetail(widget.verificationId);
    });
    _shimmerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
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

  Widget _buildDetailSkeleton() {
    return _buildShimmer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(25, 20, 25, 40),
        child: Column(
          children: [
            // Status card skeleton
            Container(height: 70, width: double.infinity, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10))),
            // User info skeleton
            Container(height: 220, width: double.infinity, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10))),
            // Documents skeleton
            Container(height: 260, width: double.infinity, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10))),
            // Action buttons skeleton
            Container(height: 80, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Verification',
          style: GoogleFonts.manrope(
            color: AdminPending.textBlack,
            fontSize: 18,
            fontWeight: FontWeight.w700,
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    provider.detailErrorMessage!,
                    style: GoogleFonts.manrope(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadVerificationDetail(widget.verificationId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final verification = provider.currentVerificationDetail;
          if (verification == null) {
            return const Center(child: Text('No users found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(25, 20, 25, 40),
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                StatusCard(verification: verification),
                const SizedBox(height: 20),
                UserInfoCard(verification: verification),
                const SizedBox(height: 20),
                DocumentsCard(verification: verification),
                const SizedBox(height: 40),
                ActionButtons(
                  verification: verification,
                  notesController: _notesController,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// --- Components ---

class StatusCard extends StatelessWidget {
  final VerificationDetail verification;

  const StatusCard({super.key, required this.verification});

  // Status color helper removed — status label not displayed in this card.

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminPending.borderColor),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Initials avatar (consistent with trip details UI)
          Builder(builder: (_) {
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
              height: 36,
              width: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFF2EAFF),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: GoogleFonts.manrope(
                  color: const Color(0xFF9C6BFF),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            );
          }),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                verification.userName,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AdminPending.textBlack,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(verification.roleCapitalized, style: _metaStyle()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: CircleAvatar(
                        radius: 2, backgroundColor: Colors.black),
                  ),
                  Text(verification.timeAgo, style: _metaStyle()),
                ],
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  TextStyle _metaStyle() => GoogleFonts.manrope(
        color: Colors.black,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      );
}

class UserInfoCard extends StatelessWidget {
  final VerificationDetail verification;

  const UserInfoCard({super.key, required this.verification});

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
        // Capitalize first letter as a fallback
        return val.isEmpty ? 'Regular' : '${val[0].toUpperCase()}${val.substring(1)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminPending.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Information',
            style: GoogleFonts.manrope(
                fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InfoItem(
                        label: 'Fullname', value: verification.userName),
                    const SizedBox(height: 16),
                    InfoItem(
                        label: 'Address',
                        value: verification.address ?? 'Not provided'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InfoItem(
                              label: 'Age',
                              value: verification.age?.toString() ?? 'N/A'),
                        ),
                        Expanded(
                          child: InfoItem(
                              label: 'Sex',
                              value: verification.sex?.toUpperCase() ?? 'N/A'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    InfoItem(
                        label: 'User type',
                        value: verification.roleCapitalized),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [                    
                    if (verification.role == 'driver') ...[
                      InfoItem(
                          label: 'License Number',
                          value: verification.licenseNumber ?? 'Not provided'),
                      const SizedBox(height: 16),
                      InfoItem(
                          label: 'Vehicle Plate',
                          value: verification.vehiclePlate ?? 'Not provided'),
                      const SizedBox(height: 16),
                      InfoItem(
                          label: 'PUV Type',
                          value: verification.puvType ?? 'Not provided'),
                      const SizedBox(height: 16),
                      InfoItem(
                          label: 'Operator',
                          value: verification.operatorName ?? 'Not assigned'),
                    ] else if (verification.role == 'commuter') ...[
                      InfoItem(
                        label: 'Category',
                        value: _formatCommuterCategory(verification.commuterCategory),
                      ),
                      const SizedBox(height: 16),
                      InfoItem(
                          label: 'ID Verified',
                          value: verification.isIdVerified == true
                              ? 'Yes'
                              : 'No'),
                    ] else if (verification.role == 'operator') ...[
                      InfoItem(
                          label: 'Company Name',
                          value: verification.companyName ?? 'Not provided'),
                      const SizedBox(height: 16),
                      InfoItem(
                          label: 'Contact Email',
                          value: verification.contactEmail ?? 'Not provided'),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class InfoItem extends StatelessWidget {
  final String label;
  final String value;
  const InfoItem({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            color: Colors.black,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.manrope(
            color: AdminPending.textBlack,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class DocumentsCard extends StatelessWidget {
  final VerificationDetail verification;

  const DocumentsCard({super.key, required this.verification});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminPending.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Documents',
            style: GoogleFonts.manrope(
                fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 15),
          if (verification.imageUrl != null) ...[
            GestureDetector(
              onTap: () {
                // Show full image in dialog
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppBar(
                          title: const Text('Document Image'),
                          automaticallyImplyLeading: true,
                        ),
                        Expanded(
                          child: InteractiveViewer(
                            child: Image.network(
                              verification.imageUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(Icons.error_outline, size: 48),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AdminPending.primaryDark,
                      AdminPending.primaryPink
                    ],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.image,
                          size: 16, color: AdminPending.primaryPink),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          verification.verificationType,
                          style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Tap to view',
                          style: GoogleFonts.manrope(
                              color: Colors.white70,
                              fontSize: 9,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.visibility, color: Colors.white70, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Preview image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                verification.imageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 48),
                    ),
                  );
                },
              ),
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  'No document uploaded',
                  style: GoogleFonts.manrope(
                      color: Colors.grey[600], fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ActionButtons extends StatelessWidget {
  final VerificationDetail verification;
  final TextEditingController notesController;

  const ActionButtons({
    super.key,
    required this.verification,
    required this.notesController,
  });

  Future<void> _handleAction(
    BuildContext context,
    String action,
  ) async {
    // Show notes dialog for reject or lacking
    if (action == 'reject' || action == 'lacking') {
      final notes = await _showNotesDialog(context, action);
      if (notes == null) return; // User cancelled
      notesController.text = notes;
    }

    final provider = context.read<AdminVerificationProvider>();
    bool success = false;

    // Capture navigator and messenger before any async gaps so we don't
    // use BuildContext after awaiting (avoid use_build_context_synchronously).
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

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

      // Close loading dialog
      navigator.pop();

      if (success) {
        // Show success message. For 'approve' show a modal dialog; for
        // other actions continue to use a snackbar.
        if (action == 'approve') {
          // Show modal using the captured navigator context so we don't use
          // the original BuildContext after awaiting async work.
          await showDialog<void>(
            context: navigator.context,
            barrierDismissible: false,
            builder: (dialogCtx) => AlertDialog(
              title: const Text('Success'),
              content: const Text('Verification approved successfully'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );

          // After modal is dismissed, go back to the list
          navigator.pop();
        } else {
          // Show success message and go back to list for other actions
          messenger.showSnackBar(
            SnackBar(
              content: Text('Verification ${action}d successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Go back to list
          navigator.pop();
        }
      } else {
        // Show error message
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to $action verification'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      try {
        navigator.pop();
      } catch (_) {}

      // Show error
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _showNotesDialog(BuildContext context, String action) async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          action == 'reject' ? 'Rejection Reason' : 'Missing Documents',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: action == 'reject'
                ? 'Explain why this verification is rejected...'
                : 'List the missing or incorrect documents...',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide notes')),
                );
                return;
              }
              Navigator.pop(context, controller.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'reject' ? Colors.red : Colors.orange,
            ),
            child: Text(action == 'reject' ? 'Reject' : 'Mark as Lacking'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only show buttons if status is pending
    if (verification.status.toLowerCase() != 'pending') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'No actions available for this verification.',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _handleAction(context, 'reject'),
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.red[300]!),
                    boxShadow: [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Reject',
                    style: GoogleFonts.nunito(
                      color: Colors.red[400],
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => _handleAction(context, 'lacking'),
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.orange[300]!),
                    boxShadow: [
                      BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Lacking',
                    style: GoogleFonts.nunito(
                      color: Colors.orange[700],
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => _handleAction(context, 'approve'),
          child: Container(
            height: 45,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AdminPending.primaryPink,
                  AdminPending.primaryDark,
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2))
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              'Approve',
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}