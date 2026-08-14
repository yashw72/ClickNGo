import 'dart:async';
import 'package:clickngo/Onboboarding/onboarding_view.dart';
import 'package:clickngo/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'Authentication/login_auth.dart';

class SplashScreen extends StatefulWidget{
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Timer(Duration(seconds: 3),(){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> OnboardingView()));
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(360),

            image: DecorationImage(
              image: AssetImage("assets/images/logo.jpeg"),
              fit: BoxFit.cover,

            ),
          ),


        ),
      ),
    );
  }
}