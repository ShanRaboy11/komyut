import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  bool isEditing = false;

  final Color primary1 = const Color(0xFF8E4CB6);

  // controllers for the text fields
  final TextEditingController emailController = TextEditingController(
    text: "juandelacruz@gmail.com",
  );
  final TextEditingController firstNameController = TextEditingController(
    text: "Juan",
  );
  final TextEditingController lastNameController = TextEditingController(
    text: "Dela Cruz",
  );
  final TextEditingController ageController = TextEditingController(text: "18");
  final TextEditingController sexController = TextEditingController(
    text: "Male",
  );
  final TextEditingController addressController = TextEditingController(
    text: "Bulacao, Cebu City, Cebu 6000",
  );
  final TextEditingController operatorController = TextEditingController(
    text: "Student",
  );
  final TextEditingController licenseIdController = TextEditingController(
    text: "1234567890",
  );

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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfilePage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          "Personal Info",
                          style: GoogleFonts.manrope(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          isEditing = !isEditing;
                        });
                      },
                      icon: Icon(Icons.edit_outlined, color: primary1),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // --- Email ---
                _buildLabel("Email Address"),
                _buildTextField(emailController),

                // --- First & Last Name ---
                _buildLabel("First Name"),
                _buildTextField(firstNameController),

                _buildLabel("Last Name"),
                _buildTextField(lastNameController),

                // --- Age & Sex ---
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Age"),
                          _buildTextField(ageController),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Sex"),
                          _buildTextField(sexController),
                        ],
                      ),
                    ),
                  ],
                ),

                // --- Address ---
                _buildLabel("Full Address"),
                _buildTextField(addressController),

                // --- Operator ---
                _buildLabel("Category"),
                _buildTextField(operatorController),

                // --- Driver’s License ---
                _buildLabel("ID"),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Color.fromARGB(255, 161, 165, 170),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/ID.png', // Replace with your asset
                      fit: BoxFit.cover,
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

  // Label Text
  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontWeight: FontWeight.w600,
          fontSize: 14.5,
          color: Colors.black87,
        ),
      ),
    );
  }

  // Text Field
  Widget _buildTextField(TextEditingController controller) {
    return TextField(
      controller: controller,
      readOnly: !isEditing,
      decoration: InputDecoration(
        filled: true,
        fillColor: isEditing ? Colors.white : Colors.transparent,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Color.fromARGB(255, 161, 165, 170),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary1, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 12,
        ),
      ),
      style: GoogleFonts.nunito(fontSize: 15, color: Colors.black87),
    );
  }
}
