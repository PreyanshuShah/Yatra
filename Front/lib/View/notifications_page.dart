import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // ✅ For formatting date

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  final Set<int> _expandedNotifications = {}; // ✅ Track expanded notifications

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  /// ✅ Fetch Notifications from API
  Future<void> _fetchNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token =
        prefs.getString('access_token'); // ✅ Get stored access token

    final response = await http.get(
      Uri.parse('http://127.0.0.1:8000/auth/notifications/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List<dynamic> notifications = json.decode(response.body);
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } else {
      print('❌ Failed to load notifications');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// ✅ Format Date to "yyyy-MM-dd HH:mm"
  String _formatDate(String dateTime) {
    try {
      DateTime parsedDate = DateTime.parse(dateTime);
      return DateFormat('yyyy-MM-dd HH:mm').format(parsedDate);
    } catch (e) {
      return dateTime; // Fallback if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.cyan,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text("📭 No notifications available."))
              : RefreshIndicator(
                  onRefresh: _fetchNotifications, // ✅ Pull-to-Refresh
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      bool isExpanded =
                          _expandedNotifications.contains(notification['id']);

                      return Card(
                        margin: const EdgeInsets.all(10),
                        elevation: 4,
                        color: notification['is_read']
                            ? Colors.white
                            : Colors
                                .cyan[50], // ✅ Highlight unread notifications
                        child: Column(
                          children: [
                            ListTile(
                              leading: notification['is_read']
                                  ? const Icon(Icons.notifications_none,
                                      color: Colors.grey)
                                  : const Icon(Icons.notifications_active,
                                      color: Colors.cyan),
                              title: const Text(
                                "New Notification", // ✅ Only show title, not message
                                style: TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                  "📅 Received: ${_formatDate(notification['created_at'])}"),
                              trailing: Icon(
                                isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: Colors.grey,
                              ),
                              onTap: () {
                                setState(() {
                                  if (isExpanded) {
                                    _expandedNotifications
                                        .remove(notification['id']);
                                  } else {
                                    _expandedNotifications
                                        .add(notification['id']);
                                  }
                                });
                              },
                            ),

                            // ✅ Show Full Message only when Expanded
                            if (isExpanded)
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Text(
                                  notification[
                                      'message'], // Show message only when expanded
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
