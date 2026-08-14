import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:clickngo/Admin/admin_dashboard/admin_home.dart';
import 'package:clickngo/Admin/admin_dashboard/admin_notification.dart';
import 'package:clickngo/Admin/admin_dashboard/admin_profile.dart';
import 'package:clickngo/Admin/admin_dashboard/admin_setting.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:get/get.dart';
import 'package:page_transition/page_transition.dart';
import 'package:uuid/uuid.dart';

import '../Component/color.dart';
import '../Form.dart';
import 'admin_dashboard/newentry.dart'; // Ensure Form.dart file is correctly named and imported

class AdminRootPage extends StatefulWidget {
  final String email;

  const AdminRootPage({Key? key, required this.email}) : super(key: key);

  @override
  State<AdminRootPage> createState() => _AdminRootPageState();
}

class _AdminRootPageState extends State<AdminRootPage> {
  int _bottomNavIndex = 0;
  String scanResult = '';
  List<Map<String, dynamic>> history = []; // List to store history

  // Define the title list for each bottom navigation tab
  final List<String> titleList = [
    'Hello Admin',
    'Notifications',
    'Settings',
    'Profile',
  ];

  // Define the icon list for each bottom navigation tab
  final List<IconData> iconList = [
    Icons.home,
    Icons.notifications,
    Icons.settings,
    Icons.person,
  ];

  @override
  void initState() {
    super.initState();
    // Additional initialization logic if needed
    if (widget.email.isEmpty) {
      // If email is not provided, navigate back to login page
      Get.offAllNamed('/login');
    }
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
    } on PlatformException catch (e) {
      Get.snackbar("Error Occurred", e.message ?? "Unknown error");
      return;
    } catch (e) {
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

          Navigator.pushReplacement(
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


  void _showOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.qr_code_scanner),
                title: Text('Scan'),
                onTap: () {
                  Navigator.pop(context); // Close the bottom sheet
                  startScan();
                },
              ),
              ListTile(
                leading: Icon(Icons.keyboard),
                title: Text('Manual Entry'),
                onTap: () {
                  Navigator.pop(context); // Close the bottom sheet
                  Navigator.push(
                    context,
                    PageTransition(
                      type: PageTransitionType.rightToLeft,
                      child: NewEntry(email : widget.email),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // List of the pages
    List<Widget> pages = [
      AdminHome(email: widget.email),
      AdminNotification(),
      AdminSetting(email : widget.email),
      AdminProfile(),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Add this line to remove the back button
        title: Text(
          titleList[_bottomNavIndex],
          style: TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w500,
            fontSize: 24,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0.0,
      ),
      body: IndexedStack(
        index: _bottomNavIndex,
        children: pages.map((page) {
          if (page is AdminHome) {
            return AdminHome(email:widget.email);
          }
          return page;
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showOptions,
        child: Icon(
          Icons.add,
          color: Colors.white,
          size: 30.0,
        ),
        // child: Image.asset('assets/images/code-scan-two.png', height: 30.0),
        backgroundColor: Color(0xFF7357a4),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedBottomNavigationBar(
        splashColor: Color(0xFF7357a4),
        activeColor: Color(0xFF7357a4),
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



