import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:front/View/home_page.dart';
import 'package:front/View/signup_page.dart';
import 'package:front/View/login_page.dart';
import 'package:front/helpers/notification_helper.dart'; // ✅ Import added

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  NotificationHelper.initialize(); // ✅ Notification init

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isDarkMode = prefs.getBool('isDarkMode') ?? false;

  runApp(MyApp(isDarkMode: isDarkMode));
}

class MyApp extends StatefulWidget {
  final bool isDarkMode;

  const MyApp({super.key, required this.isDarkMode});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _token;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('access_token');
    });
  }

  void _toggleDarkMode(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    setState(() {
      _isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Yatra',
      theme: ThemeData(
        primarySwatch: Colors.cyan,
        brightness: _isDarkMode ? Brightness.dark : Brightness.light,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('ne', 'NP'),
      ],
      home: _token != null
          ? HomePage(
              onThemeChanged: _toggleDarkMode,
              isDarkMode: _isDarkMode,
            )
          : SignupPage(
              onThemeChanged: _toggleDarkMode,
              isDarkMode: _isDarkMode,
            ),
      routes: {
        '/login': (context) =>
            LoginPage(onThemeChanged: _toggleDarkMode, isDarkMode: _isDarkMode),
        '/signup': (context) => SignupPage(
            onThemeChanged: _toggleDarkMode, isDarkMode: _isDarkMode),
        '/home': (context) =>
            HomePage(onThemeChanged: _toggleDarkMode, isDarkMode: _isDarkMode),
      },
    );
  }
}
