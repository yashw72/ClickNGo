import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart'; // Ensure you have this package in your pubspec.yaml
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class HODBoundaryBreachesPage extends StatefulWidget {
  final String hodEmail;

  const HODBoundaryBreachesPage({Key? key, required this.hodEmail}) : super(key: key);

  @override
  State<HODBoundaryBreachesPage> createState() => _HODBoundaryBreachesPageState();
}

class _HODBoundaryBreachesPageState extends State<HODBoundaryBreachesPage> {
  late Stream<QuerySnapshot> _breachesStream;
  bool _showAnimation = true; // Controls whether to show the animation or not
  String branch = "";

  @override
  void initState() {
    super.initState();
    _fetchBranchForHOD();
    // Show animation for 3 seconds and then load breaches
    _loadBreachesAfterDelay();
  }

  Future<void> _fetchBranchForHOD() async {
    try {
      DocumentReference hodDoc = FirebaseFirestore.instance.collection('Users').doc(widget.hodEmail);
      DocumentSnapshot userDoc = await hodDoc.get();

      if (userDoc.exists) {
        setState(() {
          branch = userDoc['Branch'] ?? "";
        });

        // Initialize the stream to fetch the boundary breaches data from Firestore
        _breachesStream = FirebaseFirestore.instance
            .collection('HOD')
            .doc(widget.hodEmail)
            .collection('BREACHES')
            .orderBy('datetime',descending: true)

            .snapshots();
      } else {
        print('HOD email not found');
      }
    } catch (e) {
      print('Error fetching branch: $e');
    }
  }

  Future<void> _loadBreachesAfterDelay() async {
    await Future.delayed(Duration(seconds: 3)); // 3-second delay
    if (mounted) {
      setState(() {
        _showAnimation = false; // Switch to show the breaches list
      });
    }
  }

  Future<void> _generateAndDownloadPDF(List<QueryDocumentSnapshot> breachesDocs) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: pw.EdgeInsets.all(8.0),
                    child: pw.Text('Faculty Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.all(8.0),
                    child: pw.Text('Date Crossed', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.all(8.0),
                    child: pw.Text('Time Crossed', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
              ...breachesDocs.map(
                    (doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8.0),
                        child: pw.Text(data['facultyName']),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8.0),
                        child: pw.Text(data['dateCrossed']),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8.0),
                        child: pw.Text(data['timeCrossed']),
                      ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Boundary_Breaches_Report.pdf');
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
                'Fetching Boundary Breaches',
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
        stream: _breachesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error fetching breaches: ${snapshot.error}',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No boundary breaches found.',
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
            );
          }

          final breachesDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: breachesDocs.length,
            itemBuilder: (context, index) {
              final doc = breachesDocs[index];
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
                      'Faculty Name: ${data['facultyName']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Date & Time Crossed: ${data['datetime']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    SizedBox(height: 4),

                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final snapshot = await FirebaseFirestore.instance
              .collection('HOD')
              .doc(widget.hodEmail)
              .collection('BREACHES')
              .orderBy('datetime', descending: true)
              .get();

          if (snapshot.docs.isNotEmpty) {
            await _generateAndDownloadPDF(snapshot.docs);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('No breaches data to download.')),
            );
          }
        },
        child: Icon(Icons.download),
        tooltip: 'Download PDF',
      ),
    );
  }
}