import 'package:flutter/material.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Terms & Conditionsss',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.cyan,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00BCD4), Color(0xFF00838F)], // ✅ Cyan Gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              // ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.95),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child:
                            Icon(Icons.article, size: 50, color: Colors.cyan),
                      ),
                      const SizedBox(height: 15),

                      const Center(
                        child: Text(
                          "Terms & Conditions",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      _buildSectionTitle("1. Acceptance of Terms"),
                      _buildSectionContent(
                          "By using this App, you affirm that you have read, understood, and agree to these Terms and any future modifications."),

                      _buildSectionTitle("2. Use License"),
                      _buildSectionContent(
                          "You are granted permission for temporary personal use of the App. Any modification, distribution, or commercial use is prohibited."),

                      _buildSectionTitle("3. Disclaimer"),
                      _buildSectionContent(
                          "The materials on the App are provided 'as is.' We disclaim any express or implied warranties, including merchantability or fitness for a particular purpose."),

                      _buildSectionTitle("4. Limitations"),
                      _buildSectionContent(
                          "We are not liable for any damages arising from the use or inability to use this App, including but not limited to direct or indirect damages."),

                      _buildSectionTitle("5. Accuracy of Materials"),
                      _buildSectionContent(
                          "The materials in this App may include errors. We do not guarantee accuracy, completeness, or timeliness."),

                      _buildSectionTitle("6. Links"),
                      _buildSectionContent(
                          "We are not responsible for the content of external links. Their inclusion does not imply endorsement."),

                      _buildSectionTitle("7. Modifications to Terms"),
                      _buildSectionContent(
                          "We reserve the right to modify these Terms at any time. Continued use of the App indicates acceptance of changes."),

                      _buildSectionTitle("8. Governing Law"),
                      _buildSectionContent(
                          "These Terms are governed by the laws of [Your Country/State]. Any disputes shall be resolved in the appropriate courts."),

                      const SizedBox(height: 20),

                      // ✅ Agree Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyan,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            "I Agree",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Helper Method: Title Formatting
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 15.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  // ✅ Helper Method: Content Formatting
  Widget _buildSectionContent(String content) {
    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: Text(
        content,
        style: const TextStyle(
          fontSize: 16,
          height: 1.5,
          color: Colors.black54,
        ),
      ),
    );
  }
}
