import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'registration_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _isFormValid = false;
  @override
  void initState() {
    super.initState();
    _identifierController.addListener(_updateFormValidity);
    _passwordController.addListener(_updateFormValidity);
  }

  void _updateFormValidity() {
    setState(() {
      _isFormValid = _identifierController.text.trim().isNotEmpty &&
          _passwordController.text.trim().isNotEmpty;
    });
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        String identifier = _identifierController.text.trim();
        String password = _passwordController.text.trim();

        String? email;

        if (RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(identifier)) {
          email = identifier;
        } else {
          QuerySnapshot userQuery = await _firestore
              .collection('users')
              .where('username', isEqualTo: identifier)
              .limit(1)
              .get();

          if (userQuery.docs.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('No user found with that username.'),
                backgroundColor: Colors.red,
              ),
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }

          email = userQuery.docs.first.get('email');
        }

        await _auth.signInWithEmailAndPassword(
          email: email!,
          password: password,
        );

        Navigator.pushReplacementNamed(context, '/home');
      } on FirebaseAuthException catch (e) {
        _handleFirebaseError(e);
      } catch (e) {
        print('Unexpected error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleFirebaseError(FirebaseAuthException e) {
    String errorMessage = 'An error occurred. Please try again.';
    print('FirebaseAuthException: ${e.code}');
    switch (e.code) {
      case 'user-not-found':
        errorMessage = 'No user found for that email/username.';
        break;
      case 'invalid-credential':
        errorMessage = 'Invalid credentials';
        break;
      case 'invalid-email':
        errorMessage = 'The email address is not valid.';
        break;
      case 'user-disabled':
        errorMessage = 'This user has been disabled. Please contact support.';
        break;
      default:
        errorMessage = 'An unexpected error occurred. Please try again.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      SlideLeftRoute(page: RegistrationPage()),
    );
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 24),
                  TextFormField(
                    controller: _identifierController,
                    decoration: InputDecoration(
                      labelText: 'Email or Username',
                      prefixIcon: Icon(Icons.person),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                      labelStyle: TextStyle(color: Colors.black),
                      floatingLabelStyle: TextStyle(color: Colors.black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                          color: Colors.deepPurple.shade600,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                          color: Colors.deepPurple.shade600,
                        ),
                      ),
                    ),
                    style: TextStyle(color: Colors.black),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email or username.';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                      labelStyle: TextStyle(color: Colors.black),
                      floatingLabelStyle: TextStyle(color: Colors.black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                          color: Colors.deepPurple.shade600,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                          color: Colors.deepPurple.shade600,
                        ),
                      ),
                    ),
                    style: TextStyle(color: Colors.black),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Password is required.';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isFormValid && !_isLoading) ? _login : null,
                      child: _isLoading
                          ? CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : Text(
                              'Login',
                              style: TextStyle(fontSize: 16),
                            ),
                      style: ButtonStyle(
                        foregroundColor:
                            MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.disabled))
                              return Colors.grey;
                            return Colors.white;
                          },
                        ),
                        backgroundColor: MaterialStateProperty.all<Color>(
                            Colors.deepPurple.shade600),
                        padding: MaterialStateProperty.all<EdgeInsets>(
                          EdgeInsets.symmetric(vertical: 16.0),
                        ),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: TextStyle(color: Colors.white),
                      ),
                      TextButton(
                        onPressed: _navigateToRegister,
                        child: Text('Register here'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.deepPurpleAccent,
                        ),
                      ),
                    ],
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

class SlideLeftRoute extends PageRouteBuilder {
  final Widget page;
  SlideLeftRoute({required this.page})
      : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.ease,
            )),
            child: child,
          ),
        );
}
