import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminPending extends StatelessWidget {
  const AdminPending({super.key});

  // Brand Colors
  static const Color primaryPurple = Color(0xFF8E4CB6);
  static const Color primaryDark = Color(0xFF5B53C2);
  static const Color primaryPink = Color(0xFFB945AA);
  static const Color textBlack = Color(0xFF222222);
  static const Color secondaryYellow = Color(0xFFFFBF00);
  static const Color borderColor = Color(0xFF8E4CB6);
  static const Color greyText = Color(0xFFB0B9C6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // Modified: Removed the Container with grey background
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          onPressed: () {
            // Go back to the Admin Verified Page
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Verification',
          style: GoogleFonts.manrope(
            color: textBlack,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      // Modified: Removed Stack and PurpleBottomNavBar
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(25, 20, 25, 40), 
        physics: const BouncingScrollPhysics(),
        child: const Column(
          children: [
            StatusCard(),
            SizedBox(height: 20),
            UserInfoCard(),
            SizedBox(height: 20),
            DocumentsCard(),
            SizedBox(height: 40),
            ActionButtons(),
          ],
        ),
      ),
    );
  }
}

// --- Components ---

class StatusCard extends StatelessWidget {
  const StatusCard({super.key});

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
            color: Colors.black,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFD9D9D9),
            child: Icon(Icons.person, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Juan dela Cruz',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AdminPending.textBlack,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text('Driver', style: _metaStyle()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: CircleAvatar(radius: 2, backgroundColor: Colors.black),
                  ),
                  Text('5m ago', style: _metaStyle()),
                ],
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AdminPending.secondaryYellow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Pending',
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

  TextStyle _metaStyle() => GoogleFonts.manrope(
    color: Colors.black,
    fontSize: 11,
    fontWeight: FontWeight.w700,
  );
}

class UserInfoCard extends StatelessWidget {
  const UserInfoCard({super.key});

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
            style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InfoItem(label: 'Fullname', value: 'Juan dela Cruz'),
                    SizedBox(height: 16),
                    InfoItem(label: 'Address', value: 'N. Bacalso Avenue, Cebu City'),
                    SizedBox(height: 16),
                    InfoItem(label: 'Email Address', value: 'juandelacruz@gmail.com'),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Expanded(child: InfoItem(label: 'Age', value: '30')),
                        Expanded(child: InfoItem(label: 'Sex', value: 'M')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const InfoItem(label: 'User type', value: 'Driver'),
                    const SizedBox(height: 16),
                    const InfoItem(label: 'License Number', value: 'N12-345-678901'),
                    const SizedBox(height: 16),
                    const InfoItem(label: 'Operator', value: 'Hector dela Merced'),
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
  const DocumentsCard({super.key});

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
            style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AdminPending.primaryDark, AdminPending.primaryPink],
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
                  child: const Icon(Icons.upload_file, size: 16, color: AdminPending.primaryPink),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload license',
                      style: GoogleFonts.manrope(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Front & Back',
                      style: GoogleFonts.manrope(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.download, color: Colors.white70, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ActionButtons extends StatelessWidget {
  const ActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: InkWell(
            onTap: () => debugPrint("Reject Clicked"),
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: AdminPending.greyText),
                boxShadow: [
                   BoxShadow(color: Colors.black, blurRadius: 4, offset: const Offset(0, 2))
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                'Reject',
                style: GoogleFonts.nunito(
                  color: AdminPending.greyText,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: InkWell(
            onTap: () => debugPrint("Approve Clicked"),
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AdminPending.primaryPink,
                    AdminPending.primaryDark
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(color: Colors.black, blurRadius: 4, offset: const Offset(0, 2))
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
        ),
      ],
    );
  }
}