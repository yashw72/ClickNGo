import 'package:flutter/material.dart';

import 'InterstitalAd.dart';

class AdScreen extends StatefulWidget {
  const AdScreen({super.key});

  @override
  State<AdScreen> createState() => _AdScreenState();
}

class _AdScreenState extends State<AdScreen> {
  final InterstitialAdWidget _interstitialAdWidget = InterstitialAdWidget();
  @override
  void initState() {
    super.initState();
    _interstitialAdWidget.loadInterstitialAd();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
     body : Center(

        child : Text("Ad Screen "),
      ),
    );
  }
}
