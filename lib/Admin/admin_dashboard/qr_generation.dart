import 'dart:typed_data';
import 'dart:ui';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin_root_page.dart';

class QR extends StatefulWidget {
  final String qrdata;
  final String email;

  const QR({super.key, required this.qrdata, required this.email});

  @override
  State<QR> createState() => _QRState();
}

class _QRState extends State<QR> {
  final GlobalKey _globalKey = GlobalKey();

  Future<Map<String, dynamic>> _fetchOrganizationDetails() async {
    try {
      // Fetch organization details from Firestore
      final docSnapshot = await FirebaseFirestore.instance
          .collection('Organizations') // Use the correct collection name
          .doc(widget.email) // Document ID is the user's email
          .get();

      if (docSnapshot.exists) {
        return docSnapshot.data() as Map<String, dynamic>;
      } else {
        print("Document does not exist");
        return {};
      }
    } catch (e) {
      print("Error fetching details: $e");
      return {};
    }
  }

  Future<Uint8List> generatePdfWithQr(String qrData) async {
    final pdf = pw.Document();
    pw.Font? ttf;

    try {
      // Load custom font
      final fontData = await rootBundle.load("assets/fonts/OpenSans_SemiCondensed-Regular.ttf");
      ttf = pw.Font.ttf(fontData);
    } catch (e) {
      print("Error loading font: $e");
    }

    // Fetch organization details
    final details = await _fetchOrganizationDetails();
    final organizationName = details['Org Name'] ?? 'Unknown Organization';
    final adminName = details['Org Admin Name'] ?? 'Admin';
    final adminEmail = details['Org Email'] ?? widget.email;
    final adminContact = details['Org Admin Phone number'] ?? '+123-456-7890';

    // Generate QR code as an image
    final qrImageData = await _captureWidgetAsImage();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header Section
            pw.Header(
              level: 0,
              child: pw.Center(
                child: pw.Text(
                  'QR Code Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    font: ttf,
                  ),
                ),
              ),
            ),
            pw.SizedBox(height: 20),

            // Organization and Admin Details Section
            pw.Text(
              'Organization: $organizationName',
              style: pw.TextStyle(fontSize: 18, font: ttf),
            ),
            pw.Text(
              'Admin: $adminName, Email: $adminEmail, Contact: $adminContact',
              style: pw.TextStyle(fontSize: 16, font: ttf),
            ),
            pw.SizedBox(height: 20),

            // "SCAN ME" Text Section
            pw.Center(
              child: pw.Text(
                'SCAN ME',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  font: ttf,
                  color: PdfColors.black,
                ),
              ),
            ),
            pw.SizedBox(height: 20),

            // QR Code Section
            pw.Center(
              child: pw.Image(
                pw.MemoryImage(qrImageData),
                width: 200,
                height: 200,
              ),
            ),
            pw.SizedBox(height: 20),

            // "Thank You!" Text Section
            pw.Center(
              child: pw.Text(
                'Thank You!',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  font: ttf,
                ),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> _captureWidgetAsImage() async {
    RenderRepaintBoundary boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _downloadPdf() async {
    final pdfData = await generatePdfWithQr(widget.qrdata);

    // Get the temporary directory of the device
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/qr_code_report.pdf';

    // Write the PDF data to the file
    final file = File(filePath);
    await file.writeAsBytes(pdfData);

    // Open the PDF file
    await OpenFile.open(filePath);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Your QR is ready!'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RepaintBoundary(
                key: _globalKey,
                child: QrImageView(
                  data: widget.qrdata,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              SizedBox(height: 50),
              ElevatedButton(
                onPressed: _downloadPdf,
                child: Text(
                  'Download as PDF',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
              SizedBox(height: 50),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => AdminRootPage(email: widget.email)),
                  );
                },
                child: Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
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
}
