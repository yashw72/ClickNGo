import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InternetController extends GetxController {
  Connectivity c = Connectivity();

  @override
  void onInit() {
    super.onInit();

    c.onConnectivityChanged.listen(Status);
  }

  void Status(ConnectivityResult cr) {
    if (cr == ConnectivityResult.none) {
      print("No Internet");
      Get.rawSnackbar(
        title: "No internet",  // Corrected typo
        message: "Connect to the internet to proceed",
        icon: Icon(Icons.wifi_off),
        isDismissible: false,
        backgroundColor: Colors.red,
        duration: Duration(days: 1),
        shouldIconPulse: true,
      );
    } else {
      if (Get.isSnackbarOpen) {
        Get.closeCurrentSnackbar();
        Get.rawSnackbar(
          title: "Internet Availabe",  // Corrected typo
          message: "You are connected to the internet",
          icon: Icon(Icons.wifi),
          isDismissible: false,
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
          shouldIconPulse: true,
        );
      }

    }
  }
}
