// ignore: file_names
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'home_page.dart';

class BookingPage extends StatefulWidget {
  final Vehicle vehicle;

  const BookingPage({super.key, required this.vehicle});

  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  bool _isBooking = false;
  DateTime? startDate, endDate;
  late DateTime now;
  late int maxDays;
  bool _isBooked = false;
  int rentalDays = 0;

  @override
  void initState() {
    super.initState();
    now = DateTime.now();
    maxDays = _getMaxDays();
  }

  int _getMaxDays() {
    final RegExp numberPattern = RegExp(r'\d+');
    final match = numberPattern.firstMatch(widget.vehicle.timePeriod);
    return match != null ? int.parse(match.group(0)!) : 0;
  }

  @override
  Widget build(BuildContext context) {
    double totalPrice =
        rentalDays * (double.tryParse(widget.vehicle.price) ?? 0.0);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan.shade800,
        elevation: 0,
        title: const Text("Booking Details",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00ACC1), Color(0xFF00838F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _vehicleImage(),
                _vehicleDetailsCard(totalPrice),
                const SizedBox(height: 25),
                if (_isBooked)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade700),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 24),
                        SizedBox(width: 8),
                        Text(
                          "Vehicle successfully booked!",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (!_isBooked) ...[
                  _selectDateButton(),
                  const SizedBox(height: 15),
                  Text("Total: NPR ${totalPrice.toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 10),
                  _isBooking
                      ? const CircularProgressIndicator(color: Colors.white)
                      : _confirmBookingButton(totalPrice),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vehicleImage() => Container(
        height: 200,
        width: double.infinity,
        margin: const EdgeInsets.only(top: 10, bottom: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(2, 4))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.network(widget.vehicle.vehicleImage, fit: BoxFit.cover),
        ),
      );

  Widget _vehicleDetailsCard(double totalPrice) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        color: Colors.white.withOpacity(0.95),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                  Icons.directions_car, "Model", widget.vehicle.model),
              _buildDetailRow(Icons.home, "Address", widget.vehicle.address),
              _buildDetailRow(Icons.attach_money, "Price",
                  "NPR ${widget.vehicle.price} per day"),
              _buildDetailRow(Icons.access_time, "Available Days",
                  "${widget.vehicle.timePeriod} days"),
              _buildDetailRow(
                  Icons.phone, "Phone Number", widget.vehicle.phoneNumber),
              const SizedBox(height: 10),
              const Text("Rental Period",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.cyan.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.cyan.shade200),
                ),
                child: Center(
                  child: Text(
                    startDate != null && endDate != null
                        ? "${DateFormat('MMM dd, yyyy').format(startDate!)} → ${DateFormat('MMM dd, yyyy').format(endDate!)}"
                        : "Select Rental Period",
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildDetailRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: Colors.cyan.shade700, size: 22),
            const SizedBox(width: 8),
            Text("$label: ",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
                softWrap: true,
              ),
            ),
          ],
        ),
      );

  Widget _selectDateButton() => ElevatedButton.icon(
        onPressed: _selectDateRange,
        icon: const Icon(Icons.calendar_today, size: 20),
        label: const Text("Select Dates",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyan.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 6,
        ),
      );

  Widget _confirmBookingButton(double totalPrice) => ElevatedButton.icon(
        onPressed: () => _bookVehicle(totalPrice),
        icon: const Icon(Icons.check, size: 20),
        label: const Text("Confirm Booking",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 6,
        ),
      );

  Future<void> _selectDateRange() async {
    DateTime maxAllowedEndDate = now.add(Duration(days: maxDays - 1));
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: maxAllowedEndDate,
    );
    if (picked != null) {
      final difference = picked.end.difference(picked.start).inDays + 1;
      if (difference > maxDays) {
        _showMessage(
            "❌ You can only book for up to $maxDays days.", Colors.red);
        return;
      }
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
        rentalDays = difference;
      });
    }
  }

  Future<void> _bookVehicle(double totalPrice) async {
    if (startDate == null || endDate == null) {
      _showMessage("❌ Please select rental dates!", Colors.red);
      return;
    }

    setState(() => _isBooking = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("access_token");

    if (token == null) {
      _showMessage("❌ Authentication Error! Please log in again.", Colors.red);
      setState(() => _isBooking = false);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("https://a.khalti.com/api/v2/epayment/initiate/"),
        headers: {
          "Authorization": "Key 76696163503e4c65bd22cc09a85af655",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "return_url": "http://127.0.0.1:8000/auth/payment/success/",
          "website_url": "http://127.0.0.1:8000/",
          "amount": (totalPrice * 100).round(),
          "purchase_order_id":
              "order_${widget.vehicle.id}_${DateTime.now().millisecondsSinceEpoch}",
          "purchase_order_name": "Vehicle Rental - ${widget.vehicle.model}",
          "customer_info": {
            "name": "Flutter User",
            "email": "user@example.com",
            "phone": "9800000000"
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final paymentUrl = data['payment_url'];
        final pidx = data['pidx'];

        if (await canLaunchUrl(Uri.parse(paymentUrl))) {
          await launchUrl(Uri.parse(paymentUrl),
              mode: LaunchMode.externalApplication);

          _showMessage(
              "🔁 Please return and tap Verify Payment", Colors.orange);

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              title: const Text("Thank you for your payment!"),
              content: const Text("We are always there to assist you."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () => _verifyKhaltiPayment(pidx),
                  child: const Text("Verify Payment"),
                )
              ],
            ),
          );
        } else {
          _showMessage("❌ Could not open payment page.", Colors.red);
        }
      } else {
        _showMessage("❌ Failed to initiate payment", Colors.red);
      }
    } catch (e) {
      print('❌ Exception: $e');
      _showMessage("❌ Error occurred during payment", Colors.red);
    } finally {
      setState(() => _isBooking = false);
    }
  }

  Future<void> _verifyKhaltiPayment(String pidx) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("access_token");

    if (token == null) {
      _showMessage("❌ Auth Error! Login again.", Colors.red);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("http://127.0.0.1:8000/auth/verify-khalti-epayment/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "pidx": pidx,
          "vehicle_id": widget.vehicle.id,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _showMessage(
            "✅ Payment Verified! Transaction ID: ${data['transaction_id']}",
            Colors.green);
        await _markVehicleUnavailable();
        setState(() {
          _isBooked = true;
        });
      } else {
        _showMessage("❌ ${data['error'] ?? 'Verification failed'}", Colors.red);
      }
    } catch (e) {
      print("🔴 Error verifying: $e");
      _showMessage("❌ Verification failed", Colors.red);
    }
  }

  Future<void> _markVehicleUnavailable() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("access_token");
    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse("http://127.0.0.1:8000/auth/mark-vehicle-unavailable/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"vehicle_id": widget.vehicle.id}),
      );

      if (response.statusCode != 200) {
        print("⚠️ Failed to mark unavailable: ${response.body}");
      }
    } catch (e) {
      print("❌ Error marking vehicle unavailable: $e");
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
