import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

class VehicleEditPage extends StatefulWidget {
  final dynamic vehicle;
  const VehicleEditPage({Key? key, required this.vehicle}) : super(key: key);

  @override
  State<VehicleEditPage> createState() => _VehicleEditPageState();
}

class _VehicleEditPageState extends State<VehicleEditPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _model;
  late TextEditingController _location;
  late TextEditingController _address;
  late TextEditingController _phone;
  late TextEditingController _price;
  late TextEditingController _timePeriod;

  File? _vehicleImage;
  File? _licenseDocument;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _model = TextEditingController(text: widget.vehicle['model']);
    _location = TextEditingController(text: widget.vehicle['location']);
    _address = TextEditingController(text: widget.vehicle['address']);
    _phone = TextEditingController(text: widget.vehicle['phone_number']);
    _price = TextEditingController(text: widget.vehicle['price'].toString());
    _timePeriod = TextEditingController(text: widget.vehicle['time_period']);
  }

  Future<void> _pickImage(bool isVehicleImage) async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (isVehicleImage) {
          _vehicleImage = File(picked.path);
        } else {
          _licenseDocument = File(picked.path);
        }
      });
    }
  }

  Future<void> _updateVehicle() async {
    setState(() => _isSaving = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    final request = http.MultipartRequest(
      'PUT',
      Uri.parse(
          'http://127.0.0.1:8000/auth/update-vehicle/${widget.vehicle['id']}/'),
    );

    request.headers['Authorization'] = 'Bearer $token';

    request.fields['model'] = _model.text;
    request.fields['location'] = _location.text;
    request.fields['address'] = _address.text;
    request.fields['phone_number'] = _phone.text;
    request.fields['price'] = _price.text;
    request.fields['time_period'] = _timePeriod.text;

    if (_vehicleImage != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'vehicle_image',
        _vehicleImage!.path,
        filename: path.basename(_vehicleImage!.path),
      ));
    }

    if (_licenseDocument != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'license_document',
        _licenseDocument!.path,
        filename: path.basename(_licenseDocument!.path),
      ));
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Vehicle updated successfully!")),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Update failed: ${response.statusCode}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Connection error: $e")),
      );
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Vehicle"),
        backgroundColor: Colors.teal.shade400,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextField(
                      controller: _model,
                      decoration: _inputDecoration("Model")),
                  const SizedBox(height: 12),
                  TextField(
                      controller: _location,
                      decoration: _inputDecoration("Location")),
                  const SizedBox(height: 12),
                  TextField(
                      controller: _address,
                      decoration: _inputDecoration("Address")),
                  const SizedBox(height: 12),
                  TextField(
                      controller: _phone,
                      decoration: _inputDecoration("Phone Number")),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _price,
                    decoration: _inputDecoration("Price"),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                      controller: _timePeriod,
                      decoration: _inputDecoration("Time Period")),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(true),
                    icon: const Icon(Icons.image),
                    label: const Text("Pick Vehicle Image"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent),
                  ),
                  if (_vehicleImage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text("📸 ${path.basename(_vehicleImage!.path)}"),
                    ),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(false),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("Pick License Document"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange),
                  ),
                  if (_licenseDocument != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child:
                          Text("📄 ${path.basename(_licenseDocument!.path)}"),
                    ),
                  const SizedBox(height: 24),
                  _isSaving
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text("Update Vehicle"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          onPressed: _updateVehicle,
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
