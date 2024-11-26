import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'splash_screen.dart';
import 'login_page.dart';
import 'registration_page.dart';
import 'home_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Directory current = Directory.current;
  print("Current Directory: ${current.path}");

  try {
    await dotenv.load(fileName: ".env");
    print("✅ .env file loaded successfully.");
  } catch (e) {
    print("❌ Failed to load .env file: $e");
  }

  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stock Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginPage(),
        '/register': (context) => RegistrationPage(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}
