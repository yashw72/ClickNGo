import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'input.dart'; // Importing the animation package

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _errorMessage = '';
  String _successMessage = '';
  bool _emailVerified = false;

   Future<void> storeUserDetails(User user, String role) async {
    // Storing details in Firestore using the user's existing UID
    FirebaseFirestore.instance.collection('loggedUsers').doc(user.uid).set({
      'email': user.email,
      'role': role,
    });

    // Storing details locally using shared_preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', user.email!);
    await prefs.setString('role', role);
  }

  Future<void> _signUp() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _successMessage = '';
      });

      try {
        // Create a new user with email and password
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        User? user = userCredential.user;

        if (user != null) {
          // Assume role determination happens here (you can adjust the logic as per your need)
          String role = 'normaluser'; // Example function for role

          // Store user details both in Firestore and locally
          await storeUserDetails(user, role);

          // Send email verification
          await user.sendEmailVerification();

          // Show success message
          setState(() {
            _successMessage =
            'A verification email has been sent to ${user.email}. Please verify your email to continue.';
          });

          // Continuously check if the email is verified
          _checkEmailVerified(user);
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          _errorMessage = _getAuthErrorMessage(e);
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'An unexpected error occurred. Please try again.';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkEmailVerified(User user) async {
    // Wait for the user to manually verify their email
    await Future.delayed(const Duration(seconds: 3)); // Polling interval

    await user.reload(); // Reloads user data from Firebase
    user = FirebaseAuth.instance.currentUser!;

    if (user.emailVerified) {
      setState(() {
        _emailVerified = true;
        _successMessage = 'Email verified successfully!';
      });

      // Show success animation screen before navigating
      _showSuccessAnimation();
    } else {
      // If the email is still not verified, keep checking.
      _checkEmailVerified(user);
    }
  }

  void _showSuccessAnimation() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SuccessAnimationScreen(email: _emailController.text.trim()),
      ),
    );
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'The email address is already in use by another account.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'operation-not-allowed':
        return 'Operation not allowed. Please enable this service in your Firebase console.';
      case 'weak-password':
        return 'The password is too weak. Please choose a stronger password.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register"),
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  'assets/animations/Animation - 1725686919773.json', // Path to your JSON file
                  width: 300,
                  height: 270,
                  fit: BoxFit.fill,
                ),
                const Text(
                  "Create a New Account",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  "Please enter your email and password to register. Make sure your password is at least 6 characters long.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                _buildTextFormField(
                  controller: _emailController,
                  hintText: "Enter your Email",
                  icon: Icons.email,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                _buildTextFormField(
                  controller: _passwordController,
                  hintText: "Enter your Password",
                  icon: Icons.lock,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters long';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: _signUp,
                  child: const Text(
                    "Sign Up",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_errorMessage.isNotEmpty)
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                if (_successMessage.isNotEmpty)
                  Text(
                    _successMessage,
                    style: const TextStyle(color: Colors.green),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 20),
                if (!_emailVerified)
                  const Text(
                    'Please verify your email to proceed.',
                    style: TextStyle(color: Colors.orange),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        prefixIcon: Icon(icon, color: Colors.black),
      ),
      validator: validator,
    );
  }
}

class SuccessAnimationScreen extends StatelessWidget {
  final String email;

  const SuccessAnimationScreen({Key? key, required this.email}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DataScreen(email: email)),
      );
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body:
         Center(
           child: SingleChildScrollView(

              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/animations/Animation - 1725686640443.json', // Path to your JSON file
                    width: 270,
                    height: 200,

                  ),
                  const Text(
                    'Email Verified!',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                SizedBox(height: 10,),
                  const Text(
                    'Redirecting you...',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 40),

                ],
              ),
            ),
         ),


    );
  }
}
