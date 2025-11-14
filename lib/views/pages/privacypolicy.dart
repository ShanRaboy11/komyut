import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width * 0.07;

    return Scaffold(
      backgroundColor: Color(0xFFF7F4FF),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF8F4FF), Color(0xFFF7F4FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Header ---
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.black87,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          "Privacy Policy",
                          style: GoogleFonts.manrope(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // balance arrow icon space
                  ],
                ),
                const SizedBox(height: 30),

                // --- Last Update ---
                Text(
                  "Last Update: 10/03/2025",
                  style: GoogleFonts.nunito(
                    color: const Color(0xFF8E4CB6),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),

                // --- Introduction ---
                Text(
                  "Welcome to Komyut. We are committed to protecting your privacy and ensuring transparency in how we handle your personal information. This Privacy Policy and Terms & Conditions ('Policy') explains how we collect, use, store, and safeguard your data when you use our app and services. By using Komyut, you agree to this Policy.",
                  style: GoogleFonts.nunito(
                    color: Colors.black87,
                    height: 1.6,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 30),

                // --- Terms & Conditions Header ---
                Text(
                  "Terms & Conditions",
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF8E4CB6),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                // --- Terms List ---
                _buildListItem(
                  "1. Information We Collect – We may collect your name, contact details, photo, valid IDs (for students, seniors, PWDs), driver’s license (for drivers), company details (for operators), and trip/transaction data including Wheel Tokens and application use.",
                ),
                _buildListItem(
                  "2. Use of Information – Your data is used to manage accounts, validate discounts, verify drivers and operators, process trips and rewards, ensure security, and comply with the law.",
                ),
                _buildListItem(
                  "3. Sharing – We do not sell your data. It may only be shared with regulators, co-drivers/operators for validation, or trusted providers for app functionality.",
                ),
                _buildListItem(
                  "4. Data Security & Retention – We apply safeguards to protect your data and keep it only as long as needed for service, legal, or dispute purposes.",
                ),
                _buildListItem(
                  "5. Your Rights – You may access, update, or request deletion of your data, withdraw consent for certain uses, and file complaints under the Data Privacy Act of 2012.",
                ),
                _buildListItem(
                  "6. Proper Use – Users must provide valid IDs/licenses, keep accounts secure, and avoid fraudulent or abusive activities. Discounts apply only with valid IDs.",
                ),
                _buildListItem(
                  "7. Rewards – Wheel Tokens are earned per trip and may be redeemed as peso credits, subject to app rules.",
                ),
                _buildListItem(
                  "8. Service & Liability – Komyut may modify or discontinue services/features at any time. We are not liable for accidents, disputes, or events beyond our control.",
                ),
                _buildListItem(
                  "9. Termination – Accounts may be suspended or terminated for violations or misuse.",
                ),
                const SizedBox(height: 30),

                // --- Updates ---
                Text(
                  "Updates To This Policy",
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF8E4CB6),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "We may update this Privacy Policy and T&C from time to time. Users will be notified of significant changes via in-app notice or email.",
                  style: GoogleFonts.nunito(
                    color: Colors.black87,
                    height: 1.6,
                    fontSize: 14.5,
                  ),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 30),

                // --- Contact Us ---
                Text(
                  "Contact Us",
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF8E4CB6),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "For concerns or questions regarding this Policy, please contact us at komyut@gmail.com",
                  style: GoogleFonts.nunito(
                    color: Colors.black87,
                    height: 1.6,
                    fontSize: 14.5,
                  ),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper for list items ---
  Widget _buildListItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: GoogleFonts.nunito(
          color: Colors.black87,
          height: 1.6,
          fontSize: 14.5,
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }
}
