import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FunctionCallerWidget extends StatefulWidget {
  @override
  _FunctionCallerWidgetState createState() => _FunctionCallerWidgetState();
}

class _FunctionCallerWidgetState extends State<FunctionCallerWidget> {
  int callCount = 1;
  final firestore = FirebaseFirestore.instance;
  bool isLoading = false;

  // This function will perform a batch write for 500 entries.
  Future<void> batchWrite(int startIndex, int batchSize) async {
    WriteBatch batch = firestore.batch();

    for (int i = startIndex; i < startIndex + batchSize; i++) {
      final dataDocRef = firestore
          .collection('Organizations')
          .doc("gpn03@gmail.com")
          .collection('DATA')
          .doc();

      batch.set(dataDocRef, {
        'EntryNo': i,
        'Name': "parth",
        'VehicleNumber': "mh15",
        'Email': "thakkarparth793@gmail.com",
        'Organization': "gpn",
        'Purpose': "clg",
        'DateTime': DateTime.now().toString(),
      });
    }

    // Commit the batch write
    await batch.commit();
  }

  // This function will call batchWrite for 100,000 entries in batches of 500.
  Future<void> callFunction100000Times() async {
    setState(() {
      isLoading = true; // To show a loading indicator
    });

    int batchSize = 500; // Firestore batch limit
    for (int i = 0; i < 100000; i += batchSize) {
      await batchWrite(i, batchSize);  // Call batchWrite in chunks of 500
    }

    setState(() {
      isLoading = false; // Hide the loading indicator after completion
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Function Caller'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Function has been called: $callCount times'),
            SizedBox(height: 20),
            isLoading
                ? CircularProgressIndicator()  // Show loading indicator while calling the function
                : ElevatedButton(
              onPressed: callFunction100000Times,
              child: Text('Call Function 100,000 Times'),
            ),
          ],
        ),
      ),
    );
  }
}
