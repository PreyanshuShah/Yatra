import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _username = 'Guest';
  String _email = 'guest@example.com';
  String _profileImage = ''; // ✅ Profile Image URL
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  /// **Fetch User Data from API**
  Future<void> _fetchUserData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        throw Exception("No access token found. Please log in again.");
      }

      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/auth/user-profile/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        setState(() {
          _username = data['username'] ?? 'Guest';
          _email = data['email'] ?? 'guest@example.com';
          _profileImage = data['profile_image'] ?? '';
          _isLoading = false;
        });

        prefs.setString('username', _username);
        prefs.setString('email', _email);
        prefs.setString('profile_image', _profileImage);
      } else {
        throw Exception("Failed to fetch user details");
      }
    } catch (e) {
      print("Error fetching user details: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// **Function to Change Password**
  Future<void> _changePassword(
      String currentPassword, String newPassword) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        throw Exception("No access token found. Please log in again.");
      }

      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/auth/change-password/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
            {"current_password": currentPassword, "new_password": newPassword}),
      );

      if (response.statusCode == 200) {
        _showMessage("Password changed successfully!", Colors.green);
      } else {
        final data = jsonDecode(response.body);
        _showMessage(data['error'] ?? "Failed to change password", Colors.red);
      }
    } catch (e) {
      print("Error changing password: $e");
      _showMessage("An error occurred. Try again!", Colors.red);
    }
  }

  void _showChangePasswordDialog() {
    TextEditingController currentPasswordController = TextEditingController();
    TextEditingController newPasswordController = TextEditingController();
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20), // ✅ Rounded edges
              ),
              title: const Text(
                "Change Password",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ✅ Current Password Field
                    TextField(
                      controller: currentPasswordController,
                      obscureText: obscureCurrentPassword,
                      decoration: InputDecoration(
                        labelText: "Current Password",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(obscureCurrentPassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              obscureCurrentPassword = !obscureCurrentPassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // ✅ New Password Field
                    TextField(
                      controller: newPasswordController,
                      obscureText: obscureNewPassword,
                      decoration: InputDecoration(
                        labelText: "New Password",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        prefixIcon: const Icon(Icons.vpn_key),
                        suffixIcon: IconButton(
                          icon: Icon(obscureNewPassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              obscureNewPassword = !obscureNewPassword;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                // ❌ Cancel Button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child:
                      const Text("Cancel", style: TextStyle(color: Colors.red)),
                ),

                // ✅ Change Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    _changePassword(
                      currentPasswordController.text.trim(),
                      newPasswordController.text.trim(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text("Change"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// **Show Message SnackBar**
  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  /// **Logout Function**
  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan, // ✅ Matches the theme
        title: const Text("Profile", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00BCD4), Color(0xFF00838F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 50),

                      // ✅ Profile Picture
                      CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.white,
                        backgroundImage: _profileImage.isNotEmpty
                            ? NetworkImage(_profileImage)
                            : null,
                        child: _profileImage.isEmpty
                            ? Icon(Icons.person,
                                size: 80, color: Colors.grey.shade800)
                            : null,
                      ),

                      const SizedBox(height: 20),

                      // ✅ Profile Card with Shadow
                      Card(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 8,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.person,
                                    color: Colors.cyan),
                                title: Text(
                                  'Username: $_username',
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                              const Divider(),
                              ListTile(
                                leading:
                                    const Icon(Icons.email, color: Colors.cyan),
                                title: Text(
                                  'Email: $_email',
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ✅ Change Password Button
                      ElevatedButton.icon(
                        onPressed: _showChangePasswordDialog,
                        icon: const Icon(Icons.lock),
                        label: const Text("Change Password"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 12),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ✅ Logout Button
                      ElevatedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        label: const Text("Logout"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}
