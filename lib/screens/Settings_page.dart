import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart'; // Ensure Get is imported for theme management
import 'package:url_launcher/url_launcher.dart';
import '../Authentication/login_auth.dart'; // Import your EmailPasswordAuth class here
import 'package:firebase_auth/firebase_auth.dart';
// Main Settings Page
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

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
      _darkModeEnabled = prefs.getBool('darkModeEnabled') ?? false;

      // Apply the saved theme preference
      Get.changeTheme(_darkModeEnabled ? ThemeData.dark() : ThemeData.light());
    });
  }

  // Save user settings
  void _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
    await prefs.setBool('darkModeEnabled', _darkModeEnabled);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('General'),
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
              ),
              _buildSettingTile(
                title: 'Dark Mode',
                subtitle: 'Enable dark mode for better night-time viewing',
                trailing: Switch(
                  value: _darkModeEnabled,
                  onChanged: (value) {
                    setState(() {
                      _darkModeEnabled = value;
                      _saveSettings();
                      // Apply dark mode preference
                      Get.changeTheme(_darkModeEnabled ? ThemeData.dark() : ThemeData.light());
                    });
                  },
                ),
              ),
              SizedBox(height: 20.0),
              _buildSectionTitle('Account'),
              _buildSettingTile(
                title: 'Privacy',
                subtitle: 'Manage your privacy settings',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PrivacySettingsPage()),
                  );
                },
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
              ),
              _buildSettingTile(
                title: 'Logout',
                subtitle: 'Sign out of your account',
                onTap: () {
                  _showLogoutConfirmationDialog();
                },
              ),
              SizedBox(height: 20.0),
              _buildSectionTitle('About'),
              _buildSettingTile(
                title: 'Help & Feedback',
                subtitle: 'Get help or send feedback',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HelpFeedbackPage()),
                  );
                },
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
              ),
              SizedBox(height: 20.0),
              _buildSectionTitle('Rate Us'),
              _buildSettingTile(
                title: 'Rate App',
                subtitle: 'Rate us on the app store',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RateAppPage()),
                  );
                },
              ),
              SizedBox(height: 20.0),
              _buildSectionTitle('Language'),
              _buildSettingTile(
                title: 'Language',
                subtitle: 'Select your preferred language',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LanguageSelectionPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
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
        title: Text(title),
        subtitle: Text(subtitle),
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
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text('Logout'),
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
        );
      },
    );
  }
}

class PrivacySettingsPage extends StatelessWidget {
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
                color: Colors.black87,
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

class ChangePasswordScreen extends StatefulWidget {
  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _changePassword(String currentPassword, String newPassword) async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        // Re-authenticate the user
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );

        await user.reauthenticateWithCredential(credential);

        // Update password
        await user.updatePassword(newPassword);

        // Sign out after changing the password
        await _auth.signOut();

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Password changed successfully. Please log in again."),
          backgroundColor: Colors.green,
        ));

        // Navigate to LoginAuth page
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>EmailPasswordAuth()));
      }
    } on FirebaseAuthException catch (e) {
      String message;
      Color backgroundColor;

      switch (e.code) {
        case 'wrong-password':
          message = 'The current password is incorrect.';
          backgroundColor = Colors.red;
          break;
        case 'weak-password':
          message = 'The new password is too weak.';
          backgroundColor = Colors.red;
          break;
        case 'requires-recent-login':
          message = 'Please log in again and try changing the password.';
          backgroundColor = Colors.red;
          break;
        default:
          message = 'An unexpected error occurred. Please try again.';
          backgroundColor = Colors.red;
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("An error occurred. Please try again."),
        backgroundColor: Colors.red,
      ));
    }
  }

  bool _validateAndSave() {
    final form = _formKey.currentState;
    if (form != null && form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Change Password')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _currentPasswordController,
                decoration: InputDecoration(labelText: 'Current Password'),
                obscureText: true,
                validator: (value) =>
                value!.isEmpty ? 'Please enter your current password' : null,
              ),
              TextFormField(
                controller: _newPasswordController,
                decoration: InputDecoration(labelText: 'New Password'),
                obscureText: true,
                validator: (value) =>
                value!.isEmpty ? 'Please enter a new password' : null,
              ),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(labelText: 'Confirm New Password'),
                obscureText: true,
                validator: (value) {
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () async {

                  if (_validateAndSave()) {
                    await _changePassword(
                      _currentPasswordController.text,
                      _newPasswordController.text,
                    );
                  }
                },
                child: Text('Change Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




class HelpFeedbackPage extends StatefulWidget {
  @override
  _HelpFeedbackPageState createState() => _HelpFeedbackPageState();
}

class _HelpFeedbackPageState extends State<HelpFeedbackPage> {
  final TextEditingController _feedbackController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help & Feedback'),

      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Lottie Animation
              Container(
                height: 200,
                width: 200,
                child: Lottie.asset(
                  'assets/animations/Animation - 1725698832318.json', // Replace with your animation file
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: 30),
              // Help & Feedback Text
              Text(
                'We value your feedback!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Please let us know if you have any questions or feedback about the app.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: 30),
              // Feedback Input Field
              TextField(
                controller: _feedbackController,
                maxLines: 5,

                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Your Feedback',
                  hintText: 'Enter your feedback here...',
                ),
              ),
              SizedBox(height: 30),
              // Submit Button
              ElevatedButton(

                onPressed: () {
                  // Handle feedback submission
                  final feedback = _feedbackController.text;
                  if (feedback.isNotEmpty) {
                    // You can send the feedback to a server or handle it as needed
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Thank you for your feedback!'),
                      ),
                    );
                    _feedbackController.clear();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please enter your feedback.'),
                      ),
                    );
                  }
                },
                child: Text('Submit Feedback',style: TextStyle(color: Colors.white,),),
                style: ElevatedButton.styleFrom(

                  backgroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 16,),
                  textStyle: TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AboutUsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About Us',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 20.0),
            Text(
              'Welcome to ClickNGo, your ultimate solution for managing and tracking campus activities. Our mission is to streamline your experience and ensure your security while providing real-time updates and notifications.',
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 20.0),



          ],
        ),
      ),
    );
  }
}


class LanguageSelectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Language Selection',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 20.0),
            // Add language selection options here
          ],
        ),
      ),
    );
  }
}
class RateAppPage extends StatelessWidget {
  final String _playStoreUrl = 'https://play.google.com/store/apps/details?id=com.yourcompany.yourapp';

  Future<void> _launchURL() async {
    if (await canLaunch(_playStoreUrl)) {
      await launch(_playStoreUrl);
    } else {
      throw 'Could not launch $_playStoreUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Rate Us')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/animations/rating_animation.json', height: 200), // Ensure you have the Lottie asset
            SizedBox(height: 40.0),
            Text(
              'If you enjoy using our app, please take a moment to rate us on the Play Store.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18.0, color: Colors.black87),
            ),
            SizedBox(height: 40.0),
            ElevatedButton(
              onPressed: _launchURL,
              child: Text('Rate Now'),
            ),
          ],
        ),
      ),
    );
  }
}
