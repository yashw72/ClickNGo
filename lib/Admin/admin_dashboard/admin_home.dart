import 'package:clickngo/Component/color.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../Component/important_functions.dart';

class AdminHome extends StatefulWidget {
  final String email;
  const AdminHome({Key? key, required this.email}) : super(key: key);

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  Stream<QuerySnapshot>? _adminhistoryStream;
  String? orgname;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchAndInitializeStream();
  }

  Future<void> _fetchAndInitializeStream() async {
    User? admin = _auth.currentUser;
    if (admin != null) {
      final orgSnapshot = await _firestore
          .collection('Organizations')
          .where('Org Email', isEqualTo: widget.email)
          .get();

      if (orgSnapshot.docs.isNotEmpty) {
        orgname = orgSnapshot.docs.first.id;
        setState(() {
          _adminhistoryStream = _firestore
              .collection('Organizations')
              .doc(orgname)
              .collection('DATA')
              .orderBy("DateTime", descending: true)
              .snapshots();
        });
      } else {
        setState(() {
          _adminhistoryStream = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: _adminhistoryStream == null
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
        stream: _adminhistoryStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error fetching history: ${snapshot.error}',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No history available.',
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
            );
          }

          final historyDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: historyDocs.length,
            itemBuilder: (context, index) {
              final doc = historyDocs[index];
              final data = doc.data() as Map<String, dynamic>;

              return _buildEntryContainer(context, doc.id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildEntryContainer(BuildContext context, String docId, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                child: IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    _showEditDialog(context, docId, data);
                  },
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  _deleteEntry(docId);
                },
              ),
            ],
          ),
          SizedBox(height: 8),
          _buildDetailsCard(data),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Email: ${data['Email']}',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          SizedBox(height: 8),
          Text(
            'Date and Time: ${data['DateTime']}',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          SizedBox(height: 8),
          Text(
            'Organization: ${data['Organization']}',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          SizedBox(height: 8),
          Text(
            'Purpose: ${data['Purpose']}',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, String docId, Map<String, dynamic> data) {
    TextEditingController entryNoController = TextEditingController(text: data['EntryNo'].toString());
    TextEditingController emailController = TextEditingController(text: data['Email']);
    TextEditingController dateTimeController = TextEditingController(text: data['DateTime']);
    TextEditingController organizationController = TextEditingController(text: data['Organization']);
    TextEditingController purposeController = TextEditingController(text: data['Purpose']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 16,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Edit Entry',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildTextField(entryNoController, 'Entry No', Icons.confirmation_number),
                  _buildTextField(emailController, 'Email', Icons.email),
                  _buildTextField(dateTimeController, 'Date and Time', Icons.calendar_today),
                  _buildTextField(organizationController, 'Organization', Icons.business),
                  _buildTextField(purposeController, 'Purpose of Visit', Icons.description),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildDialogButton(context, 'Cancel', Colors.redAccent, () {
                        Navigator.of(context).pop();
                      }),
                      _buildDialogButton(context, 'Save', Colors.green, () async {
                        await FirebaseFirestore.instance
                            .collection('Organizations')
                            .doc(orgname)
                            .collection('DATA')
                            .doc(docId)
                            .update({
                          'EntryNo': int.parse(entryNoController.text),
                          'Email': emailController.text,
                          'DateTime': dateTimeController.text,
                          'Organization': organizationController.text,
                          'Purpose': purposeController.text,
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Entry updated successfully')),
                        );

                        Navigator.of(context).pop();
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.black54),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: primaryColor),
          ),
          labelStyle: TextStyle(color: primaryColor),
        ),
      ),
    );
  }

  Widget _buildDialogButton(BuildContext context, String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

  Future<void> _deleteEntry(String docId) async {
    await FirebaseFirestore.instance
        .collection('Organizations')
        .doc(orgname)
        .collection('DATA')
        .doc(docId)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Entry deleted successfully')),
    );
  }
}
