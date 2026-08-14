import 'dart:developer';
import 'package:clickngo/FACULTY/root2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DataScreen2 extends StatefulWidget {
  final String email;

  DataScreen2({super.key, required this.email});

  @override
  State<DataScreen2> createState() => _DataScreen2State();
}

class _DataScreen2State extends State<DataScreen2> {
  TextEditingController nametc = TextEditingController();
  TextEditingController rolltc = TextEditingController();
  TextEditingController vehtc = TextEditingController();
  String? selectedBranch;

  // List of branches for the dropdown
  final List<String> branches = [
    "Computer",
    "Civil",
    "Information Tech",
    "Mechanical",
    "Automobile",
    "IDD",
    "Mechatronics"
  ];
  // Function to check geofence
  Future<String?> getHODEmailFromBranch(String branch) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final collection = firestore.collection('HOD');

      // Query documents where the 'Branch' field matches the given branch
      final querySnapshot = await collection.where('Branch', isEqualTo: branch).get();

      if (querySnapshot.docs.isNotEmpty) {
        // Assuming there is only one document per branch
        // Return the document ID which is the HOD email
        return querySnapshot.docs.first.id;
      } else {
        print('No HOD found for the branch: $branch');
        return null;
      }
    } catch (e) {
      print('Error fetching HOD email: $e');
      return null;
    }
  }

  Future<void> addData(String name, int no, String vehno, String branch) async {
    if (name.isEmpty || no == 0 || vehno.isEmpty || branch.isEmpty) {
      log("Enter required fields correctly");
    } else {
      await FirebaseFirestore.instance.collection("Users").doc(widget.email).set({
        "Name": name,
        "Id": no,
        "Vehicle no": vehno,
        "Branch": branch,
        "email": widget.email,
      }).then((value) {
        log("Data inserted");
      });
      String? hodEmail = await getHODEmailFromBranch(branch);
      await FirebaseFirestore.instance.collection("HOD").doc(hodEmail).collection("faculties").doc(name).set({
        "Name": name,
        "Id": no,
        "Vehicle no": vehno,
        "Branch": branch,
        "email": widget.email,
      }).then((value) {
        log("Data inserted");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tell us a bit about yourself!"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 60),
                Text(
                  "Enter your details",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: TextField(
                    controller: nametc,
                    decoration: InputDecoration(
                      hintText: "Enter your name",
                      suffixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: TextField(
                    controller: rolltc,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Enter your rollno / faculty number",
                      suffixIcon: Icon(Icons.numbers),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: TextField(
                    controller: vehtc,
                    decoration: InputDecoration(
                      hintText: "Enter your vehicle number",
                      suffixIcon: Icon(Icons.directions_car),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: DropdownButtonFormField<String>(
                    value: selectedBranch,
                    decoration: InputDecoration(
                      hintText: "Select your branch",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: branches.map((String branch) {
                      return DropdownMenuItem<String>(
                        value: branch,
                        child: Text(branch),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedBranch = newValue;
                      });
                    },
                  ),
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    addData(
                      nametc.text,
                      int.tryParse(rolltc.text) ?? 0,
                      vehtc.text,
                      selectedBranch ?? "",
                    );
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RootPage2(email: widget.email),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 15,
                    ),
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
    );
  }
}
