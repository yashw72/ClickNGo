import 'package:clickngo/screens/history_page.dart';
import 'package:clickngo/screens/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';


class Loading extends StatefulWidget {
  final String email;
  const Loading({super.key,required this.email});

  @override
  State<Loading> createState() => _LoadingState();
}

class _LoadingState extends State<Loading> {
  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HistoryPage(email: widget.email)),
      );
    });
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animations/Animation - 1725686193709.json', // Path to your JSON file
                width: 270,
                height: 200,

              ),
              const Text(
                'Fetching your History',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),



            ],
          ),
        ),
      ),


    );
  }
}
