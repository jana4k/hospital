import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class HospitalHomePage extends StatefulWidget {
  const HospitalHomePage({super.key});

  @override
  _HospitalHomePageState createState() => _HospitalHomePageState();
}

class _HospitalHomePageState extends State<HospitalHomePage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // _initFirebase();
  }
  Future<void> _initFirebase() async {
    await Firebase.initializeApp();}
  final DatabaseReference _databaseReference =
      FirebaseDatabase.instance.reference().child('formData');
  Future<void> _fetchFormDataFromFirebase() async {
    final databaseRef = _databaseReference.child('formData');
    final snapshot = await databaseRef.get();

    if (snapshot.exists) {
      final formData = snapshot.value as Map<String, dynamic>;
      // Process the fetched data
      if (kDebugMode) {
        print('Name: ${formData['name']}');
      }
      if (kDebugMode) {
        print('Age: ${formData['age']}');
      }
      // ...
    } else {
      if (kDebugMode) {
        print('No data found');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Hospital Home Page'),
        ),
        body: Center(
          child: ElevatedButton(
              onPressed: () {
                // _fetchFormDataFromFirebase();
              },
              child: const Text('data')),
        ));
  }
}
