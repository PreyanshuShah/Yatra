import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'login_page.dart'; // Navigate to Login Page after signup oks

class SignupPage extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool isDarkMode;

  const SignupPage(
      {super.key, required this.onThemeChanged, required this.isDarkMode});

  @override
  _SignupPageState createState() => _SignupPageState();
}

Future<void> saveUserData(String username, String email) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('username', username);
  await prefs.setString('email', email);
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final response = await http.post(
          Uri.parse('http://127.0.0.1:8000/auth/register/'), // Your API URL
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': _usernameController.text.trim(),
            'email': _emailController.text.trim(),
            'password': _passwordController.text.trim(),
          }),
        );

        final responseData = jsonDecode(response.body);

        if (response.statusCode == 200 || response.statusCode == 201) {
          saveUserData(
              _usernameController.text.trim(), _emailController.text.trim());

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? '✅ Signup Successful!'),
            ),
          );

          // Navigate to Login Page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LoginPage(
                  onThemeChanged: widget.onThemeChanged,
                  isDarkMode: widget.isDarkMode),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['error'] ?? '❌ Signup failed')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ Network error: $e')),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00BCD4), Color(0xFF00838F)], // ✅ Cyan Gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ✅ App Logo
                  Image.asset(
                    'assets/images/logo.png',
                    height: 200, // 🔥 Bigger logo
                  ),
                  const SizedBox(height: 20),

                  // ✅ Signup Title
                  const Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Join Yatra and rent vehicles effortlessly!",
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // ✅ Username Field
                  _buildTextField(
                      "Username", _usernameController, Icons.person),
                  const SizedBox(height: 15),

                  // ✅ Email Field
                  _buildTextField("Email", _emailController, Icons.email,
                      isEmail: true),
                  const SizedBox(height: 15),

                  // ✅ Password Field
                  _buildTextField("Password", _passwordController, Icons.lock,
                      obscureText: true),
                  const SizedBox(height: 20),

                  // ✅ Signup Button
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _registerUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                            ),
                            child: const Text(
                              "Sign Up",
                              style: TextStyle(
                                  color: Colors.cyan,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                  const SizedBox(height: 20),

                  // ✅ Already have an account? Login
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginPage(
                              onThemeChanged: widget.onThemeChanged,
                              isDarkMode: widget.isDarkMode),
                        ),
                      );
                    },
                    child: const Text(
                      "Already have an account? Login",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon,
      {bool obscureText = false, bool isEmail = false}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        filled: true,
        fillColor: Colors.white24,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none),
        prefixIcon: Icon(icon, color: Colors.white),
      ),
      validator: (value) {
        if (value!.isEmpty) return "⚠️ Please enter your $label";
        if (isEmail &&
            !RegExp(r"^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$")
                .hasMatch(value)) {
          return "⚠️ Please enter a valid email";
        }
        if (label == "Password" && value.length < 6) {
          return "⚠️ Password must be at least 6 characters";
        }
        return null;
      },
    );
  }
}
