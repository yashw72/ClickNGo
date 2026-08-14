import 'package:clickngo/Component/color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clickngo/Component/important_functions.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class NotificationModel {
  final String title;
  final String description;
  final DateTime timestamp;

  NotificationModel({
    required this.title,
    required this.description,
    required this.timestamp,
  });
}

class AdminNotification extends StatefulWidget {
  @override
  _AdminNotificationState createState() => _AdminNotificationState();
}

class _AdminNotificationState extends State<AdminNotification> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<NotificationModel> notifications = [];
  String? ORGNAME;
  bool isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    fetchNotifications(); // Fetch existing notifications from Firestore
    // Set up a timer to check for new entries every 15 minutes
    _timer = Timer.periodic(Duration(minutes: 1), (Timer t) {
      notifyNewEntriesLastHour();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  Future<void> fetchNotifications() async {
    try {
      setState(() {
        isLoading = true;
      });

      User? admin = _auth.currentUser;

      if (ORGNAME == null) {
        throw Exception('Organization name is null');
      }

      final notificationSnapshot = await FirebaseFirestore.instance.collection('Notifications').get();

      List<NotificationModel> fetchedNotifications = notificationSnapshot.docs.map((doc) {
        final timestamp = doc['timestamp'];
        DateTime dateTime;
        if (timestamp is Timestamp) {
          dateTime = timestamp.toDate();
        } else if (timestamp is String) {
          dateTime = DateTime.tryParse(timestamp) ?? DateTime.now(); // Fallback to current time
        } else {
          dateTime = DateTime.now(); // Default in case of an unknown format
        }
        return NotificationModel(
          title: doc['title'],
          description: doc['description'],
          timestamp: dateTime,
        );
      }).toList();

      setState(() {
        notifications.addAll(fetchedNotifications);
      });

      await notifyNewEntriesLastHour(); // Check for new entries in the last hour
    } catch (e) {
      print("Error fetching notifications: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching notifications: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> notifyNewEntriesLastHour() async {
    try {
      DateTime oneHourAgo = DateTime.now().subtract(Duration(hours: 1));

      if (ORGNAME != null) {
        final entrySnapshot = await FirebaseFirestore.instance
            .collection('Organizations')
            .doc(ORGNAME!)
            .collection('DATA')
            .where('DateTime', isGreaterThanOrEqualTo: oneHourAgo)
            .get();

        int count = entrySnapshot.size;

        if (count > 0) {
          final newNotification = NotificationModel(
            title: 'New Entries in Last Hour',
            description: '$count new entries have been made in your organization in the last hour.',
            timestamp: DateTime.now(),
          );

          // Add to Firestore
          try {
            await FirebaseFirestore.instance.collection('Notifications').add({
              'title': newNotification.title,
              'description': newNotification.description,
              'timestamp': Timestamp.now(),
            });
          } catch (e) {
            print('Error adding document: $e');
          }

          // Add to the local list and update UI
          setState(() {
            notifications.add(newNotification);
          });
        }
      }
    } catch (e) {
      print("Error fetching new entries: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching new entries: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            elevation: 4,
            child: ListTile(
              leading: Icon(
                Icons.notifications,
                color: primaryColor,
              ),
              title: Text(
                notification.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              subtitle: Text(
                notification.description,
                style: TextStyle(
                  color: Colors.black54,
                ),
              ),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('yMd').format(notification.timestamp),
                    style: TextStyle(color: Colors.grey),
                  ),
                  Text(
                    DateFormat('jm').format(notification.timestamp),
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
