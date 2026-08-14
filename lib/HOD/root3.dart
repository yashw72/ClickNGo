import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:clickngo/HOD/Breaches.dart';
import 'package:clickngo/screens/Settings_page.dart';
import 'package:clickngo/screens/history_page.dart';
import 'package:clickngo/screens/home_page.dart';
import 'package:clickngo/screens/notification_page.dart';
import 'package:clickngo/screens/profile_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:background_location/background_location.dart' as bg_location;
import 'package:location/location.dart' as loc;
import 'package:page_transition/page_transition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:telephony/telephony.dart';
import 'package:uuid/uuid.dart';

import '../Form.dart'; // Ensure Form.dart file is correctly named and imported

class RootPage3 extends StatefulWidget {
  final String email;

  const RootPage3({Key? key, required this.email}) : super(key: key);

  @override
  State<RootPage3> createState() => _RootPage3State();
}

class _RootPage3State extends State<RootPage3> {
  int _bottomNavIndex = 0;
  final loc.Location location = loc.Location();
  String scanResult = '';
  double currentDistance = 0.0;
  final Telephony telephony = Telephony.instance;
  List<Map<String, dynamic>> history = []; // List to store history

  // Define the title list for each bottom navigation tab
  final List<String> titleList = [
    'Home',
    'Boundary Breaches',
    'History',
    'Settings',
  ];

  // Define the icon list for each bottom navigation tab
  final List<IconData> iconList = [
    Icons.home,
    Icons.notifications,
    Icons.history,
    Icons.settings,
  ];

  // List of the pages
  List<Widget> pages = [];

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();

    pages = [
      HomePage(distance: currentDistance,email: widget.email,),
      HODBoundaryBreachesPage(hodEmail: widget.email),
      HistoryPage(email: widget.email),
      SettingsPage(),
    ];
  }

  // Function to validate UUID
  bool isValidUUID(String uuid) {
    try {
      Uuid.parse(uuid);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Function to start scanning
  Future<void> startScan() async {
    var result;
    try {
      result = await FlutterBarcodeScanner.scanBarcode(
        '#00FF00',
        'Cancel',
        true,
        ScanMode.QR,
      );
      print("Scan result: $result"); // Log scan result
    } on PlatformException catch (e) {
      print("PlatformException: ${e.message}"); // Log exception
      Get.snackbar("Error Occurred", e.message ?? "Unknown error");
      return;
    } catch (e) {
      print("Exception: $e"); // Log exception
      Get.snackbar("Error", "An unexpected error occurred");
      return;
    }

    if (!mounted) return;

    if (result != '-1') {
      const String expectedPrefix = "https://66cb1c3dccec5e00083c8861--clickngoform.netlify.app/?organization=";

      if (result.startsWith(expectedPrefix)) {
        Uri uri = Uri.parse(result);
        String? orgUUID = uri.queryParameters['organizationid'];
        String? orgName = uri.queryParameters['organization'];

        if (orgUUID != null && isValidUUID(orgUUID)) {
          setState(() {
            scanResult = result;
          });

          Navigator.push(
            context,
            PageTransition(
              type: PageTransitionType.bottomToTop,
              child: MyFormPage(
                email: widget.email,
                orgName: orgName ?? '',
                orgUUID: orgUUID,
                onFormSubmitted: (entry) {
                  setState(() {
                    history.add(entry); // Append new entry
                  });
                },
              ),
            ),
          );
        } else {
          Get.snackbar(
            "Invalid QR Code",
            "The QR code does not contain a valid UUID.",
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } else {
        Get.snackbar(
          "Invalid QR Code",
          "The scanned QR code does not have the correct prefix.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }
  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.status;

    if (!status.isGranted) {
      // Request the notification permission
      final result = await Permission.notification.request();

      if (result.isGranted) {
        print('Notification permission granted');
      } else {
        print('Notification permission denied');
      }
    } else {
      print('Notification permission already granted');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              titleList[_bottomNavIndex],
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
                fontSize: 24,
              ),
            ),
            Container(
              child: GestureDetector(
                child: Icon(
                  Icons.person,
                  color: Colors.black54,
                  size: 30.0,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    PageTransition(
                      type: PageTransitionType.rightToLeft,
                      child: ProfilePage(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0.0,
      ),
      body: IndexedStack(
        index: _bottomNavIndex,
        children: pages.map((page) {
          if (page is HomePage) {
            return HomePage(distance: currentDistance,email: widget.email,);
          }
          return page;
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: startScan,
        child: Image.asset('assets/images/code-scan-two.png', height: 30.0),
        backgroundColor: Colors.black,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedBottomNavigationBar(
        splashColor: Colors.black,
        activeColor: Colors.black,
        inactiveColor: Colors.black.withOpacity(.5),
        icons: iconList,
        activeIndex: _bottomNavIndex,
        gapLocation: GapLocation.center,
        notchSmoothness: NotchSmoothness.softEdge,
        onTap: (index) {
          setState(() {
            _bottomNavIndex = index;
          });
        },
      ),
    );
  }
}
