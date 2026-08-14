import 'package:flutter/material.dart';
import 'package:clickngo/banner_ad_widget.dart'; // Import your BannerAdWidget here

class ADScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ClickNGo - Ads Screen'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Display the Banner Ad at the top
          BannerAdWidget(),
          SizedBox(height: 20),
          Text(
            'Welcome to the Ads screen!',
            style: TextStyle(fontSize: 24),
          ),
          SizedBox(height: 20),
          Text(
            'This is where your main content will go.',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
