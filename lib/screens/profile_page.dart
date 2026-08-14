import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaveSuccessful = false;
  bool _hasError = false; // Track if there was an error

  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _idController = TextEditingController();
  TextEditingController _vehicleNoController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    User? user = _auth.currentUser;

    if (user != null) {
      try {
        DocumentSnapshot userDoc = await _firestore.collection('Users').doc(user.email).get();

        if (userDoc.exists) {
          setState(() {
            _nameController.text = userDoc['Name'] ?? '';
            _emailController.text = userDoc['email'] ?? '';
            _idController.text = userDoc['Id']?.toString() ?? '';
            _vehicleNoController.text = userDoc['Vehicle no'] ?? '';
            _isLoading = false;
          });
        } else {
          print("Document does not exist");
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        print("Error fetching document: $e");
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _saveUserProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _isLoading = true;
        _isSaveSuccessful = false;
        _hasError = false; // Reset error state
      });

      try {
        await _firestore.collection('Users').doc(user.email).update({
          'Name': _nameController.text,
          'email': _emailController.text,
          'Id': _idController.text,
          'Vehicle no': _vehicleNoController.text,
        });

        setState(() {
          _isEditing = false;
          _isSaveSuccessful = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully!')),
        );
      } catch (e) {
        print("Error updating document: $e");
        setState(() {
          _isSaveSuccessful = false;
          _hasError = true; // Set error state
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile. Please try again.')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveUserProfile();
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
          ),
        ],
      ),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()  // Show loading spinner
            : SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: 100.0,
                backgroundImage: AssetImage('assets/images/Sample_User_Icon.png'),
              ),
              SizedBox(height: 40.0),
              _buildTextField(
                controller: _nameController,
                label: 'Name',
                icon: Icons.person,
              ),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email,
              ),
              _buildTextField(
                controller: _idController,
                label: 'ID',
                icon: Icons.perm_identity,
              ),
              _buildTextField(
                controller: _vehicleNoController,
                label: 'Vehicle No',
                icon: Icons.directions_car,
              ),
              if (_isEditing)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: _saveUserProfile,
                    child: Text('Save'),
                  ),
                ),
              if (_isSaveSuccessful)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Profile updated successfully!',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              if (_hasError && !_isLoading && !_isEditing)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error updating profile. Please try again.',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(),
        ),
        enabled: _isEditing,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _idController.dispose();
    _vehicleNoController.dispose();
    super.dispose();
  }
}
