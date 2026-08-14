import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _deviceToken;

  @override
  void initState() {
    super.initState();
    _requestPermission();
    _getDeviceToken();
    _setupForegroundNotificationListener();
  }

  // Request permission for notifications
  void _requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');
  }

  // Get the device token
  void _getDeviceToken() async {
    String? token = await _firebaseMessaging.getToken();
    setState(() {
      _deviceToken = token;
    });
    print("Device Token: $_deviceToken");
  }

  // Listen for foreground notifications
  void _setupForegroundNotificationListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        _showForegroundNotification(
            message.notification!.title,
            message.notification!.body
        );
      }
    });
  }

  // Display notification manually when app is in the foreground
  void _showForegroundNotification(String? title, String? body) {
    if (title == null || body == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<String> _getAccessToken() async {
    final jsonString =
    await rootBundle.loadString('assets/clickngo-17114-f2ca1e6f62bd.json');
    var serviceAccountCredentials = ServiceAccountCredentials.fromJson(
      json.decode(jsonString),
    );

    var scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    var client = http.Client();

    var accessCredentials = await obtainAccessCredentialsViaServiceAccount(
      serviceAccountCredentials,
      scopes,
      client,
    );
    return accessCredentials.accessToken.data;
  }

  // Function to send push notification
  void _sendPushNotification() async {
    if (_deviceToken == null) {
      print("Device token is not available.");
      return;
    }

    String accessToken = await _getAccessToken();
    String projectId = "clickngo-17114"; // Replace with your Firebase project ID
    String fcmUrl =
        "https://fcm.googleapis.com/v1/projects/$projectId/messages:send";

    Map<String, dynamic> notificationPayload = {
      "message": {
        "token": _deviceToken,
        "notification": {
          "title": "Hello from Flutter",
          "body": "This is a push notification triggered by a button click."
        },
        "data": {
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
          "status": "done"
        }
      }
    };

    var response = await http.post(
      Uri.parse(fcmUrl),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(notificationPayload),
    );

    if (response.statusCode == 200) {
      print("Push notification sent successfully.");
    } else {
      print("Failed to send push notification. Error: ${response.body}");
    }
  }

  // Send push notification after 5 seconds
  void _delayedPushNotification() {
    Future.delayed(Duration(seconds: 5), () {
      _sendPushNotification();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FCM Push Notification'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            print("Button pressed. Notification will be sent in 5 seconds.");
            _delayedPushNotification();
          },
          child: Text("Send Push Notification"),
        ),
      ),
    );
  }
}
