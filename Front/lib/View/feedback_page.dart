import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FeedbackPage extends StatefulWidget {
  final int vehicleId;

  const FeedbackPage({Key? key, required this.vehicleId}) : super(key: key);

  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  List<dynamic> _feedbackList = [];
  final TextEditingController _commentController = TextEditingController();
  int _rating = 5; // Default rating

  @override
  void initState() {
    super.initState();
    _fetchFeedback();
  }

  Future<void> _fetchFeedback() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://127.0.0.1:8000/auth/feedback/list/${widget.vehicleId}/'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _feedbackList = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load feedback');
      }
    } catch (error) {
      print('Error fetching feedback: $error');
    }
  }

  Future<void> _submitFeedback() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    if (token == null) {
      print('User is not logged in');
      return;
    }

    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/auth/feedback/add/${widget.vehicleId}/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'comment': _commentController.text,
        'rating': _rating,
      }),
    );

    if (response.statusCode == 201) {
      _commentController.clear();
      _rating = 5; // Reset rating
      _fetchFeedback(); // Refresh feedback list
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback submitted successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit feedback')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Feedback"),
        backgroundColor: Colors.cyan,
      ),
      body: Column(
        children: [
          Expanded(
            child: _feedbackList.isEmpty
                ? const Center(
                    child: Text(
                      "No feedback available.",
                      style: TextStyle(fontSize: 18, color: Colors.black54),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _feedbackList.length,
                    itemBuilder: (context, index) {
                      final feedback = _feedbackList[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(feedback['user'][0].toUpperCase()),
                          ),
                          title: Text(
                            feedback['user'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(feedback['comment']),
                              const SizedBox(height: 4),
                              Row(
                                children: List.generate(5, (i) {
                                  return Icon(
                                    i < feedback['rating']
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 18,
                                    color: Colors.amber,
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 2, color: Colors.grey),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Leave Feedback:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Write your feedback...",
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text("Rating: "),
                    Row(
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < _rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                          ),
                          onPressed: () {
                            setState(() {
                              _rating = index + 1;
                            });
                          },
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Center(
                    child: Text("Submit Feedback"),
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
