import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:workmanager/workmanager.dart';
import 'settings_accounts.dart';
import 'settings_notifications.dart';
import 'settings_data.dart';
import 'settings_privacy.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoggingOut = false;

  void _logout() async {
    setState(() {
      _isLoggingOut = true;
    });
    print('🔒 Logout started. Showing "Logging out..."');

    try {
      await Future.delayed(Duration(milliseconds: 1500));
      print('⏱️ Delay completed. Proceeding to sign out.');

      await Workmanager().cancelAll();
      print('🗑️ All scheduled notifications canceled.');

      await _auth.signOut();
      print('🔓 User signed out.');
    } catch (e) {
      print('Error during logout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred during logout. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoggingOut = false;
      });
      print('🔒 Logout process completed. _isLoggingOut set to false.');
    }
  }

  void _navigateToPage(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black, Colors.deepPurple.shade900],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.account_circle, color: Colors.white),
              title: Text(
                'Accounts',
                style: TextStyle(color: Colors.white),
              ),
              trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
              onTap: () => _navigateToPage(SettingsAccounts()),
            ),
            Divider(color: Colors.white54),
            ListTile(
              leading: Icon(Icons.notifications, color: Colors.white),
              title: Text(
                'Notifications',
                style: TextStyle(color: Colors.white),
              ),
              trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
              onTap: () => _navigateToPage(SettingsNotifications()),
            ),
            Divider(color: Colors.white54),
            ListTile(
              leading: Icon(Icons.data_usage, color: Colors.white),
              title: Text(
                'Data',
                style: TextStyle(color: Colors.white),
              ),
              trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
              onTap: () => _navigateToPage(SettingsData()),
            ),
            Divider(color: Colors.white54),
            ListTile(
              leading: Icon(Icons.lock, color: Colors.white),
              title: Text(
                'Privacy',
                style: TextStyle(color: Colors.white),
              ),
              trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
              onTap: () => _navigateToPage(SettingsPrivacy()),
            ),
            Spacer(),
            GestureDetector(
              onTap: _isLoggingOut ? null : _logout,
              child: Text(
                _isLoggingOut ? 'Logging out...' : 'Logout',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
