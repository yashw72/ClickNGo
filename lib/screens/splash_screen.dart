import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:clickngo/Onboboarding/onboarding_view.dart';
import 'package:flutter/material.dart';

import '../Admin/admin_root_page.dart';
import '../FACULTY/root2.dart';
import '../HOD/root3.dart';
import '../Users/login_auth.dart';
import '../Users/root_page.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkOnboardingStatus(); // Check onboarding status when splash screen initializes
  }

  Future<void> checkDetailsLocallyAndNavigate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');
    String? role = prefs.getString('role');

    if (email != null && role != null) {
      // If details are present, navigate based on the role
      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminRootPage(email: email),
          ),
        );
      } else if (role == 'faculty') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RootPage2(email: email)),
        );
      } else if (role == 'HOD') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RootPage3(email: email)),
        );
      } else if (role == 'normaluser') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RootPage(email: email),
          ),
        );
      }
    } else {
      // No user is logged in, redirect to the login page
    }
  }

  Future<void> checkOnboardingStatus() async {
    // Get instance of SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Check if onboarding has been completed by retrieving the "onboarding" flag
    bool hasSeenOnboarding = prefs.getBool("onboarding") ?? false;

    // Wait for 3 seconds before navigating
    await Future.delayed(const Duration(seconds: 3));

    // Navigate based on the onboarding status
    if (hasSeenOnboarding) {
      checkDetailsLocallyAndNavigate(); // Check if details are stored and navigate
      // If onboarding was already shown, navigate to the login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => EmailPasswordAuth()),
      );
    } else {
      // If onboarding is not completed, show the onboarding screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OnboardingView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Center the logo
          Expanded(
            child: Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/qrcode.png"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          // Align the name at the bottom
          Padding(
            padding:
                const EdgeInsets.only(bottom: 40.0), // Adjust bottom spacing
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Center(
                child: Text(
                  "ClickNGo\n   v1.0.0",
                  style: TextStyle(
                    fontSize: 20,

                    color:
                        Colors.black.withOpacity(0.4), // Set the color to grey
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
