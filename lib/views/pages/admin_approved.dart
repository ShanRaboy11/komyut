import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminApprovePage extends StatelessWidget {
  const AdminApprovePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF222222), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Verification',
          style: GoogleFonts.manrope(
            color: const Color(0xFF222222),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // --- 1. User Profile Summary (Added Shadow) ---
            _buildSummaryCard(),

            const SizedBox(height: 16),

            // --- 2. User Information Details ---
            _buildUserInfoCard(),

            const SizedBox(height: 16),

            // --- 3. Documents Section ---
            _buildDocumentsCard(),
          ],
        ),
      ),
    );
  }

  // --- Widget: Summary Card (Added Shadow) ---
  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(12),
        // Purple Border
        border: Border.all(color: const Color(0xFF8E4CB6), width: 1), 
        // --- NEW: Added Shadow ---
        boxShadow: [
          BoxShadow(
            color: Colors.black, // Soft shadow
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar (Updated with User Icon)
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFD9D9D9), 
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: Color(0xFF222222),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          
          // Name and Role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Juan dela Cruz',
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF222222),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Commuter', 
                      style: GoogleFonts.manrope(
                        color: Colors.black.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Text(
                      '5m ago',
                      style: GoogleFonts.manrope(
                        color: Colors.black.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- APPROVED BADGE ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF33AF5B), // Green
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Approved',
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget: User Info Card ---
  Widget _buildUserInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8E4CB6), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Information',
            style: GoogleFonts.manrope(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),

          // Row 1
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3, 
                child: _buildLabelValue('Fullname', 'Juan dela Cruz')
              ),
              Expanded(
                flex: 1, 
                child: _buildLabelValue('Age', '20')
              ),
              Expanded(
                flex: 1, 
                child: _buildLabelValue('Sex', 'M')
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Row 2
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildLabelValue('Address', 'N. Bacalso Avenue, Cebu City')
              ),
              Expanded(
                flex: 2,
                child: _buildLabelValue('Category', 'Student, PWD, Senior Citizen')
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Row 3
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildLabelValue('Email Address', 'juandelacruz@gmail.com')
              ),
              Expanded(
                flex: 2,
                child: _buildLabelValue('User type', 'Commuter')
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Helper: Label + Value Text ---
  Widget _buildLabelValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            color: Colors.black.withValues(alpha: 0.60),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.manrope(
            color: const Color(0xFF222222),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  // --- Widget: Documents Card ---
  Widget _buildDocumentsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8E4CB6), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Documents',
            style: GoogleFonts.manrope(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          
          // Purple Gradient Bar
          Container(
            height: 55,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5B53C2), Color(0xFFB945AA)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // White Icon Box
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Text Info
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload ID',
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Front & Back',
                      style: GoogleFonts.manrope(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                const Spacer(),
                
                // Settings/Verify Icon
                const Icon(
                  Icons.verified, 
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}