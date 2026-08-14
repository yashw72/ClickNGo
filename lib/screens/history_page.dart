import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart'; // Ensure you have this package in your pubspec.yaml

class HistoryPage extends StatefulWidget {
  final String email; // Email passed to retrieve the user's history

  const HistoryPage({Key? key, required this.email}) : super(key: key);

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Stream<QuerySnapshot> _historyStream;
  bool _showAnimation = true; // Controls whether to show the animation or not

  @override
  void initState() {
    super.initState();
    // Initialize the stream to fetch the history data from Firestore
    _historyStream = FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.email)
        .collection('History')
        .orderBy('DateTime', descending: true) // Order by date and time
        .snapshots();

    // Show animation for 3 seconds and then load history
    _loadHistoryAfterDelay();
  }

  Future<void> _loadHistoryAfterDelay() async {
    await Future.delayed(Duration(seconds: 3)); // 3-second delay
    if (mounted) {
      setState(() {
        _showAnimation = false; // Switch to show the history
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _showAnimation
          ? Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animations/Animation - 1725686193709.json', // Path to your JSON file
                width: 270,
                height: 200,
              ),
              const Text(
                'Fetching your History',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      )
          : StreamBuilder<QuerySnapshot>(
        stream: _historyStream,
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
                      offset: Offset(0, 4), // changes position of shadow
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Organization: ${data['Organization']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Date and Time: ${data['DateTime']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Purpose: ${data['Purpose']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
