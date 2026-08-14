import 'dart:developer';
import 'package:clickngo/Users/root_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class DataScreen extends StatefulWidget {
  final String email;

  DataScreen({super.key, required this.email});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController nametc = TextEditingController();
  TextEditingController idtc = TextEditingController(); // For Employee ID or Student Roll No.
  TextEditingController phonetc = TextEditingController(); // Phone number controller
  TextEditingController vehtc = TextEditingController(); // Vehicle number controller
  String? selectedRole; // Field for dropdown selection
  String selectedCountryCode = '+91'; // Initialize with default value

  Future<void> addData(String name, int no, String phoneno, String? vehno, String? role) async {
    if (name.isEmpty || phoneno.isEmpty || role == null || role.isEmpty) {
      log("Enter required fields correctly");
    } else {
      Map<String, dynamic> userData = {
        "Name": name,
        "Phone": phoneno,
        "Role": role,
        "email": widget.email,
      };

      // Add ID (Roll No. or Employee ID) if the role is Student or Employee
      if ((role == "Student" || role == "Employee") && no != 0) {
        userData["Id"] = no;
      }

      // Add Vehicle number if provided (required for Delivery Person)
      if (role == "Delivery Person" && (vehno == null || vehno.isEmpty)) {
        log("Vehicle number is required for Delivery Person");
        return;
      } else if (vehno != null && vehno.isNotEmpty) {
        userData["Vehicle no"] = vehno;
      }

      await FirebaseFirestore.instance.collection("Users").doc(widget.email).update(userData).then((value) {
        log("Data inserted");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tell us a bit about yourself!"),
        backgroundColor: Colors.white, // Customize app bar color
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  SizedBox(height: 15),
                  Lottie.asset(
                    'assets/animations/Animation - 1726565840941.json', // Path to your JSON file
                    width: 300,
                    height: 200,

                  ),

                  Text(
                    "Enter your details",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // Accent color for the header
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Please fill in the details based on your role.",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Colors.grey[600], // Subtle subtitle color
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),

                  // Role selection dropdown
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: InputDecoration(
                      labelText: "Select your role",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: ["Student", "Delivery Person", "Resident", "Employee", "Others"]
                        .map((role) => DropdownMenuItem<String>(
                      value: role,
                      child: Text(role),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select your role';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 20),

                  // Name field for all roles
                  TextFormField(
                    controller: nametc,
                    decoration: InputDecoration(
                      hintText: "Enter your name",
                      labelText: "Name",
                      suffixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),

                  // ID field for Students and Employees
                  if (selectedRole == "Student" || selectedRole == "Employee")
                    TextFormField(
                      controller: idtc,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: selectedRole == "Student"
                            ? "Enter your roll number"
                            : "Enter your employee ID",
                        labelText: selectedRole == "Student"
                            ? "Roll Number"
                            : "Employee ID",
                        suffixIcon: Icon(Icons.numbers),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (selectedRole == "Student" || selectedRole == "Employee") {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your ID';
                          }
                        }
                        return null;
                      },
                    ),
                  SizedBox(height: 10),

                  // Phone number field with country code dropdo
                  Stack(
                    children: [
                      TextFormField(
                        controller: phonetc,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: "Enter your phone number",
                          labelText: "Phone Number",
                          prefixIcon: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedCountryCode,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedCountryCode = newValue!;
                                  });
                                },
                                items: <String>['+91', '+1', '+44', '+61', '+81', '+49']
                                    .map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          suffixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          } else if (value.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(value)) {
                            return 'Please enter a valid 10-digit phone number';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 10),

                  // Vehicle number field (optional for all roles except Delivery Person)
                  TextFormField(
                    controller: vehtc,
                    decoration: InputDecoration(
                      hintText: selectedRole == "Delivery Person"
                          ? "Enter your vehicle number (required)"
                          : "Enter your vehicle number (optional)",
                      labelText: "Vehicle Number",
                      suffixIcon: Icon(Icons.directions_car),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (selectedRole == "Delivery Person" && (value == null || value.isEmpty)) {
                        return 'Vehicle number is required for Delivery Person';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 30),

                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        // Call the addData function if all validations are passed
                        addData(
                          nametc.text,
                          int.tryParse(idtc.text) ?? 0,
                          phonetc.text,
                          vehtc.text.isNotEmpty ? vehtc.text : null,
                          selectedRole,
                        );

                        // Navigate to RootPage
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RootPage(email: widget.email),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black, // Button color
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Submit",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}