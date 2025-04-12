import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'home_page.dart';
import 'forgot_password_page.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool isDarkMode;

  const LoginPage(
      {super.key, required this.onThemeChanged, required this.isDarkMode});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  /// 🔹 Logs in the user and stores access & refresh tokens yes
  Future<void> _loginUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final response = await http.post(
          Uri.parse('http://127.0.0.1:8000/auth/login/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': _usernameController.text.trim(),
            'password': _passwordController.text.trim(),
          }),
        );

        final responseData = jsonDecode(response.body);

        if (response.statusCode == 200) {
          String accessToken = responseData['tokens']['access'];
          String refreshToken =
              responseData['tokens']['refresh']; // ✅ Get refresh token

          // ✅ Save tokens in SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', accessToken);
          await prefs.setString('refresh_token', refreshToken);
          await prefs.setString('username', _usernameController.text.trim());

          print('Access Token: $accessToken'); // Debugging
          print('Refresh Token: $refreshToken'); // Debugging

          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Login Successful!')),
          );

          // ✅ Navigate to HomePage
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(
                  onThemeChanged: widget.onThemeChanged,
                  isDarkMode: widget.isDarkMode),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    responseData['detail'] ?? 'Invalid username or password')),
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
            colors: [Color(0xFF00BCD4), Color(0xFF00838F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ✅ Bigger App Logo
                  Image.asset(
                    'assets/images/logo.png',
                    height: 320,
                    width: 400,
                  ),
                  const SizedBox(height: 0),

                  const Text(
                    "Welcome Back!",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Login to continue renting vehicles",
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 30),

                  _buildTextField(
                      'Username', _usernameController, Icons.person),
                  const SizedBox(height: 15),

                  _buildTextField('Password', _passwordController, Icons.lock,
                      obscureText: true),
                  const SizedBox(height: 20),

                  // ✅ Login Button
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _loginUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                            ),
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                  color: Colors.cyan,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                  const SizedBox(height: 20),

                  // ✅ Forgot Password Button
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ForgotPasswordPage()),
                      );
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ✅ "Don't have an account? Sign Up" Option
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SignupPage(
                              onThemeChanged: widget.onThemeChanged,
                              isDarkMode: widget.isDarkMode),
                        ),
                      );
                    },
                    child: const Text(
                      "Don't have an account? Sign Up",
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
      {bool obscureText = false}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
      ),
      validator: (value) =>
          value!.isEmpty ? '⚠️ Please enter your $label' : null,
    );
  }
}
