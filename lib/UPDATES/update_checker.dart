import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateChecker {
  final String versionUrl = "https://clickngo.netlify.app/images/version.json";

  Future<String?> fetchLatestVersion() async {
    try {
      var response = await Dio().get(versionUrl);
      return response.data['latest_version'];
    } catch (e) {
      print("Error fetching latest version: $e");
      return null;
    }
  }

  Future<String> getCurrentVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  Future<void> checkForUpdate(BuildContext context) async {
    String currentVersion = await getCurrentVersion();
    String? latestVersion = await fetchLatestVersion();

    if (latestVersion != null && _isOutdated(currentVersion, latestVersion)) {
      print("App is not updated");
      await _showUpdateDialog(context); // Check for updates repeatedly until updated
    }else{
      print("app is updated");
    }

  }

  bool _isOutdated(String currentVersion, String latestVersion) {
    List<String> currentParts = currentVersion.split('.');
    List<String> latestParts = latestVersion.split('.');

    for (int i = 0; i < latestParts.length; i++) {
      if (int.parse(currentParts[i]) < int.parse(latestParts[i])) {
        return true;
      } else if (int.parse(currentParts[i]) > int.parse(latestParts[i])) {
        return false;
      }
    }
    return false;
  }

  Future<void> _showUpdateDialog(BuildContext context) async {
    bool updated = false; // Track if the app has been updated

    while (!updated) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Update Required"),
            content: Text("A new version of the app is available. Please update the app from our website to continue."),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _launchUpdatePage();
                  updated = true; // Set to true after launching the update page
                },
                child: Text("Update Now"),
              ),
            ],
          );
        },
      );

      // After the dialog is closed, check for updates again
      String currentVersion = await getCurrentVersion();
      String? latestVersion = await fetchLatestVersion();
      updated = latestVersion != null && !_isOutdated(currentVersion, latestVersion);
    }
  }

  Future<void> _launchUpdatePage() async {
    Uri url = Uri.parse('https://clickngo.netlify.app/#download');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Error launching URL: $e');
    }
  }
}
