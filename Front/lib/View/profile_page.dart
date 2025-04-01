import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

import 'login_page.dart'; // ✅ Import Login Page

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
      print('Error: $e');
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
        title: const Text("Profile Options", textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
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
            tooltip: 'Logout',
            onPressed: _logout,
          )
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.cyan, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.cyan, Colors.blueAccent],
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
                      // Profile Picture + Edit
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
                                  colors: [Colors.cyan, Colors.blueAccent],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.3),
                                    blurRadius: 25,
                                    spreadRadius: 3,
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
                              child: Icon(Icons.edit, color: Colors.blueAccent),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 35),

                      // Info Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 20),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.person_outline,
                                      color: Colors.cyan),
                                  title: const Text("Username",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Text(_username),
                                ),
                                const Divider(),
                                ListTile(
                                  leading: const Icon(Icons.email_outlined,
                                      color: Colors.cyan),
                                  title: const Text("Email",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Text(_email),
                                ),
                              ],
                            ),
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
