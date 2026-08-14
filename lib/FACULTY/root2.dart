import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:clickngo/Form.dart';
import 'package:clickngo/screens/Settings_page.dart';
import 'package:clickngo/screens/history_page.dart';
import 'package:clickngo/screens/home_page.dart';
import 'package:clickngo/screens/notification_page.dart';
import 'package:clickngo/screens/profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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





class RootPage2 extends StatefulWidget {
  final String email;

  const RootPage2({Key? key, required this.email}) : super(key: key);

  @override
  State<RootPage2> createState() => _RootPage2State();
}

class _RootPage2State extends State<RootPage2> {
  int _bottomNavIndex = 0;
  final loc.Location location = loc.Location();
  String scanResult = '';
  double currentDistance = 0.0;
  String name="";
  String branch="";
  final Telephony telephony = Telephony.instance;
  List<Map<String, dynamic>> history = []; // List to store history

  // Define the title list for each bottom navigation tab
  final List<String> titleList = [
    'Home',
    'Notifications',
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
    startTracking();
    startBackgroundTracking(); // Start background tracking
    pages = [
      HomePage(distance: currentDistance,email: widget.email,),
      NotificationPage(),
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
  Future<void> _fetchDetails() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final docRef = firestore.collection('Users').doc(widget.email);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        setState(() {
          name = data['Name'] ?? '';
          branch = data['Branch'] ?? '';
          print("Name retrieved : "+name);
          print("branch retrieved : "+branch);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No user found with the provided email.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user details: $e')),
      );
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
  // Function to start tracking location
  void startTracking() async {
    bool _serviceEnabled;
    loc.PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        print("Location service not enabled"); // Log service status
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == loc.PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != loc.PermissionStatus.granted) {
        print("Location permission not granted"); // Log permission status
        return;
      }
    }

    location.onLocationChanged.listen((loc.LocationData currentLocation) {
      // Log location update
      setState(() {
        currentDistance = _calculateDistance(currentLocation);
      });
      checkGeofence(currentLocation);
    });
  }

  // Function to start background tracking
  void startBackgroundTracking() async {
    try {
      // Set up Android notification for background tracking
      await bg_location.BackgroundLocation.setAndroidNotification(
        title: 'Location Tracking',
        message: 'Your location is being tracked in the background',
        icon: '@mipmap/ic_launcher',
      );
      print("Android notification set up for background tracking");

      // Stop any previous location service if running
      await bg_location.BackgroundLocation.stopLocationService();
      print("Previous location service stopped");

      // Configure the background location settings and start the location service
      await bg_location.BackgroundLocation.setAndroidConfiguration(30000); // 30 seconds
      print("Background location configuration set");

      await bg_location.BackgroundLocation.startLocationService(distanceFilter: 10);
      print("Background location service started");

      // Start receiving location updates
      bg_location.BackgroundLocation.getLocationUpdates((bg_location.Location location) {
        print("Background location update: ${location.latitude}, ${location.longitude}"); // Log background location update
        setState(() {
          currentDistance = _calculateDistance(loc.LocationData.fromMap({
            'latitude': location.latitude,
            'longitude': location.longitude,
          }));
        });
        checkGeofence(loc.LocationData.fromMap({
          'latitude': location.latitude,
          'longitude': location.longitude,
        }));
      });
    } catch (e) {
      print("Error in background tracking: $e"); // Log any errors
    }
  }

  // Function to calculate distance
  double _calculateDistance(loc.LocationData currentLocation) {
    double collegeLat = 19.952975;
    double collegeLong = 73.863793;

    return Geolocator.distanceBetween(
      collegeLat,
      collegeLong,
      currentLocation.latitude!,
      currentLocation.longitude!,
    );
  }
  bool hasCrossedBoundary = false;
  // Function to check geofence
  // Function to check geofence
  Future<String?> getHODEmailFromBranch(String branch) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final collection = firestore.collection('HOD');

      // Query documents where the 'Branch' field matches the given branch
      final querySnapshot = await collection.where('Branch', isEqualTo: branch).get();

      if (querySnapshot.docs.isNotEmpty) {
        // Assuming there is only one document per branch
        // Return the document ID which is the HOD email
        return querySnapshot.docs.first.id;
      } else {
        print('No HOD found for the branch: $branch');
        return null;
      }
    } catch (e) {
      print('Error fetching HOD email: $e');
      return null;
    }
  }

  Future<void> checkGeofence(loc.LocationData currentLocation) async {
    double collegeLat = 19.952975;
    double collegeLong = 73.863793;
    double boundaryRadius = 50;

    double distance = _calculateDistance(currentLocation);

    // Continuously send SMS if out of boundary
    if (distance > boundaryRadius && !hasCrossedBoundary) {
      setState(() {
        hasCrossedBoundary = true; // Set the flag to true when the boundary is crossed
      });
      Get.snackbar(
        "Boundary Alert",
        "You have crossed the college boundary!",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: EdgeInsets.all(8),
        borderRadius: 8,
        duration: Duration(seconds: 5),
      );
      Timestamp currentTimestamp = Timestamp.now();
      DateTime currentDateTime = currentTimestamp.toDate();

      await _fetchDetails();
      // Save the boundary breach info in Firestore
      String? hodemail = await getHODEmailFromBranch(branch);
      await FirebaseFirestore.instance.collection('HOD').doc(hodemail).collection("faculties").doc(name).collection("BREACHES").add({
        'facultyName' : name,
        'facultyEmail': widget.email,
        'datetime' : currentDateTime

      });
      await FirebaseFirestore.instance.collection('HOD').doc(hodemail).collection("BREACHES").add({
        'facultyName' : name,
        'facultyEmail': widget.email,
        'datetime' : currentDateTime

      });

      _sendSmsNotification();
    }
    else if(distance <= boundaryRadius && hasCrossedBoundary){
      setState(() {
        hasCrossedBoundary = false;
      });
    }
  }

  // Function to send SMS notification
  void _sendSmsNotification() async {
    String message = "You have crossed the boundary";
    List<String> recipients = [];

    for (String recipient in recipients) {
      try {
        await telephony.sendSms(
          to: recipient,
          message: message,
        );
        Get.snackbar("SMS Sent", "Notification SMS has been sent to $recipient.");

      } catch (e) {
        Get.snackbar("SMS Error", "Failed to send SMS to $recipient.");

      }
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
