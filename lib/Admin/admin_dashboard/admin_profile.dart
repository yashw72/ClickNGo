import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminProfile extends StatefulWidget {
  @override
  _AdminProfileState createState() => _AdminProfileState();
}

class _AdminProfileState extends State<AdminProfile> {
  String? orgNAME;
  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaveSuccessful = false;
  bool _hasError = false; // Track if there was an error

  TextEditingController _adminNameController = TextEditingController();
  TextEditingController _orgEmailController = TextEditingController();
  TextEditingController _orgNameController = TextEditingController();
  TextEditingController _orgTypeController = TextEditingController();
  TextEditingController _adminPhoneNoController = TextEditingController();
  TextEditingController _orgAddressController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchAdminProfile();
  }

  Future<void> _fetchAdminProfile() async {
    User? admin = _auth.currentUser;

    if (admin != null) {
      try {
        DocumentSnapshot orgDoc = await _firestore.collection('Organizations').doc(admin.email).get();

        if (orgDoc.exists) {
          print("Document Data: ${orgDoc.data()}"); // Debug print to check all document data
          setState(() {
            _adminNameController.text = orgDoc['Org Admin Name'] ?? '';
            _orgEmailController.text = orgDoc['Org Email'] ?? '';
            _orgAddressController.text = orgDoc['Org Address'] ?? '';
            _orgTypeController.text = orgDoc['Org Type'] ?? '';
            _orgNameController.text = orgDoc['Org Name'] ?? '';
            _adminPhoneNoController.text = orgDoc['Org Admin Phone number'] ?? ''; // Debug print if necessary
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
    User? admin = _auth.currentUser;
    if (admin != null) {
      setState(() {
        _isLoading = true;
        _isSaveSuccessful = false;
        _hasError = false; // Reset error state
      });

      try {
        await _firestore.collection('Organizations').doc(admin.email).update({
          'Org Admin Name': _adminNameController.text,
          'Org Name': _orgNameController.text,
          'Org Email': _orgEmailController.text,
          'Org Type': _orgTypeController.text,
          'Org Admin Phone number': _adminPhoneNoController.text,
          'Org Address': _orgAddressController.text,
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
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator() // Show loading spinner
            : SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 100.0,
                    backgroundImage: AssetImage('assets/images/user_Icon.webp'),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: CircleAvatar(
                      backgroundColor: Colors.grey[200],
                      radius: 20,
                      child: IconButton(
                        icon: Icon(_isEditing ? Icons.check : Icons.edit, color: Colors.black),
                        onPressed: () {
                          if (_isEditing) {
                            _saveUserProfile(); // Save the profile and toggle to edit mode
                          } else {
                            setState(() {
                              _isEditing = true;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40.0),
              _buildTextField(
                controller: _adminNameController,
                label: 'Admin Name',
                icon: Icons.person,
              ),
              _buildTextField(
                controller: _orgEmailController,
                label: 'Organization Email',
                icon: Icons.email,
              ),
              _buildTextField(
                controller: _orgTypeController,
                label: 'Organization Type',
                icon: Icons.business,
              ),
              _buildTextField(
                controller: _orgNameController,
                label: 'Organization Name',
                icon: Icons.business,
              ),
              _buildTextField(
                controller: _orgAddressController,
                label: 'Organization Address',
                icon: Icons.location_city,
              ),
              _buildTextField(
                controller: _adminPhoneNoController,
                label: 'Admin Phone No',
                icon: Icons.mobile_friendly,
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
    _adminNameController.dispose();
    _orgNameController.dispose();
    _orgTypeController.dispose();
    _orgAddressController.dispose();
    _adminPhoneNoController.dispose();
    _orgEmailController.dispose();
    super.dispose();
  }
}
