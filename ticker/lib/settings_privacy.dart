import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsPrivacy extends StatefulWidget {
  @override
  _SettingsPrivacyState createState() => _SettingsPrivacyState();
}

class _SettingsPrivacyState extends State<SettingsPrivacy> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isDeleting = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    if (_currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
    }
  }

  Future<void> _deleteWatchlist() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User not logged in. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      CollectionReference watchlistRef = _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('watchlist');

      QuerySnapshot watchlistSnapshot = await watchlistRef.get();

      if (watchlistSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Your watchlist is already empty.'),
            backgroundColor: Colors.blue,
          ),
        );
        return;
      }

      WriteBatch batch = _firestore.batch();
      for (var doc in watchlistSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All watchlist data has been deleted successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error deleting watchlist: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete watchlist. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAccountAndData() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User not logged in. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await _deleteWatchlist();

      await _firestore.collection('users').doc(_currentUser!.uid).delete();

      await _currentUser!.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Your account and all data have been deleted successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacementNamed(context, '/login');
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred. Please try again.';
      if (e.code == 'requires-recent-login') {
        errorMessage = 'Please log in again to delete your account.';
        bool reauthenticated = await _reauthenticate();
        if (reauthenticated) {
          await _deleteAccountAndData();
        }
        return;
      } else if (e.code == 'user-token-expired') {
        errorMessage = 'Your session has expired. Please log in again.';
        Navigator.pushReplacementNamed(context, '/login');
        return;
      } else {
        errorMessage = e.message ?? errorMessage;
      }

      print('FirebaseAuthException: ${e.code} - ${e.message}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      print('Error deleting account and data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete account and data. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isDeleting = false;
      });
    }
  }

  Future<void> _showConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Colors.deepPurple.shade900],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delete Account and Data',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Are you sure you want to delete your account and all associated data? This action cannot be undone.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: _isDeleting
                          ? null
                          : () {
                              Navigator.of(context).pop();
                            },
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    SizedBox(width: 24),
                    GestureDetector(
                      onTap: _isDeleting
                          ? null
                          : () async {
                              Navigator.of(context).pop();
                              await _deleteAccountAndData();
                            },
                      child: Text(
                        'Delete Account and Data',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAccountInfoDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Colors.deepPurple.shade900],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Deletion',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Deleting your account will remove all your account information from our servers. This includes your email, password, and any other personal data associated with your account.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Close',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _reauthenticate() async {
    final TextEditingController _passwordController = TextEditingController();
    bool _isReauthenticating = false;
    bool _isSuccessful = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Colors.deepPurple.shade900],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Re-authenticate',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Please enter your current password to proceed.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock, color: Colors.white),
                  ),
                  obscureText: true,
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: _isReauthenticating
                          ? null
                          : () {
                              Navigator.of(context).pop();
                            },
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    SizedBox(width: 24),
                    GestureDetector(
                      onTap: _isReauthenticating
                          ? null
                          : () async {
                              setState(() {
                                _isReauthenticating = true;
                              });

                              try {
                                if (_currentUser == null ||
                                    _currentUser!.email == null) {
                                  throw FirebaseAuthException(
                                      code: 'no-email',
                                      message: 'No email found for this user.');
                                }

                                AuthCredential credential =
                                    EmailAuthProvider.credential(
                                  email: _currentUser!.email!,
                                  password: _passwordController.text.trim(),
                                );

                                await _currentUser!
                                    .reauthenticateWithCredential(credential);
                                _isSuccessful = true;
                                Navigator.of(context).pop();
                              } on FirebaseAuthException catch (e) {
                                String errorMessage =
                                    'Re-authentication failed.';
                                if (e.code == 'wrong-password') {
                                  errorMessage = 'Incorrect password.';
                                } else if (e.code == 'user-mismatch') {
                                  errorMessage =
                                      'User mismatch. Please try again.';
                                } else if (e.code == 'user-not-found') {
                                  errorMessage = 'User not found.';
                                } else if (e.code == 'invalid-credential') {
                                  errorMessage = 'Invalid credentials.';
                                } else if (e.code == 'no-email') {
                                  errorMessage = e.message ?? errorMessage;
                                }

                                print(
                                    'FirebaseAuthException during re-authenticate: ${e.code} - ${e.message}');

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(errorMessage),
                                    backgroundColor: Colors.red,
                                  ),
                                );

                                setState(() {
                                  _isReauthenticating = false;
                                });
                              } catch (e) {
                                print('Re-authentication error: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'An error occurred. Please try again.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );

                                setState(() {
                                  _isReauthenticating = false;
                                });
                              }
                            },
                      child: _isReauthenticating
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Confirm',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return _isSuccessful;
  }

  final TextStyle buttonTextStyle = TextStyle(
    color: Colors.redAccent,
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Privacy',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.deepPurple.shade800,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.deepPurple,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Privacy',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple.shade800,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.deepPurple.shade900],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We value your privacy and are committed to protecting your personal information. This page allows you to delete all your in-app data, including your account. Please note that this action cannot be undone.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\u2022',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Watchlist',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\u2022',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          'Account',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            _showAccountInfoDialog();
                          },
                          child: Icon(
                            Icons.info_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Spacer(),
              Center(
                child: GestureDetector(
                  onTap: _isDeleting ? null : _showConfirmationDialog,
                  child: Text(
                    _isDeleting ? 'Deleting...' : 'Delete Account and Data',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
