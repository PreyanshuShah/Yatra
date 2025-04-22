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
    'Dharan'
  ];

  bool _isLoading = false;
  int _selectedIndex = 1;
  DateTime? startDate, endDate;

  // File Picker function to pick files (vehicle and license images)
  Future<void> _pickFile(bool isVehicle) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        isVehicle
            ? vehicleImage = result.files.first
            : licenseImage = result.files.first;
      });
    }
  }

  // Date Range Picker for selecting rental period
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

  // Form submission function
  Future<void> _submitForm() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');

    // Check if the user is logged in
    if (accessToken == null) {
      _showSnackbar('You must log in first!', Colors.redAccent);
      return;
    }

    // Validate all required fields
    if (modelController.text.isEmpty ||
        selectedLocation == null ||
        addressController.text.isEmpty ||
        priceController.text.isEmpty ||
        startDate == null ||
        endDate == null ||
        contactController.text.isEmpty ||
        vehicleImage == null || // Check for vehicle image
        licenseImage == null) {
      // Check for license image
      _showSnackbar('All fields are required!', Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Ensure `startDate` and `endDate` are always valid
      startDate ??= DateTime.now(); // Default to current date if null
      endDate ??= DateTime.now(); // Default to current date if null

      // Ensure selectedLocation is never null
      selectedLocation ??= 'Kathmandu'; // Default to 'Kathmandu' if null

      String formattedTimePeriod =
          "${DateFormat('yyyy-MM-dd').format(startDate!)} to ${DateFormat('yyyy-MM-dd').format(endDate!)}";

      FormData formData = FormData.fromMap({
        'model': modelController.text.trim(),
        'location':
            selectedLocation!, // Force unwrap because we set a default value
        'address': addressController.text.trim(),
        'price': priceController.text.trim(),
        'time_period': formattedTimePeriod,
        'phone_number': contactController.text.trim(),
        // Handle vehicle image and license image null checks
        'vehicle_image': vehicleImage != null
            ? MultipartFile.fromBytes(vehicleImage!.bytes!,
                filename: vehicleImage!.name)
            : null,
        'license_document': licenseImage != null
            ? MultipartFile.fromBytes(licenseImage!.bytes!,
                filename: licenseImage!.name)
            : null,
      });

      var response = await Dio().post(
        'http://127.0.0.1:8000/auth/add-vehicle/',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      // Handle the response
      if (response.statusCode == 201) {
        _showSnackbar('Vehicle Added Successfully!', Colors.green);
        Navigator.pop(context);
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

  // Function to show a Snackbar message
  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  // Build the UI for the Add Vehicle page
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
                _buildTextField('Rental Price', priceController, Icons.money),
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

  // Dropdown for location
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

  // Text fields for user input
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

  // Upload section for images and documents
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

  // Date range picker for start and end date
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

  // Helper method to wrap widgets in a Card
  Widget _buildCard(Widget child) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12), child: child),
    );
  }
}
