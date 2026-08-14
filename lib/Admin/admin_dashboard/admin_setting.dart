import 'dart:developer';

import 'package:clickngo/Admin/admin_dashboard/qr_generation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../Authentication/login_auth.dart';
import '../../pdf_generator.dart';
import '../../screens/Settings_page.dart';

const intialBlack = Colors.black;
const intialWhite = Colors.white;

class AdminSetting extends StatefulWidget {
  final String email;

  const AdminSetting({super.key,required this.email});

  @override
  State<AdminSetting> createState() => _AdminSettingState();
}

class _AdminSettingState extends State<AdminSetting> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Load user settings
  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    });
  }

  // Save user settings
  void _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
  }

  Future<String?> fetchQrData(String orgEmail) async {
    try {
      // Access Firestore collection for Organizations
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection('Organizations')
          .doc(orgEmail) // Using email as document ID
          .get();

      if (snapshot.exists) {
        // Assuming `qrdata` is a field in the document
        return snapshot.data()?['qrdata'];
      } else {
        log('Organization with email $orgEmail does not exist.');
        return null;
      }
    } catch (e) {
      log('Error fetching QR data: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor =  intialBlack;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('General', textColor),
              _buildSettingTile(
                title: 'Notifications',
                subtitle: 'Receive notifications about updates',
                trailing: Switch(
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                    _saveSettings();
                  },
                ),
                textColor: textColor,
              ),
              SizedBox(height: 20.0),
              _buildSectionTitle('Account', textColor),
              _buildSettingTile(
                title: 'Privacy',
                subtitle: 'Manage your privacy settings',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PrivacySettingsPage(textColor)),
                  );
                },
                textColor: textColor,
              ),
              _buildSettingTile(
                title: 'Change Password',
                subtitle: 'Update your account password',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ChangePasswordScreen()),
                  );
                },
                textColor: textColor,
              ),
              _buildSettingTile(
                title: 'Logout',
                subtitle: 'Sign out of your account',
                onTap: _showLogoutConfirmationDialog,
                textColor: textColor,
              ),
              SizedBox(height: 20.0),
              _buildSectionTitle('Organization Management', textColor),
              _buildSettingTile(
                title: 'Organization QR',
                subtitle: 'Get your customized organization QR.',
                onTap: () async {
                  String? qrdata = await fetchQrData(widget.email);

                  if (qrdata != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => QR(qrdata: qrdata, email: widget.email)),
                    );
                  } else {
                    // Handle the case when QR data is null, such as showing a message
                    log('QR data is null. Navigation aborted.');
                  }

                },
                textColor: textColor,
              ),
              _buildSettingTile(
                title: 'Generate Organization Entry Report',
                subtitle: 'Get your customized entry report of your organization.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PdfGenerator()),
                  );
                },
                textColor: textColor,
              ),
              SizedBox(height: 20.0),
              _buildSectionTitle('About', textColor),
              _buildSettingTile(
                title: 'Help & Feedback',
                subtitle: 'Get help or send feedback',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HelpFeedbackPage()),
                  );
                },
                textColor: textColor,
              ),
              _buildSettingTile(
                title: 'About Us',
                subtitle: 'Learn more about our company',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AboutUsPage()),
                  );
                },
                textColor: textColor,
              ),
              SizedBox(height: 20.0),
              _buildSectionTitle('Rate Us', textColor),
              _buildSettingTile(
                title: 'Rate App',
                subtitle: 'Rate us on the app store',
                onTap: () {
                  // Implement your app store rating logic here
                },
                textColor: textColor,
              ),
              SizedBox(height: 20.0),
              _buildSectionTitle('Language', textColor),
              _buildSettingTile(
                title: 'Language',
                subtitle: 'Select your preferred language',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LanguageSelectionPage()),
                  );
                },
                textColor: textColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    required Color textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2), // Shadow position
          ),
        ],
      ),
      child: ListTile(
        title: Text(title, style: TextStyle(color: textColor)),
        subtitle: Text(subtitle, style: TextStyle(color: textColor.withOpacity(0.7))),
        trailing: trailing,
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      ),
    );
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final textColor = intialBlack;

        return AlertDialog(
          title: Text('Logout', style: TextStyle(color: textColor)),
          content: Text('Are you sure you want to log out?', style: TextStyle(color: textColor)),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: textColor)),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text('Logout', style: TextStyle(color: textColor)),
              onPressed: () {
                // Handle logout action here
                Navigator.of(context).pop(); // Close the dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => EmailPasswordAuth()), // Navigate to your EmailPasswordAuth class
                );
              },
            ),
          ],
          backgroundColor: Colors.white,
        );
      },
    );
  }
}

class PrivacySettingsPage extends StatelessWidget {
  final Color textColor;

  PrivacySettingsPage(this.textColor);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Settings',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: 20.0),
            // Add detailed privacy settings options here
          ],
        ),
      ),
    );
  }
}


  Widget _buildPasswordInputField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
      ),
    );
  }
