import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsAccounts extends StatefulWidget {
  @override
  _SettingsAccountsState createState() => _SettingsAccountsState();
}

class _SettingsAccountsState extends State<SettingsAccounts> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  User? _currentUser;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserData();
  }

  Future<void> _fetchCurrentUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _currentUser = _auth.currentUser;
      if (_currentUser == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(_currentUser!.uid).get();

      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data() as Map<String, dynamic>;
        });
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print('Error fetching user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load user data. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showEditDialog(String field, String currentValue) async {
    final TextEditingController _controller =
        TextEditingController(text: currentValue);
    final _formKey = GlobalKey<FormState>();
    bool _isSubmitting = false;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $field'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: field,
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '$field cannot be empty.';
              }
              if (field == 'Username' && value.trim().length < 3) {
                return 'Username must be at least 3 characters long.';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting
                ? null
                : () {
                    Navigator.pop(context);
                  },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() {
                        _isSubmitting = true;
                      });

                      String newValue = _controller.text.trim();

                      if (field == 'Username') {
                        QuerySnapshot usernameQuery = await _firestore
                            .collection('users')
                            .where('username', isEqualTo: newValue)
                            .get();

                        if (usernameQuery.docs.isNotEmpty &&
                            usernameQuery.docs.first.id != _currentUser!.uid) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Username already taken. Please choose another one.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          setState(() {
                            _isSubmitting = false;
                          });
                          return;
                        }
                      }

                      User? user = _auth.currentUser;
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'User not logged in. Please log in again.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        setState(() {
                          _isSubmitting = false;
                        });
                        Navigator.pop(context);
                        return;
                      }

                      try {
                        await _firestore
                            .collection('users')
                            .doc(user.uid)
                            .update({
                          field.toLowerCase().replaceAll(' ', '_'): newValue
                        });

                        await _fetchCurrentUserData();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$field updated successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );

                        Navigator.pop(context);
                      } catch (e) {
                        print('Error updating $field: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Failed to update $field. Please try again.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } finally {
                        setState(() {
                          _isSubmitting = false;
                        });
                      }
                    }
                  },
            child: _isSubmitting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showUpdateEmailDialog() async {
    final TextEditingController _emailController =
        TextEditingController(text: _userData?['email'] ?? '');
    final _formKey = GlobalKey<FormState>();
    bool _isSubmitting = false;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Email'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'New Email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email cannot be empty.';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                return 'Please enter a valid email address.';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting
                ? null
                : () {
                    Navigator.pop(context);
                  },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() {
                        _isSubmitting = true;
                      });

                      String newEmail = _emailController.text.trim();

                      try {
                        await _currentUser!.updateEmail(newEmail);
                        await _firestore
                            .collection('users')
                            .doc(_currentUser!.uid)
                            .update({'email': newEmail});

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Email updated successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );

                        await _fetchCurrentUserData();

                        Navigator.pop(context);
                      } on FirebaseAuthException catch (e) {
                        String errorMessage =
                            'An error occurred. Please try again.';
                        if (e.code == 'invalid-email') {
                          errorMessage = 'The email address is not valid.';
                        } else if (e.code == 'email-already-in-use') {
                          errorMessage = 'This email is already in use.';
                        } else if (e.code == 'requires-recent-login') {
                          errorMessage =
                              'Please log in again to update your email.';
                          bool reauthenticated = await _reauthenticate();
                          if (reauthenticated) {
                            Navigator.pop(context);
                            _showUpdateEmailDialog();
                          }
                          return;
                        } else {
                          errorMessage = e.message ?? errorMessage;
                        }

                        print(
                            'FirebaseAuthException: ${e.code} - ${e.message}');

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(errorMessage),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } catch (e) {
                        print('Error updating email: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Failed to update email. Please try again.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } finally {
                        setState(() {
                          _isSubmitting = false;
                        });
                      }
                    }
                  },
            child: _isSubmitting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showUpdatePasswordDialog() async {
    final TextEditingController _passwordController = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    bool _isSubmitting = false;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Password'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'New Password',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Password cannot be empty.';
              }
              if (value.trim().length < 6) {
                return 'Password must be at least 6 characters long.';
              }
              if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{6,}$')
                  .hasMatch(value)) {
                return 'Password must include both letters and numbers.';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting
                ? null
                : () {
                    Navigator.pop(context);
                  },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() {
                        _isSubmitting = true;
                      });

                      String newPassword = _passwordController.text.trim();

                      try {
                        await _currentUser!.updatePassword(newPassword);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Password updated successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );

                        Navigator.pop(context);
                      } on FirebaseAuthException catch (e) {
                        String errorMessage =
                            'An error occurred. Please try again.';
                        if (e.code == 'weak-password') {
                          errorMessage =
                              'The password is too weak. Please use at least 6 characters, including letters and numbers.';
                        } else if (e.code == 'requires-recent-login') {
                          errorMessage =
                              'Please log in again to update your password.';
                          bool reauthenticated = await _reauthenticate();
                          if (reauthenticated) {
                            Navigator.pop(context);
                            _showUpdatePasswordDialog();
                          }
                          return;
                        } else {
                          errorMessage = e.message ?? errorMessage;
                        }

                        print(
                            'FirebaseAuthException: ${e.code} - ${e.message}');

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(errorMessage),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } catch (e) {
                        print('Error updating password: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Failed to update password. Please try again.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } finally {
                        setState(() {
                          _isSubmitting = false;
                        });
                      }
                    }
                  },
            child: _isSubmitting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text('Save'),
          ),
        ],
      ),
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
        builder: (context, setState) => AlertDialog(
          title: Text('Re-authenticate'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Please enter your current password to proceed.'),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _isReauthenticating
                  ? null
                  : () {
                      Navigator.pop(context);
                    },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isReauthenticating
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
                        Navigator.pop(context);
                      } on FirebaseAuthException catch (e) {
                        String errorMessage = 'Re-authentication failed.';
                        if (e.code == 'wrong-password') {
                          errorMessage = 'Incorrect password.';
                        } else if (e.code == 'user-mismatch') {
                          errorMessage = 'User mismatch. Please try again.';
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
                            content:
                                Text('An error occurred. Please try again.'),
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
                  : Text('Confirm'),
            ),
          ],
        ),
      ),
    );

    return _isSuccessful;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Accounts',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple.shade800,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Colors.deepPurple,
              ),
            )
          : Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black, Colors.deepPurple.shade900],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: Icon(Icons.person, color: Colors.white),
                      title: Text(
                        'First Name',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        _userData?['first_name'] ?? '',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.edit, color: Colors.white),
                        onPressed: () => _showEditDialog(
                            'First Name', _userData?['first_name'] ?? ''),
                      ),
                    ),
                    Divider(color: Colors.white54),
                    ListTile(
                      leading: Icon(Icons.person_outline, color: Colors.white),
                      title: Text(
                        'Last Name',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        _userData?['last_name'] ?? '',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.edit, color: Colors.white),
                        onPressed: () => _showEditDialog(
                            'Last Name', _userData?['last_name'] ?? ''),
                      ),
                    ),
                    Divider(color: Colors.white54),
                    ListTile(
                      leading: Icon(Icons.account_circle, color: Colors.white),
                      title: Text(
                        'Username',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        _userData?['username'] ?? '',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.edit, color: Colors.white),
                        onPressed: () => _showEditDialog(
                            'Username', _userData?['username'] ?? ''),
                      ),
                    ),
                    Divider(color: Colors.white54),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              _showUpdateEmailDialog();
                            },
                      child: Text(
                        'Update Email',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple.shade600,
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              _showUpdatePasswordDialog();
                            },
                      child: Text(
                        'Update Password',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple.shade600,
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
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
