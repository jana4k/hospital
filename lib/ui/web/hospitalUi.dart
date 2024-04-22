import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class HospitalHomePage extends StatefulWidget {
  const HospitalHomePage({super.key});

  @override
  _HospitalHomePageState createState() => _HospitalHomePageState();
}

class _HospitalHomePageState extends State<HospitalHomePage> {
  late DatabaseReference _databaseReference;
  List<Map<String, dynamic>> patientsData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp();
    _databaseReference = FirebaseDatabase(
      databaseURL:
          'https://hospital-1c0f8-default-rtdb.asia-southeast1.firebasedatabase.app',
    ).reference().child('formData');
    _fetchData();
  }

  Future<void> _fetchData() async {
    _databaseReference.onValue.listen((event) {
      final snapshot = event.snapshot;
      final Map<dynamic, dynamic>? data = snapshot.value as Map?;
      if (data != null) {
        List<Map<String, dynamic>> patients = [];
        data.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            patients.add(value);
          }
        });
        setState(() {
          patientsData = patients;
          _isLoading = false; // Data fetched, set isLoading to false
        });
      } else {
        // Handle empty data scenario (optional)
        print('No data found in the database');
        setState(() {
          _isLoading = false; // Set isLoading to false even if there's no data
        });
      }
    }, onError: (error) {
      // Handle errors during data fetching
      if (kDebugMode) {
        print('Error fetching data: $error');
      }
      setState(() {
        _isLoading = false; // Set isLoading to false on error
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospital Home Page'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : patientsData.isEmpty
              ? const Center(child: Text('No data found'))
              : ListView.builder(
                  itemCount: patientsData.length,
                  itemBuilder: (context, index) {
                    final patient = patientsData[index];
                    return ListTile(
                      title: Text(patient['name'] ?? 'No Name'),
                      onTap: () {
                        _showPatientDetailsDialog(patient);
                      },
                    );
                  },
                ),
    );
  }

  // Function to show patient details dialog (unchanged)
  void _showPatientDetailsDialog(Map<String, dynamic> patient) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Patient Details - ${patient['name']}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${patient['name']}'),
                Text('Age: ${patient['age']}'),
                Text('Gender: ${patient['gender']}'),
                Text('Address: ${patient['address']}'),
                Text('Contact: ${patient['contact']}'),
                Text('Email: ${patient['email']}'),
                Text('Blood Group: ${patient['bloodGroup']}'),
                Text('Height: ${patient['height']}'),
                Text('Weight: ${patient['weight']}'),
                Text('Allergies: ${patient['allergies']}'),
                Text('Medications: ${patient['medications']}'),
                Text('Medical History: ${patient['medicalHistory']}'),
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
