import 'dart:developer';
import 'package:clickngo/root_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DataScreen extends StatefulWidget {
  final String email;

  DataScreen({super.key, required this.email});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  TextEditingController nametc = TextEditingController();
  TextEditingController rolltc = TextEditingController();
  TextEditingController vehtc = TextEditingController();

  Future<void> addData(String name, int no, String vehno) async {
    if (name.isEmpty || no == 0 || vehno.isEmpty) {
      log("Enter required fields correctly");
    } else {
      await FirebaseFirestore.instance.collection("Users").doc(widget.email).set({
        "Name": name,
        "Id": no,
        "Vehicle no": vehno,
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
            constraints: BoxConstraints(maxWidth: 600),  // Set a max width for better layout
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
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    addData(nametc.text, int.tryParse(rolltc.text) ?? 0, vehtc.text);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RootPage(email: widget.email),
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
