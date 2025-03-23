import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class VerifyPaymentPage extends StatefulWidget {
  final String pidx;
  final int vehicleId;

  const VerifyPaymentPage(
      {super.key, required this.pidx, required this.vehicleId});

  @override
  State<VerifyPaymentPage> createState() => _VerifyPaymentPageState();
}

class _VerifyPaymentPageState extends State<VerifyPaymentPage> {
  bool isVerifying = false;

  Future<void> verifyPayment() async {
    setState(() => isVerifying = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("access_token");

    if (token == null) {
      _showSnack("❌ Login required", Colors.red);
      setState(() => isVerifying = false);
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
          "pidx": widget.pidx,
          "vehicle_id": widget.vehicleId,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _showSnack("✅ Payment Verified Successfully", Colors.green);
        Navigator.pop(context); // return to previous screen
      } else {
        _showSnack("❌ ${data['error'] ?? 'Verification failed'}", Colors.red);
      }
    } catch (e) {
      _showSnack("❌ Exception: $e", Colors.red);
    } finally {
      setState(() => isVerifying = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify Payment"),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: isVerifying
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
                onPressed: verifyPayment,
                icon: const Icon(Icons.verified),
                label: const Text("Verify Payment"),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
      ),
    );
  }
}
