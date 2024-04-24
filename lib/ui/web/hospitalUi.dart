import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';

class HospitalHomePage extends StatefulWidget {
  const HospitalHomePage({super.key});

  @override
  _HospitalHomePageState createState() => _HospitalHomePageState();
}

class _HospitalHomePageState extends State<HospitalHomePage> {
  late DatabaseReference _databaseReference;
  bool _showNewUserCard = false;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _initializeDatabase() async {
    await Firebase.initializeApp();
    _databaseReference = FirebaseDatabase(
      databaseURL:
          'https://hospital-1c0f8-default-rtdb.asia-southeast1.firebasedatabase.app',
    ).reference();
    _databaseReference.child('formData').onChildAdded.listen((event) {
      setState(() {
        _showNewUserCard = true;
        _timer = Timer(const Duration(seconds: 8), () {
          setState(() {
            _showNewUserCard = false;
          });
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospital Home Page'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_showNewUserCard)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'New user added! Check the details now!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          const Center(
            child: Text(
              'Patient Details',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _databaseReference.child('formData').onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  Map<dynamic, dynamic> data = (snapshot.data!.snapshot.value ??
                      {}) as Map<dynamic, dynamic>;
                  if (data.isNotEmpty) {
                    return ListView.builder(
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        String key = data.keys.elementAt(index);
                        Map<dynamic, dynamic> formData =
                            data[key] as Map<dynamic, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: GestureDetector(
                            onTap: () {
                              _showDetailsDialog(formData);
                            },
                            child: Card(
                              elevation: 3,
                              child: ListTile(
                                title: Text(
                                  formData['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                subtitle: Text(
                                  'Age: ${formData['age']}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  } else {
                    return const Center(
                      child: Text('No data available'),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailsDialog(Map<dynamic, dynamic> formData) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Details for ${formData['name']}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetail('Address', formData['address']),
                _buildDetail('Age', formData['age']),
                _buildDetail('Allergies', formData['allergies']),
                _buildDetail('Blood Group', formData['bloodGroup']),
                _buildDetail('Contact', formData['contact']),
                _buildDetail('Email', formData['email']),
                _buildDetail('Gender', formData['gender']),
                _buildDetail('Height', formData['height']),
                _buildDetail('Medical History', formData['medicalHistory']),
                _buildDetail('Medications', formData['medications']),
                _buildDetail('Weight', formData['weight']),
                // Location with copy option

                _buildLocationDetail(
                    'Location', "https://goo.gl/maps/TxNMxrXNFrp9oWbc8"),

                // Show image if available
                if (formData['image'] != null &&
                    formData['image'] is String) ...[
                  _buildLocationDetail('Image', formData['image']),
                ],
                // Show PDF if available
                if (formData['pdf'] != null && formData['pdf'] is Map) ...[
                  _buildLocationDetail(
                      'PDF', formData['pdf'].values.first['url']),
                ],
              ],
            ),
          ),
          actions: <Widget>[
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

  Widget _buildLocationDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$label copied to clipboard'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14),
        ),
        const Divider(),
      ],
    );
  }

  Widget _buildDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14),
        ),
        const Divider(),
      ],
    );
  }
}
