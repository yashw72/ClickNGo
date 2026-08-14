import 'package:audioplayers/audioplayers.dart';
import 'package:clickngo/root_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class MyFormPage extends StatefulWidget {
  final String orgName;
  final String orgUUID;
  final String email;
  final Function(Map<String, dynamic>)? onFormSubmitted;

  const MyFormPage({
    Key? key,
    required this.orgName,
    required this.orgUUID,
    required this.email,
    this.onFormSubmitted,
  }) : super(key: key);

  @override
  _MyFormPageState createState() => _MyFormPageState();
}

class _MyFormPageState extends State<MyFormPage> {
  late TextEditingController _nameController;
  late TextEditingController _vehicleNumberController;
  late TextEditingController _emailController;
  late TextEditingController _organizationNameController;
  late TextEditingController _purposeController;
  late String _currentDateTime;
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Function to play sound
  Future<void> _playSound() async {
    await _audioPlayer.play(AssetSource('audio/audio.mpeg')); // Load sound from assets
  }
  @override
  void initState() {
    super.initState();
    _currentDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    _nameController = TextEditingController();
    _vehicleNumberController = TextEditingController();
    _emailController = TextEditingController(text: widget.email);
    _organizationNameController = TextEditingController(text: widget.orgName);
    _purposeController = TextEditingController();
    _fetchDetails();
    _initializeLocalNotifications();

  }

  void _initializeLocalNotifications() {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }



  Future<void> _fetchDetails() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final docRef = firestore.collection('Users').doc(widget.email);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        setState(() {
          _nameController.text = data['Name'] ?? '';
          _vehicleNumberController.text = data['Vehicle no'] ?? '';
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
  Future<String?> _getOrgEmailDocumentId(String orgName) async {
    try {
      // Reference the collection where organizations are stored
      final firestore = FirebaseFirestore.instance;

      // Query the 'Organizations' collection for the document where 'OrgName' matches
      final orgSnapshot = await firestore
          .collection('Organizations')
          .where('Org Name', isEqualTo: orgName)
          .limit(1)
          .get();

      if (orgSnapshot.docs.isNotEmpty) {
        // Extract the document ID (which represents the email) from the first matching document
        return orgSnapshot.docs.first.id;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No organization found with the name: $orgName')),
        );
        return null;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching organization document ID: $e')),
      );
      return null;
    }
  }

  Future<void> _submitFormData() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final historyDocRef = firestore
          .collection('Users')
          .doc(widget.email)
          .collection('History')
          .doc();

      await historyDocRef.set({
        'Name': _nameController.text,
        'VehicleNumber': _vehicleNumberController.text,
        'Email': _emailController.text,
        'Organization': widget.orgName,
        'Purpose': _purposeController.text,
        'DateTime': _currentDateTime,
      });
      String? orgemail = await _getOrgEmailDocumentId(widget.orgName);
      print(orgemail);
      final dataDocRef = firestore
          .collection('Organizations')
          .doc(orgemail)
          .collection('DATA')
          .doc();

      await dataDocRef.set({
        'Name': _nameController.text,
        'VehicleNumber': _vehicleNumberController.text,
        'Email': _emailController.text,
        'Organization': widget.orgName,
        'Purpose': _purposeController.text,
        'DateTime': _currentDateTime,
      });
      _playSound();
      // Call the function to show a local notification
      await _showLocalNotification(
        'Registration Successful',
        'You have successfully registered at ${widget.orgName} on ${_currentDateTime}',
      );

      if (widget.onFormSubmitted != null) {
        widget.onFormSubmitted!({
          'organization': widget.orgName,
          'datetime': _currentDateTime,
          'purpose': _purposeController.text,
        });
      }

      Get.off(() => RootPage(email: widget.email));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Form Submitted Successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting form: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails('your_channel_id', 'your_channel_name',
        channelDescription: 'your_channel_description',
        importance: Importance.max,
        priority: Priority.high);

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
        0,
        title,
        body,
        platformChannelSpecifics,
        payload: 'item x');
  }

  Future<void> _checkFormAndSubmit() async {
    if (_purposeController.text.isNotEmpty) {
      await _submitFormData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill out the Purpose of Visit.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Form Page'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormField('Organization Name:', _organizationNameController, enabled: false),
              SizedBox(height: 16),
              _buildFormField('Email:', _emailController, enabled: false),
              SizedBox(height: 16),
              _buildFormField('Name:', _nameController, enabled: false),
              SizedBox(height: 16),
              _buildFormField('Vehicle Number:', _vehicleNumberController, enabled: false),
              SizedBox(height: 16),
              _buildFormField('Date and Time:', TextEditingController(text: _currentDateTime), enabled: false),
              SizedBox(height: 16),
              Text(
                'Purpose of Visit:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _purposeController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Purpose of Visit',
                  labelStyle: TextStyle(color: Colors.black54),
                ),
              ),
              SizedBox(height: 30),
              Center(
                child: SlideAction(
                  text: "Slide To Register",
                  onSubmit: _checkFormAndSubmit,
                  outerColor: Colors.black,
                  innerColor: Colors.white,
                  borderRadius: 100,
                  height: 70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(String label, TextEditingController controller, {bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: label,
            labelStyle: TextStyle(color: Colors.black54),
          ),
        ),
      ],
    );
  }
}
