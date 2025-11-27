import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminRejectPage extends StatefulWidget {
  const AdminRejectPage({super.key});

  @override
  State<AdminRejectPage> createState() => _AdminRejectPageState();
}

class _AdminRejectPageState extends State<AdminRejectPage> {
  // State variables for editing logic
  bool _isEditingReason = false;
  late TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    // Initialize with the default rejection text
    _reasonController = TextEditingController(
      text: 'The photo provided is not clear. Please retake your document in a well-lit area, ensure the entire ID is visible, and remove unnecessary things before submitting again.',
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

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
            // --- 1. User Profile Summary (Rejected Style) ---
            _buildSummaryCard(),

            const SizedBox(height: 16),

            // --- 2. User Information Details ---
            _buildUserInfoCard(),

            const SizedBox(height: 16),

            // --- 3. Documents Section ---
            _buildDocumentsCard(),

            const SizedBox(height: 16),

            // --- 4. Rejection Reason Section (Editable) ---
            _buildRejectionReasonCard(),

            const SizedBox(height: 30),

            // --- 5. Action Buttons (Cancel / Done) ---
            _buildActionButtons(context),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- Widget: Summary Card (Rejected) ---
  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF8E4CB6), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
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
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Text(
                      '5m ago',
                      style: GoogleFonts.manrope(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- REJECTED BADGE ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE64646), // Red for Rejected
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Rejected',
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
        borderRadius: BorderRadius.circular(10),
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
                child: _buildLabelValue('Fullname', 'Juan dela Cruz'),
              ),
              Expanded(
                flex: 1,
                child: _buildLabelValue('Age', '20'),
              ),
              Expanded(
                flex: 1,
                child: _buildLabelValue('Sex', 'M'),
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
                child: _buildLabelValue('Address', 'N. Bacalso Avenue, Cebu City'),
              ),
              Expanded(
                flex: 2,
                child: _buildLabelValue('Category', 'Student, PWD, Senior Citizen'),
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
                child: _buildLabelValue('Email Address', 'juandelacruz@gmail.com'),
              ),
              Expanded(
                flex: 2,
                child: _buildLabelValue('User type', 'Commuter'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Widget: Documents Card ---
  Widget _buildDocumentsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(10),
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
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
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
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget: Rejection Reason Card (Updated) ---
  Widget _buildRejectionReasonCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF8E4CB6), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rejection Reason',
            style: GoogleFonts.manrope(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),

          // --- EDIT LOGIC START ---
          if (_isEditingReason)
            // If editing, show TextField
            TextField(
              controller: _reasonController,
              maxLines: null, // Allow multiline
              style: GoogleFonts.manrope(
                color: Colors.black,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.all(8),
              ),
            )
          else
            // If not editing, show Text
            Text(
              _reasonController.text,
              style: GoogleFonts.manrope(
                color: Colors.black,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          // --- EDIT LOGIC END ---

          const SizedBox(height: 16),

          // Edit/Save Button aligned to the right
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () {
                setState(() {
                  // Toggle editing state
                  _isEditingReason = !_isEditingReason;
                });
              },
              borderRadius: BorderRadius.circular(15),
              child: Container(
                width: 65,
                height: 24,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB945AA), Color(0xFF8E4CB6), Color(0xFF5B53C2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    // Change text based on state
                    _isEditingReason ? 'Save' : 'Edit',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget: Action Buttons (Cancel & Done) ---
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Cancel Button
        InkWell(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 100,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFB0B9C6)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Cancel',
                style: GoogleFonts.nunito(
                  color: const Color(0xFFB0B9C6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),

        // Done Button
        InkWell(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 100,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB945AA), Color(0xFF8E4CB6), Color(0xFF5B53C2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Done',
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
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
            color: Colors.black,
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
}