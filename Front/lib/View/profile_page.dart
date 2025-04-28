
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _username = 'Guest';
  String _email = 'guest@example.com';
  String _profileImage = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');

      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/auth/user-profile/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _username = data['username'] ?? 'Guest';
          _email = data['email'] ?? 'guest@example.com';
          _profileImage = data['profile_image'] ?? '';
          _isLoading = false;
        });
      } else {
        throw Exception("Failed to load user data");
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:8000/auth/user-profile/'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath(
        'profile_image',
        pickedFile.path,
      ));

      var response = await request.send();

      if (response.statusCode == 200) {
        _showMessage("✅ Profile photo updated!", Colors.green);
        _fetchUserData();
      } else {
        _showMessage("❌ Failed to upload image", Colors.red);
      }
    }
  }

  Future<void> _changePassword(
      String currentPassword, String newPassword) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');

      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/auth/change-password/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        _showMessage("✅ Password changed successfully", Colors.green);
      } else {
        final data = jsonDecode(response.body);
        _showMessage(data['error'] ?? "❌ Password change failed", Colors.red);
      }
    } catch (e) {
      _showMessage("❌ Error: $e", Colors.red);
    }
  }

  void _showChangePasswordDialog() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text("Change Password"),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPassController,
                  obscureText: obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(obscureCurrent
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () {
                        setState(() => obscureCurrent = !obscureCurrent);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPassController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                          obscureNew ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() => obscureNew = !obscureNew);
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: const Text("Change"),
                onPressed: () {
                  Navigator.pop(context);
                  _changePassword(
                    currentPassController.text.trim(),
                    newPassController.text.trim(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _showMessage("Logged out successfully!", Colors.green);

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => LoginPage(
          isDarkMode: false,
          onThemeChanged: (val) {},
        ),
      ),
      (route) => false,
    );
  }

  void _showImageOptions() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Profile Image Options", textAlign: TextAlign.center),
        content: SizedBox(
          height: 160,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.image_search),
                title: const Text("View Profile Image"),
                onTap: () {
                  Navigator.pop(context);
                  if (_profileImage.isNotEmpty) {
                    showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          child: Image.network(_profileImage),
                        ),
                      ),
                    );
                  } else {
                    _showMessage("No profile image available.", Colors.grey);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Select New Profile Image"),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessage(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("My Profile", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00BCD4), Color(0xFF00838F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00BCD4), Color(0xFF00838F)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 140, bottom: 40),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _showImageOptions,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF00BCD4),
                                    Color(0xFF00838F)
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 65,
                                backgroundColor: Colors.white,
                                backgroundImage: _profileImage.isNotEmpty
                                    ? NetworkImage(_profileImage)
                                    : null,
                                child: _profileImage.isEmpty
                                    ? Icon(Icons.person,
                                        size: 70, color: Colors.grey.shade700)
                                    : null,
                              ),
                            ),
                            const CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.edit, color: Color(0xFF00838F)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 35),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 20),
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.person_outline,
                                    color: Colors.white),
                                title: const Text("Username",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                                subtitle: Text(_username,
                                    style:
                                        const TextStyle(color: Colors.white70)),
                              ),
                              const Divider(color: Colors.white24),
                              ListTile(
                                leading: const Icon(Icons.email_outlined,
                                    color: Colors.white),
                                title: const Text("Email",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                                subtitle: Text(_email,
                                    style:
                                        const TextStyle(color: Colors.white70)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Card(
                          color: Colors.white.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            leading: const Icon(Icons.lock_reset,
                                color: Colors.white),
                            title: const Text(
                              "Change Password",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios,
                                color: Colors.white),
                            onTap: _showChangePasswordDialog,
                          ),
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
