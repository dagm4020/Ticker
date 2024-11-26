import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

    await Future.delayed(Duration(milliseconds: 1500));

    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _navigateToSubPage(String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubSettingsPage(title: title),
      ),
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
              onTap: () => _navigateToSubPage('Accounts'),
            ),
            Divider(color: Colors.white54),
            ListTile(
              leading: Icon(Icons.notifications, color: Colors.white),
              title: Text(
                'Notifications',
                style: TextStyle(color: Colors.white),
              ),
              trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
              onTap: () => _navigateToSubPage('Notifications'),
            ),
            Divider(color: Colors.white54),
            ListTile(
              leading: Icon(Icons.data_usage, color: Colors.white),
              title: Text(
                'Data',
                style: TextStyle(color: Colors.white),
              ),
              trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
              onTap: () => _navigateToSubPage('Data'),
            ),
            Divider(color: Colors.white54),
            ListTile(
              leading: Icon(Icons.lock, color: Colors.white),
              title: Text(
                'Privacy',
                style: TextStyle(color: Colors.white),
              ),
              trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
              onTap: () => _navigateToSubPage('Privacy'),
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

class SubSettingsPage extends StatelessWidget {
  final String title;

  SubSettingsPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple.shade800,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.deepPurple.shade900],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
        ),
        child: Center(
          child: Text(
            '$title Page',
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
