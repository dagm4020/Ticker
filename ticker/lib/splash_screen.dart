import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    print('SplashScreen: initState called');
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    print('SplashScreen: Waiting for 3 seconds...');
    await Future.delayed(Duration(seconds: 3));

    User? user = _auth.currentUser;
    print(
        'SplashScreen: User is ${user == null ? 'not logged in' : 'logged in'}');

    Navigator.pushReplacementNamed(context, '/auth_wrapper');
  }

  @override
  Widget build(BuildContext context) {
    print('SplashScreen: build called');
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.deepPurple.shade900],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
        ),
        child: Center(
          child: Image.asset(
            'src/logo.png',
            width: 150,
            height: 150,
          ),
        ),
      ),
    );
  }
}
