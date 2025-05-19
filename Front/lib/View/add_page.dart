// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_page.dart';
import 'settings_page.dart';

class AddPage extends StatefulWidget {
  final Function(Map<String, dynamic>) onVehicleAdded;

  const AddPage({Key? key, required this.onVehicleAdded}) : super(key: key);

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  String? selectedLocation;
  PlatformFile? vehicleImage, licenseImage;

  final TextEditingController modelController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  final List<String> predefinedLocations = [
    'Kathmandu',
    'Pokhara',
    'Chitwan',
    'Dharan',
    'Itahari',
    'Biratnagar',
  ];

  bool _isLoading = false;
  int _selectedIndex = 1;
  DateTime? startDate, endDate;

  Future<void> _pickFile(bool isVehicle) async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(withData: true);
    if (result != null) {
      setState(() {
        if (isVehicle) {
          vehicleImage = result.files.first;
        } else {
          licenseImage = result.files.first;
        }
      });
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
    }
  }

  Future<void> _submitForm() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');

    if (accessToken == null) {
      _showSnackbar('You must log in first!', Colors.redAccent);
      return;
    }

    if (modelController.text.isEmpty ||
        selectedLocation == null ||
        addressController.text.isEmpty ||
        priceController.text.isEmpty ||
        startDate == null ||
        endDate == null ||
        contactController.text.isEmpty ||
        vehicleImage == null ||
        licenseImage == null ||
        vehicleImage?.bytes == null ||
        licenseImage?.bytes == null) {
      _showSnackbar('All fields are required!', Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);

    try {
      String formattedTimePeriod =
          "${DateFormat('yyyy-MM-dd').format(startDate!)} to ${DateFormat('yyyy-MM-dd').format(endDate!)}";

      print(
          "Vehicle: ${vehicleImage?.name}, ${vehicleImage?.bytes?.length} bytes");
      print(
          "License: ${licenseImage?.name}, ${licenseImage?.bytes?.length} bytes");

      FormData formData = FormData.fromMap({
        'model': modelController.text.trim(),
        'location': selectedLocation!,
        'address': addressController.text.trim(),
        'price': priceController.text.trim(),
        'time_period': formattedTimePeriod,
        'phone_number': contactController.text.trim(),
        'vehicle_image': MultipartFile.fromBytes(
          vehicleImage!.bytes!,
          filename: vehicleImage!.name,
        ),
        'license_document': MultipartFile.fromBytes(
          licenseImage!.bytes!,
          filename: licenseImage!.name,
        ),
      });

      var response = await Dio().post(
        'http://192.168.42.151:8000/auth/add-vehicle/',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 201) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Submission Received'),
            content: const Text(
              'Your vehicle listing has been submitted for review. It will be visible after admin approval.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        _showSnackbar(
            'Failed to add vehicle: ${response.data}', Colors.redAccent);
      }
    } catch (e) {
      _showSnackbar('Error: ${e.toString()}', Colors.redAccent);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [Color(0xFF00BCD4), Color(0xFF00838F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 50),
                const Text(
                  "Add a Vehicle 🚗",
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 15),
                _buildTextField(
                    'Vehicle Model', modelController, Icons.directions_car),
                _buildDropdownField(
                    'Location',
                    selectedLocation,
                    predefinedLocations,
                    (value) => setState(() => selectedLocation = value)),
                _buildTextField('Address', addressController, Icons.home),
                _buildTextField(
                    'Rental Price', priceController, Icons.currency_rupee),
                _buildDateRangePicker(),
                _buildTextField('Phone Number', contactController, Icons.phone),
                _buildUploadSection('Upload Vehicle Image', Icons.camera_alt,
                    vehicleImage?.name, () => _pickFile(true)),
                _buildUploadSection(
                    'Upload License Document',
                    Icons.file_upload,
                    licenseImage?.name,
                    () => _pickFile(false)),
                const SizedBox(height: 20),
                Center(
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.cyan,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _submitForm,
                          child: const Text('Submit Vehicle',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.cyan,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(
                  onThemeChanged: (bool isDark) {},
                  isDarkMode: Theme.of(context).brightness == Brightness.dark,
                ),
              ),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => SettingsPage(
                  onThemeChanged: (bool value) {},
                ),
              ),
            );
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

  Widget _buildDropdownField(String label, String? value, List<String> items,
      ValueChanged<String?> onChanged) {
    return _buildCard(
      DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.location_on, color: Colors.cyan),
          border: InputBorder.none,
        ),
        value: value,
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon) {
    return _buildCard(
      TextField(
        controller: controller,
        decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: Colors.cyan),
            border: InputBorder.none),
      ),
    );
  }

  Widget _buildUploadSection(
      String label, IconData icon, String? fileName, VoidCallback onPressed) {
    return _buildCard(
      ListTile(
        title: Text(label),
        subtitle: Text(fileName ?? 'No file selected'),
        trailing: IconButton(
            icon: Icon(icon, color: Colors.cyan), onPressed: onPressed),
      ),
    );
  }

  Widget _buildDateRangePicker() {
    return GestureDetector(
      onTap: () => _selectDateRange(context),
      child: _buildCard(
        ListTile(
          leading: const Icon(Icons.date_range, color: Colors.cyan),
          title: Text(
            startDate != null && endDate != null
                ? "${DateFormat('yyyy-MM-dd').format(startDate!)} → ${DateFormat('yyyy-MM-dd').format(endDate!)}"
                : "Select Date Range",
            style: const TextStyle(fontSize: 16),
          ),
          subtitle: startDate != null && endDate != null
              ? Text(
                  "Available for ${endDate!.difference(startDate!).inDays} days",
                  style: const TextStyle(color: Colors.black54),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildCard(Widget child) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12), child: child),
    );
  }
}
