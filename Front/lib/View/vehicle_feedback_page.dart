import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class VehicleFeedbackPage extends StatefulWidget {
  const VehicleFeedbackPage({Key? key}) : super(key: key);

  @override
  _VehicleFeedbackPageState createState() => _VehicleFeedbackPageState();
}

class _VehicleFeedbackPageState extends State<VehicleFeedbackPage> {
  List<dynamic> _vehicles = [];

  @override
  void initState() {
    super.initState();
    _fetchUserVehicles();
  }

  Future<void> _fetchUserVehicles() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    final response = await http.get(
      Uri.parse('http://127.0.0.1:8000/auth/user-vehicles/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        _vehicles = json.decode(response.body);
      });
    } else {
      print('Failed to load vehicles');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.cyan[50],
      appBar: AppBar(
        title: const Text("My Vehicles & Feedbacks"),
        backgroundColor: Colors.cyan,
      ),
      body: _vehicles.isEmpty
          ? const Center(child: Text("No vehicles available."))
          : ListView.builder(
              itemCount: _vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = _vehicles[index];
                return _buildVehicleCard(vehicle);
              },
            ),
    );
  }

  Widget _buildVehicleCard(dynamic vehicle) {
    List<dynamic> feedbacks = vehicle['feedbacks'] ?? [];

    return Card(
      margin: const EdgeInsets.all(10),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Vehicle Details with tappable image
            Row(
              children: [
                if (vehicle['vehicle_image'] != null)
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: InteractiveViewer(
                            panEnabled: true,
                            minScale: 0.5,
                            maxScale: 4,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                vehicle['vehicle_image'],
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        vehicle['vehicle_image'],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                const SizedBox(width: 10),
                // ✅ Vehicle Text Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle['model'],
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text("Location: ${vehicle['location']}"),
                      Text("Price: \$${vehicle['price']}"),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // ✅ Feedbacks Section
            feedbacks.isEmpty
                ? const Text(
                    "No feedbacks yet.",
                    style: TextStyle(color: Colors.grey),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: feedbacks.map((feedback) {
                      return ListTile(
                        leading: const Icon(Icons.comment, color: Colors.blue),
                        title: Text(feedback['comment']),
                        subtitle: Text("Rating: ${feedback['rating']} ⭐"),
                        trailing: Text(feedback['user']),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }
}
