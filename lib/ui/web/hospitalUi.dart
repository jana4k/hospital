import 'package:flutter/material.dart';

class HospitalHomePage extends StatefulWidget {
  const HospitalHomePage({super.key});

  @override
  State<HospitalHomePage> createState() => _HospitalHomePageState();
}

class _HospitalHomePageState extends State<HospitalHomePage> {
  List<String> patientNames = [
    'Patient 1',
    'Patient 2',
    'Patient 3'
  ]; // Example list of patient names

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospital Home Page'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Message Box
            const Card(
              elevation: 3,
              margin: EdgeInsets.all(10),
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'New user added few seconds ago. Check it now.',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Patient Names
            ListView.builder(
              shrinkWrap: true,
              itemCount: patientNames.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(patientNames[index]),
                  onTap: () {
                    // Show patient details dialog
                    _showPatientDetailsDialog(patientNames[index]);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Function to show patient details dialog
  void _showPatientDetailsDialog(String patientName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Patient Details - $patientName'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add patient details here based on patientName
                // For example:
                Text('Age: 25'),
                Text('Gender: Male'),
                Text('Address: XYZ Street'),
                // Add more patient details as needed
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
