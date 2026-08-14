import 'package:clickngo/Admin/admin_root_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../Component/SharedData.dart';
import '../../Component/color.dart';
import '../../Component/important_functions.dart';

class NewEntry extends StatefulWidget {
  final String email;
  const NewEntry({super.key,required this.email});

  @override
  State<NewEntry> createState() => _NewEntryState();
}

class _NewEntryState extends State<NewEntry> {
  String? Orgname;
  String Orgemail = '';

  // Controllers for the input fields
  late TextEditingController _serialnumberController;
  late TextEditingController _organizationNameController;
  late TextEditingController _emailController;
  late TextEditingController _nameController;
  late TextEditingController _vehicleNumberController;
  late TextEditingController _purposeController;

  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  String get selectedDateTime {
    final int hours = selectedTime.hour;
    final int minutes = selectedTime.minute;

    final DateTime dateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      hours,
      minutes,
    );

    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return formatter.format(dateTime);
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _serialnumberController = TextEditingController();
    _nameController = TextEditingController();
    _vehicleNumberController = TextEditingController();
    _emailController = TextEditingController();
    _organizationNameController = TextEditingController();
    _purposeController = TextEditingController();

    _fetchAndSetSerialNumber();
  }

  Future<void> _fetchAndSetSerialNumber() async {
    User? admin = _auth.currentUser;
    try {
      if (admin != null) {
        Orgemail = admin.email!;

      }

      final firestore = FirebaseFirestore.instance;
      final dataCollectionRef = firestore
          .collection('Organizations')
          .doc(Orgemail)
          .collection('DATA');

      final dataCollectionSnapshot = await dataCollectionRef.get();
      final nextSerialNumber = dataCollectionSnapshot.size + 1;

      setState(() {
        _serialnumberController.text = nextSerialNumber.toString();
        _organizationNameController.text = Orgname!;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching serial number: $e')),
      );
    }
  }

  Future<void> _submitFormData() async {
    try {
      if (Orgname != null && Orgname!.isNotEmpty) {
        final firestore = FirebaseFirestore.instance;

        // Store in Users collection
        final orgDataDocRef = firestore
            .collection('Users')
            .doc(_emailController.text)
            .collection('History')
            .doc();

        await orgDataDocRef.set({
          'EntryNo': _serialnumberController.text,
          'Name': _nameController.text,
          'VehicleNumber': _vehicleNumberController.text,
          'Email': _emailController.text,
          'Organization': Orgname,
          'Purpose': _purposeController.text,
          'DateTime': selectedDateTime,
        });

        print(Orgname);

        // Store in Organizations collection
        final dataCollectionsRef = firestore
            .collection('Organizations')
            .doc(Orgemail)
            .collection('DATA');

        final dataDocRef = dataCollectionsRef.doc(_serialnumberController.text);

        await dataDocRef.set({
          'EntryNo': int.parse(_serialnumberController.text),
          'Name': _nameController.text,
          'VehicleNumber': _vehicleNumberController.text,
          'Email': _emailController.text,
          'Organization': Orgname,
          'Purpose': _purposeController.text,
          'DateTime': selectedDateTime,
        });

        print('Data successfully written to Organizations collection.');

        // Show success SnackBar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Form Submitted Successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Navigate to AdminRootPage after displaying SnackBar
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted) {
            Get.off(() => AdminRootPage(email: Orgemail));
          }
        });

      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: Organization name is null or empty'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting form: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Error submitting form: $e');
    }
  }


  void _checkFormAndSubmit() {
    if (_purposeController.text.isNotEmpty) {
      _submitFormData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill out the Purpose of Visit.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: Theme(
            data: ThemeData.light().copyWith(
              timePickerTheme: TimePickerThemeData(
                dayPeriodColor: primaryColor.withOpacity(0.5),
              ),
            ),
            child: child!,
          ),
        );
      },
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("New Entry"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextFormField('Entry No:', _serialnumberController),
              _buildTextFormField('Organization Name:', _organizationNameController),
              _buildTextFormField('Email:', _emailController),
              _buildTextFormField('Name:', _nameController),
              _buildTextFormField('Vehicle Number:', _vehicleNumberController),
              Text(
                'Date and Time:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _selectDate(context),
                      child: Text("${selectedDate.toLocal()}".split(' ')[0]),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _selectTime(context),
                      child: Text("${selectedTime.format(context)}"),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              _buildTextFormField('Purpose of Visit:', _purposeController),
              SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _checkFormAndSubmit,
                  child: Text('Submit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: label,
            labelStyle: TextStyle(color: Colors.black54),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }
}
