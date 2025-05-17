import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_page.dart';
import 'vehicle_feedback_page.dart';
import 'notifications_page.dart';
import 'terms_conditions_page.dart';
import 'home_page.dart';
import 'add_page.dart';
import 'booking_history_page.dart';

class SettingsPage extends StatefulWidget {
  final Function(bool) onThemeChanged;

  const SettingsPage({super.key, required this.onThemeChanged});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00BCD4), Color(0xFF00838F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar with Title
              _buildAppBar(),

              // Settings List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const SizedBox(height: 20),
                    _buildSettingsOption(
                      title: "Profile",
                      icon: Icons.person,
                      onTap: () => _navigateTo(context, const ProfilePage()),
                    ),
                    _buildSettingsOption(
                      title: "My Vehicles & Feedbacks",
                      icon: Icons.feedback,
                      onTap: () =>
                          _navigateTo(context, const VehicleFeedbackPage()),
                    ),
                    _buildSettingsOption(
                      title: "Notifications",
                      icon: Icons.notifications,
                      onTap: () =>
                          _navigateTo(context, const NotificationsPage()),
                    ),
                    _buildSettingsOption(
                      title: "Terms & Conditions",
                      icon: Icons.description,
                      onTap: () =>
                          _navigateTo(context, const TermsConditionsPage()),
                    ),
                    _buildSettingsOption(
                      title: "My Bookings",
                      icon: Icons.history,
                      onTap: () =>
                          _navigateTo(context, const BookingHistoryPage()),
                    ),

                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }


  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Text(
            'Settings ⚙️',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

 
  Widget _buildSettingsOption({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.cyan[700]),
        title: Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.black54),
        onTap: onTap,
      ),
    );
  }

  
  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      selectedItemColor: Colors.cyan,
      unselectedItemColor: Colors.grey,
      currentIndex: 2,
      onTap: (index) {
        if (index == 0) {
          _navigateTo(
              context,
              HomePage(
                onThemeChanged: widget.onThemeChanged,
                isDarkMode: _isDarkMode, // ✅ Pass isDarkMode correctly
              ));
        } else if (index == 1) {
          _navigateTo(context, AddPage(onVehicleAdded: (vehicle) {}));
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    );
  }


  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }
}
