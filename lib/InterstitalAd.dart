import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class InterstitialAdWidget {
  InterstitialAd? _interstitialAd;

  // Load the interstitial ad
  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-5214491851748744/8086535938', // Replace with your Ad Unit ID
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('InterstitialAd failed to load: $error');

        },
      ),
    );
  }

  // Show the interstitial ad
  void showInterstitialAd(BuildContext context) {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null; // Dispose of the ad after showing
      loadInterstitialAd(); // Load a new ad for future use
    } else {
      print('InterstitialAd is not ready yet.');
    }
  }

  // Dispose of the ad when no longer needed
  void dispose() {
    _interstitialAd?.dispose();
  }
}
