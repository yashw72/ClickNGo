import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'admin_dashboard/qr_generation.dart';

class OrgRegistration extends StatefulWidget {
  const OrgRegistration({super.key});

  @override
  State<OrgRegistration> createState() => _OrgRegistrationState();
}

class _OrgRegistrationState extends State<OrgRegistration> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController name = TextEditingController();
  final TextEditingController add = TextEditingController();
  final TextEditingController admin_name = TextEditingController();
  final TextEditingController admin_phone = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  String selectedType = "Company";
  final List<String> orgTypes = [
    "Company",
    "NGO",
    "Educational",
    "Government",
    "Residential",
    "Other"
  ];
  String selectedCountryCode = "+91";
  final List<String> countryCodes = [
    "+91",
    "+44",
    "+49",
    "+33",
    "+34",
    "+39",
    "+61",
    "+81",
    "+82",
    "+86",
    "+1",
  ];
  String orgemail = "";
  String orgname = "";
  String qrdata = "";
  String orgcode = "";
  String _errorMessage = '';

  @override
  void dispose() {
    name.dispose();
    add.dispose();
    admin_name.dispose();
    admin_phone.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void generateCode() {
    var uuid = Uuid();
    orgcode = uuid.v4();
    orgemail = emailController.text.trim();
    qrdata =
        'https://clickngoform.netlify.app/?organization=$orgname&organizationid=$orgcode&organizationemail=$orgemail';
    log("Generated QR data: $qrdata");
  }

  Future<void> addData(String name, String uuid, String add, String type,
      String adm_name, String adm_phone, String email) async {
    try {
      await FirebaseFirestore.instance
          .collection("Organizations")
          .doc(email)
          .set({
        "Org Name": name,
        "Org Address": add,
        "Org Type": type,
        "Org Admin Name": adm_name,
        "Org Admin Phone number": adm_phone,
        "Org UUID": uuid,
        "Org Email": email,
        "qrdata": qrdata,
      });

      log("Data entered successfully");
    } catch (e) {
      log("Error adding data to Firestore: $e");
      if (Get.isSnackbarOpen) {
        Get.closeCurrentSnackbar();
      }
      Get.rawSnackbar(
        title: "Oops",
        message: "We have some issue registering you. Please try again later.",
        isDismissible: false,
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
        shouldIconPulse: true,
      );
      throw e; // Rethrow to handle in the calling function
    }
  }

  Future<void> storeUserDetails(User user, String role) async {
    // Storing details in Firestore using the user's existing UID
    FirebaseFirestore.instance.collection('loggedUsers').doc(user.uid).set({
      'email': user.email,
      'role': role,
    });

    // Storing details locally using shared_preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', user.email!);
    await prefs.setString('role', role);
  }

  Future<void> registerOrganization() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
        log("User registered: ${userCredential.user?.uid}");

        orgname = name.text.trim();
        generateCode();

        await addData(
          orgname,
          orgcode,
          add.text.trim(),
          selectedType,
          admin_name.text.trim(),
          selectedCountryCode + " " + admin_phone.text.trim(),
          emailController.text.trim(),
        );

        Get.rawSnackbar(
          title: "Registration Successful!",
          message: "You have registered successfully",
          isDismissible: false,
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
          shouldIconPulse: true,
        );

        User? user = userCredential.user;

        await storeUserDetails(user!, 'admin');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => QR(
                    qrdata: qrdata,
                    email: emailController.text.trim(),
                  )),
        );
      } on FirebaseAuthException catch (e) {
        log("Firebase Auth Error: ${e.message}");
        setState(() {
          _errorMessage = e.message ?? 'An error occurred';
        });
      } on FirebaseException catch (e) {
        log("Firebase Error: ${e.message}");
        setState(() {
          _errorMessage = e.message ?? 'An error occurred';
        });
      } catch (e) {
        log("General Error: $e");
        setState(() {
          _errorMessage = 'An unexpected error occurred. Please try again.';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      log("Form validation failed");
    }
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 30),
              // Organization Name
              TextFormField(
                controller: name,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Organization Name',
                  prefixIcon: Icon(Icons.business, color: Colors.black),
                  hintText: 'Enter the name of your organization',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the organization name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 25),
              // Organization Address
              TextFormField(
                controller: add,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.location_on, color: Colors.black),
                  border: OutlineInputBorder(),
                  labelText: 'Organization Address',
                  hintText: 'Enter the address of your organization',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the organization address';
                  }
                  return null;
                },
              ),
              SizedBox(height: 25),
              // Organization Type
              DropdownButtonFormField<String>(
                value: selectedType,
                items: orgTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedType = newValue!;
                  });
                },
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.category, color: Colors.black),
                  border: OutlineInputBorder(),
                  labelText: 'Organization Type',
                ),
              ),
              SizedBox(height: 25),
              // Admin Name
              TextFormField(
                controller: admin_name,
                decoration: InputDecoration(
                  prefixIcon:
                      Icon(Icons.account_circle_outlined, color: Colors.black),
                  border: OutlineInputBorder(),
                  labelText: 'Admin Name',
                  hintText: "Enter Admin name",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the admin name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 25),
              // Admin Phone Number with Country Code
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: selectedCountryCode,
                      items: countryCodes.map((String code) {
                        return DropdownMenuItem<String>(
                          value: code,
                          child: Text(code),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedCountryCode = newValue!;
                        });
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Country Code',
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: admin_phone,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Admin Phone Number',
                        hintText: "Enter phone number",
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the admin phone number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 25),
              // Email
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.email, color: Colors.black),
                  border: OutlineInputBorder(),
                  labelText: 'Email',
                  hintText: "Enter Email",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              SizedBox(height: 25),
              // Password
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock, color: Colors.black),
                  border: OutlineInputBorder(),
                  labelText: 'Password',
                  hintText: "Enter Password",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null;
                },
              ),
              SizedBox(height: 25),
              // Display Error Message if Any
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              SizedBox(height: 20),
              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : registerOrganization,
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text(
                        'Register',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Organization Registration"),
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: _buildForm(),
    );
  }
}
