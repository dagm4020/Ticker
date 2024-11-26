import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _isFormValid = false;
  bool _isPasswordMinLength = false;
  bool _hasLetters = false;
  bool _hasNumbers = false;

  @override
  void initState() {
    super.initState();
    _firstNameController.addListener(_updateFormValidity);
    _lastNameController.addListener(_updateFormValidity);
    _usernameController.addListener(_updateFormValidity);
    _emailController.addListener(_updateFormValidity);
    _passwordController.addListener(_updateFormValidity);
  }

  void _updateFormValidity() {
    setState(() {
      _isPasswordMinLength = _passwordController.text.trim().length >= 6;
      _hasLetters =
          _passwordController.text.trim().contains(RegExp(r'[A-Za-z]'));
      _hasNumbers = _passwordController.text.trim().contains(RegExp(r'\d'));

      _isFormValid = _firstNameController.text.trim().isNotEmpty &&
          _lastNameController.text.trim().isNotEmpty &&
          _usernameController.text.trim().isNotEmpty &&
          _usernameController.text.trim().length >= 3 &&
          _emailController.text.trim().isNotEmpty &&
          RegExp(r'^[^@]+@[^@]+\.[^@]+')
              .hasMatch(_emailController.text.trim()) &&
          _isPasswordMinLength &&
          _hasLetters &&
          _hasNumbers;
    });
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        QuerySnapshot usernameQuery = await _firestore
            .collection('users')
            .where('username', isEqualTo: _usernameController.text.trim())
            .limit(1)
            .get();

        if (usernameQuery.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Username already taken. Please choose another one.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        await _firestore.collection('users').doc(userCredential.user?.uid).set({
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account created successfully! Please login.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(Duration(seconds: 2));
        Navigator.pushReplacementNamed(context, '/login');
      } on FirebaseAuthException catch (e) {
        _handleFirebaseError(e);
      } catch (e) {
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

    switch (e.code) {
      case 'weak-password':
        errorMessage =
            'The password is too weak. Please use at least 6 characters, including letters and numbers.';
        break;
      case 'email-already-in-use':
        errorMessage =
            'This email is already in use. Please use a different email.';
        break;
      case 'invalid-email':
        errorMessage =
            'The email address is not valid. Please check and try again.';
        break;
      case 'operation-not-allowed':
        errorMessage =
            'Email/Password accounts are not enabled. Please contact support.';
        break;
      default:
        errorMessage = 'An unexpected error occurred: ${e.message}';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      SlideRightRoute(page: LoginPage()),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildPasswordRequirement(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.cancel,
          color: isMet ? Colors.green : Colors.red,
          size: 16,
        ),
        SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: isMet ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
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
                    'Register',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 24),
                  TextFormField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: 'First Name',
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
                        return 'First name is required.';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                      prefixIcon: Icon(Icons.person_outline),
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
                        return 'Last name is required.';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.account_circle),
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
                        return 'Username is required.';
                      }
                      if (value.trim().length < 3) {
                        return 'Username must be at least 3 characters long.';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
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
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: Colors.black),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required.';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Please enter a valid email address.';
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
                  SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPasswordRequirement(
                          'At least 6 characters', _isPasswordMinLength),
                      _buildPasswordRequirement(
                          'Includes letters', _hasLetters),
                      _buildPasswordRequirement(
                          'Includes numbers', _hasNumbers),
                    ],
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          (_isFormValid && !_isLoading) ? _register : null,
                      child: _isLoading
                          ? CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : Text(
                              'Register',
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
                        'Already have an account?',
                        style: TextStyle(color: Colors.white),
                      ),
                      TextButton(
                        onPressed: _navigateToLogin,
                        child: Text('Login here'),
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

class SlideRightRoute extends PageRouteBuilder {
  final Widget page;
  SlideRightRoute({required this.page})
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
              begin: const Offset(-1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.ease,
            )),
            child: child,
          ),
        );
}
