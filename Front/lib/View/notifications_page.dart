// ignore: file_names
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:front/helpers/notification_helper.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  final Set<int> _expandedNotifications = {};
  Set<int> _shownNotificationIds = {};
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    NotificationHelper.initialize();
    _loadShownIds().then((_) => _fetchNotifications());
    _notificationTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchNotifications();
    });
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadShownIds() async {
    final prefs = await SharedPreferences.getInstance();
    _shownNotificationIds =
        prefs.getStringList('shown_notification_ids')?.map(int.parse).toSet() ??
            {};
  }

  Future<void> _saveShownIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'shown_notification_ids',
      _shownNotificationIds.map((id) => id.toString()).toList(),
    );
  }

  Future<void> _fetchNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/auth/notifications/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final notifications = json.decode(response.body) as List<dynamic>;

        final newUnread = notifications.where((n) =>
            n['is_read'] == false && !_shownNotificationIds.contains(n['id']));

        for (var notif in newUnread) {
          // schedule 5 repeats, 5s,10s,15s,20s,25s from now
          for (int i = 1; i <= 5; i++) {
            final fireTime = DateTime.now().add(Duration(seconds: 5 * i));
            await NotificationHelper.scheduleNotification(
              id: notif['id'] * 10 + i,
              title: "📬 New Notification",
              body: notif['message'],
              scheduledDate: fireTime,
            );
          }
          _shownNotificationIds.add(notif['id']);
        }

        await _saveShownIds();

        if (!mounted) return;
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("❌ Notification fetch error: $e");
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return;

    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/auth/notifications/read/$id/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      debugPrint("Failed to mark notification as read");
    }
  }

  String _formatDate(String dateTime) {
    try {
      final parsed = DateTime.parse(dateTime);
      return DateFormat('yyyy-MM-dd HH:mm').format(parsed);
    } catch (_) {
      return dateTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.cyan,
        elevation: 5,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Text(
                    "📭 No notifications available.",
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final id = notification['id'] as int;
                      final isExpanded = _expandedNotifications.contains(id);
                      final isRead = notification['is_read'] as bool;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isRead ? Colors.white : Colors.cyan[50],
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black12,
                                blurRadius: 5,
                                spreadRadius: 1),
                          ],
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Icon(
                                isRead
                                    ? Icons.notifications_none
                                    : Icons.notifications_active,
                                color: isRead ? Colors.grey : Colors.cyan,
                              ),
                              title: const Text(
                                'Yatra',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Text(
                                "📅 ${_formatDate(notification['created_at'])}",
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              trailing: Icon(
                                isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: Colors.grey,
                              ),
                              onTap: () async {
                                setState(() {
                                  if (isExpanded) {
                                    _expandedNotifications.remove(id);
                                  } else {
                                    _expandedNotifications.add(id);
                                  }
                                });
                                if (!isRead) {
                                  await _markAsRead(id);
                                  setState(() {
                                    notification['is_read'] = true;
                                  });
                                }
                              },
                            ),
                            if (isExpanded)
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  notification['message'],
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.black87),
                                  textAlign: TextAlign.justify,
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
