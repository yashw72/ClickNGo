import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage3 extends StatefulWidget {
  @override
  _ProfilePageState3 createState() => _ProfilePageState3();
}

class _ProfilePageState3 extends State<ProfilePage3> {
  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaveSuccessful = false;
  bool _hasError = false;

  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _idController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _vehicleNoController = TextEditingController();
  TextEditingController _branchController = TextEditingController(); // Added branch controller

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
            _phoneController.text = userDoc['Phone'] ?? '';
            _vehicleNoController.text = userDoc['Vehicle no'] ?? '';
            _branchController.text = userDoc['Branch'] ?? ''; // Fetch branch

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
        _hasError = false;
      });

      try {
        Map<String, dynamic> updateData = {
          'Name': _nameController.text,
          'email': _emailController.text,
          'Phone': _phoneController.text,
          'Branch': _branchController.text, // Include branch
        };

        // Add ID if it exists
        if (_idController.text.isNotEmpty) {
          updateData['Id'] = _idController.text;
        }

        // Always include Vehicle No
        if (_vehicleNoController.text.isNotEmpty) {
          updateData['Vehicle no'] = _vehicleNoController.text;
        }

        await _firestore.collection('Users').doc(user.email).update(updateData);

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
          _hasError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile.')),
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
            ? CircularProgressIndicator()
            : SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: 100.0,
                backgroundImage: AssetImage('assets/images/Sample_User_Icon.png'),
              ),
              SizedBox(height: 20.0),
              _buildTextField(
                controller: _nameController,
                label: 'Name',
                icon: Icons.person,
                enabled: _isEditing,
              ),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email,
                enabled: _isEditing,
              ),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone',
                icon: Icons.phone,
                enabled: _isEditing,
              ),
              _buildTextField(
                controller: _branchController,
                label: 'Branch',
                icon: Icons.business,
                enabled: _isEditing,
              ),
              if (_idController.text.isNotEmpty)
                _buildTextField(
                  controller: _idController,
                  label: 'ID',
                  icon: Icons.perm_identity,
                  enabled: _isEditing,
                ),
              _buildTextField(
                controller: _vehicleNoController,
                label: 'Vehicle No',
                icon: Icons.directions_car,
                enabled: _isEditing,
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
                    'Error occurred while saving.',
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
    bool enabled = true,
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
        enabled: enabled,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _idController.dispose();
    _phoneController.dispose();
    _vehicleNoController.dispose();
    _branchController.dispose(); // Dispose branch controller
    super.dispose();
  }
}