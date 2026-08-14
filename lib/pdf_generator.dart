import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart'; // Package to open files
import 'package:cloud_firestore/cloud_firestore.dart';

class PdfGenerator extends StatefulWidget {
  @override
  _PdfGeneratorState createState() => _PdfGeneratorState();
}

class _PdfGeneratorState extends State<PdfGenerator> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate PDF with organization email and admin details
  Future<void> generatePdf(String organizationEmail, String adminName, String adminEmail, String adminContact) async {
    // Fetch entries from Firestore
    final entries = await fetchEntries(organizationEmail);

    final pdf = pw.Document();
    pw.Font? ttf;
    print(entries);

    try {
      // Load custom font
      final fontData = await rootBundle.load("assets/fonts/OpenSans_SemiCondensed-Regular.ttf");
      ttf = pw.Font.ttf(fontData);
    } catch (e) {
      print("Error loading font: $e");
      return; // Exit if font cannot be loaded
    }

    // Add a page to the PDF with organization and admin details
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          if (ttf == null) {
            print("Font is null");
            return []; // Return an empty list if font is null
          }

          return [
            // Header Section
            pw.Header(
              level: 0,
              child: pw.Center(
                child: pw.Text(
                  '${organizationEmail} Entry Report',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, font: ttf),
                ),
              ),
            ),
            pw.Text('Organization Email: $organizationEmail',
                style: pw.TextStyle(fontSize: 18, font: ttf)),
            pw.Text('Admin: $adminName, Email: $adminEmail, Contact: $adminContact',
                style: pw.TextStyle(fontSize: 14, font: ttf)),
            pw.SizedBox(height: 20),

            // Table Section with fetched entries
            pw.TableHelper.fromTextArray(
              context: context,
              headers: ['Entry No', 'Name', 'Email', 'Date & Time', 'Organization', 'Purpose', 'Vehicle Number'],
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
              headerHeight: 25,
              cellHeight: 40,
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerLeft,
                5: pw.Alignment.centerLeft,
                6: pw.Alignment.centerLeft,
              },
              cellStyle: pw.TextStyle(font: ttf, fontSize: 12),
              headerStyle: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, font: ttf),
              data: entries.map((entry) {
                return [
                  entry['EntryNo']?.toString() ?? '',
                  entry['Name'] ?? '',
                  entry['Email'] ?? '',
                  entry['DateTime'] ?? '',
                  entry['Organization'] ?? '',
                  entry['Purpose'] ?? '',
                  entry['VehicleNumber'] ?? '' // Vehicle Number included
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 20),
          ];
        },
      ),
    );

    // Save the PDF and open it for the user
    try {
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/organization_report.pdf");
      await file.writeAsBytes(await pdf.save());
      print("PDF Saved: ${file.path}");

      // Open the saved PDF file
      OpenFile.open(file.path);
    } catch (e) {
      print("Error saving PDF: $e");
    }
  }

  // Fetch entries from Firestore based on organization email
  Future<List<Map<String, dynamic>>> fetchEntries(String organizationEmail) async {
    try {
      // Get reference to the Firestore collection for the given organization email
      final snapshot = await FirebaseFirestore.instance
          .collection('Organizations') // Main collection
          .doc(organizationEmail) // Document using OrgEmail
          .collection('DATA') // Subcollection named 'DATA'
          .orderBy('DateTime', descending: true) // Order entries by DateTime
          .get();

      // Map the documents to a list of maps for further processing
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print("Error fetching entries: $e");
      return [];
    }
  }

  // Fetch organization and admin details, and generate PDF
  Future<void> fetchAndGeneratePdf() async {
    User? user = _auth.currentUser;
    if (user != null) {
      String userEmail = user.email ?? 'unknown@example.com';

      // Fetch organization details using OrgEmail from Firestore
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('Organizations') // Assuming there's a collection for users
          .doc(userEmail) // Use user's email as document ID
          .get();

      if (snapshot.exists) {
        // Extract data from snapshot
        Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;

        // Store organization and admin details
        String organizationEmail = data?['Org Email'] ?? 'Unknown Organization Email';
        String adminName = data?['Org Admin Name'] ?? 'Admin';
        String adminEmail = data?['AdminEmail'] ?? userEmail;
        String adminContact = data?['Org Admin Phone number'] ?? '+123-456-7890';

        // Generate the PDF with fetched data
        await generatePdf(
          organizationEmail,
          adminName,
          adminEmail,
          adminContact,
        );
      } else {
        print("User document does not exist");
      }
    } else {
      print("No user logged in");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Generator'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: fetchAndGeneratePdf,
          child: Text('Generate PDF'),
        ),
      ),
    );
  }
}
