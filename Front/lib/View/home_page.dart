import 'package:flutter/material.dart';
import 'package:front/View/BookingPage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'feedback_page.dart';
import 'add_page.dart';
import 'settings_page.dart';

class Vehicle {
  final int id;
  final String model;
  final String location;
  final String address;
  final String phoneNumber;
  final String price;
  final String timePeriod;
  final String vehicleImage;
  final int ownerId; // ✅ Add this

  Vehicle({
    required this.id,
    required this.model,
    required this.location,
    required this.address,
    required this.phoneNumber,
    required this.price,
    required this.timePeriod,
    required this.vehicleImage,
    required this.ownerId,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      model: json['model'],
      location: json['location'],
      address: json['address'],
      phoneNumber: json['phone_number'],
      price: json['price'],
      timePeriod: json['time_period'],
      vehicleImage: json['vehicle_image'],
      ownerId: json['owner_id'],
    );
  }
}

class HomePage extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool isDarkMode;

  const HomePage(
      {super.key, required this.onThemeChanged, required this.isDarkMode});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<Vehicle> _vehicles = [];
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 0;
  String _username = "";
  String? _selectedTimePeriod;
  String? _selectedLocation;
  double? _minPrice;
  double? _maxPrice;

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _fetchVehicles();
    Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchVehicles();
    });
  }

  void _openFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("\u{1F50D} Filter Vehicles",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "\u{1F4CD} Location",
                  border: OutlineInputBorder(),
                ),
                items: _vehicles
                    .map((v) => v.location)
                    .toSet()
                    .map(
                        (loc) => DropdownMenuItem(value: loc, child: Text(loc)))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedLocation = value);
                },
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                          labelText: "\u{1F4B0} Min Price",
                          border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      onChanged: (value) =>
                          setState(() => _minPrice = double.tryParse(value)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                          labelText: "\u{1F4B0} Max Price",
                          border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      onChanged: (value) =>
                          setState(() => _maxPrice = double.tryParse(value)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                    labelText: "\u{23F3} Select Time Period",
                    border: OutlineInputBorder()),
                items: _vehicles
                    .map((v) => v.timePeriod)
                    .toSet()
                    .map((period) => DropdownMenuItem(
                        value: period, child: Text("$period days")))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedTimePeriod = value),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text("\u{2705} Apply Filters",
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() => _username = prefs.getString('username') ?? "User");
  }

  Future<void> _fetchVehicles() async {
    try {
      final response = await http
          .get(Uri.parse('http://127.0.0.1:8000/auth/list-vehicles/'));
      if (response.statusCode == 200) {
        final List<dynamic> vehicleList = json.decode(response.body);
        setState(() {
          _vehicles =
              vehicleList.map((data) => Vehicle.fromJson(data)).toList();
        });
      } else {
        throw Exception('Failed to load vehicles');
      }
    } catch (error) {
      print('Error fetching vehicles: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Vehicle> filteredVehicles = _vehicles.where((vehicle) {
      bool matchesSearch =
          vehicle.model.toLowerCase().contains(_searchQuery.toLowerCase());
      bool matchesLocation =
          _selectedLocation == null || vehicle.location == _selectedLocation;
      bool matchesPrice =
          (_minPrice == null || double.parse(vehicle.price) >= _minPrice!) &&
              (_maxPrice == null || double.parse(vehicle.price) <= _maxPrice!);
      bool matchesTimePeriod = _selectedTimePeriod == null ||
          vehicle.timePeriod == _selectedTimePeriod;
      return matchesSearch &&
          matchesLocation &&
          matchesPrice &&
          matchesTimePeriod;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.cyan[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Yatra - Rent a Vehicle",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 1.2)),
        backgroundColor: Colors.cyan,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 4,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text("Welcome, $_username 👋",
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: ' Search for a vehicle',
                    prefixIcon: const Icon(Icons.search, color: Colors.cyan),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _openFilterBottomSheet,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 3,
                    padding: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50))),
                child: const Icon(Icons.filter_list, color: Colors.cyan),
              ),
            ]),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchVehicles,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 15,
                      crossAxisSpacing: 15,
                      childAspectRatio: 0.49,
                    ),
                    itemCount: filteredVehicles.length,
                    itemBuilder: (context, index) {
                      final vehicle = filteredVehicles[index];
                      return _buildVehicleCard(vehicle);
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.cyan,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (index) async {
          setState(() => _selectedIndex = index);
          if (index == 1) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddPage(
                  onVehicleAdded: (vehicle) => _fetchVehicles(),
                ),
              ),
            );
            if (result == true) _fetchVehicles();
          } else if (index == 2) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        SettingsPage(onThemeChanged: (bool value) {})));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    return SizedBox(
      height: 300,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: () => showDialog(
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
                      child: Image.network(vehicle.vehicleImage,
                          fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15)),
                child: SizedBox(
                  height: 100,
                  child: Image.network(vehicle.vehicleImage,
                      fit: BoxFit.cover, width: double.infinity),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(Icons.directions_car, vehicle.model),
                    _buildDetailRow(Icons.location_on, vehicle.location),
                    _buildDetailRow(Icons.home, vehicle.address),
                    _buildDetailRow(Icons.attach_money, vehicle.price),
                    _buildDetailRow(
                        Icons.access_time,
                        vehicle.timePeriod.contains("to")
                            ? "Duration: ${vehicle.timePeriod}"
                            : "${vehicle.timePeriod} days"),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    FeedbackPage(vehicleId: vehicle.id))),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyan),
                        child: const Text("Give Feedback",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    BookingPage(vehicle: vehicle)),
                          );
                          if (result == true) _fetchVehicles();
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green),
                        child: const Text("Book Now",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.cyan),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }
}
