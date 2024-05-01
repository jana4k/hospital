import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:myapp/ui/app/about.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bloodGroupController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _medicationsController = TextEditingController();
  final TextEditingController _medicalHistoryController =
      TextEditingController();
  List<String> _pdfFilePaths = [];
  String? _imageFilePath;
  bool _loading = false;
  File? fileToDisplay;
  SharedPreferences? _prefs;
  bool _dataSubmitted = false;
  late String _encryptedData;
  bool normalData = false;
  late DatabaseReference _databaseReference;
  late FirebaseStorage _storage;
  late Future<void> _firebaseInitialized;
  bool _isSubmitting = false;
  late StreamSubscription<UserAccelerometerEvent> _accelerometerSubscription;
  bool _isDialogShowing =
      false; // Variable to track if a dialog is already showing
  double? _latitude;
  double? _longitude;
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadDataFromPrefs();
    _generateEncryptedData();
    _firebaseInitialized = _initFirebase();

    _accelerometerSubscription =
        userAccelerometerEvents.listen((UserAccelerometerEvent event) {
      // Detect shake
      if (_isShake(event) && !_isDialogShowing) {
        // Check if a dialog is not already showing
        setState(() {
          _isDialogShowing = true; // Set to true to prevent multiple dialogs
        });
        _saveFormDataToFirebase();
        showDialog(
          context: context,
          barrierDismissible: false, // Prevent dialog dismissal on tap outside
          builder: (context) {
            return AlertDialog(
              title: const Text(
                'Alert',
                style: TextStyle(color: Color.fromARGB(255, 235, 82, 36)),
              ),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Accident Detected Your Data Has Been sended to your nearby hospital'),
                  SizedBox(
                    height: 15,
                  ),
                  Center(
                      child: Text(
                    'Be safe for a while',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  )),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _isDialogShowing = false; // Reset the dialog showing flag
                    });
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _accelerometerSubscription.cancel();
  }

  Future<void> _getCurrentLocation() async {
    var status = await Permission.location.status;
    if (status.isGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
      } catch (e) {
        print("Error: $e");
      }
    } else {
      status = await Permission.location.request();
      if (!status.isGranted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Permission Denied"),
              content: const Text("Location permission is required!"),
              actions: <Widget>[
                TextButton(
                  child: const Text("OK"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  bool _isShake(UserAccelerometerEvent event) {
    // Adjust the threshold values according to your requirements
    const double threshold = 20.0;
    return event.x.abs() > threshold ||
        event.y.abs() > threshold ||
        event.z.abs() > threshold;
  }

  Future<void> _initFirebase() async {
    await Firebase.initializeApp();

    _storage =
        FirebaseStorage.instanceFor(bucket: 'gs://hospital-1c0f8.appspot.com');

    _databaseReference = FirebaseDatabase.instance.reference();
    // Set the correct database URL
    FirebaseDatabase.instance.setPersistenceEnabled(true);
    FirebaseDatabase.instance.setPersistenceCacheSizeBytes(10000000);
    _databaseReference = FirebaseDatabase(
      databaseURL:
          'https://hospital-1c0f8-default-rtdb.asia-southeast1.firebasedatabase.app',
    ).reference();
  }

  Future<void> _saveFormDataToFirebase() async {
    setState(() {
      _isSubmitting = true;
    });
    await _firebaseInitialized;
    if (_formKey.currentState!.validate()) {
      final googleMapsUrl =
          'https://www.google.com/maps/search/?api=1&query=$_latitude,$_longitude';

      final formData = {
        'name': _nameController.text,
        'age': _ageController.text,
        'gender': _genderController.text,
        'address': _addressController.text,
        'contact': _contactController.text,
        'email': _emailController.text,
        'bloodGroup': _bloodGroupController.text,
        'height': _heightController.text,
        'weight': _weightController.text,
        'allergies': _allergiesController.text,
        'medications': _medicationsController.text,
        'medicalHistory': _medicalHistoryController.text,
        'location': googleMapsUrl
      };

      final databaseRef = _databaseReference.child('formData').push();
      await databaseRef.set(formData);

      // Upload images
      if (_imageFilePath != null) {
        final imageBytes = await File(_imageFilePath!).readAsBytes();
        final imageExtension =
            _imageFilePath!.split('.').last; // Get the file extension
        final imageStorageRef = _storage
            .ref()
            .child('formData/${databaseRef.key}/image.$imageExtension');
        SettableMetadata metadata =
            SettableMetadata(contentType: 'image/$imageExtension');
        await imageStorageRef.putData(imageBytes, metadata);
        final imageUrl = await imageStorageRef.getDownloadURL();
        await databaseRef.update({'image': imageUrl});
      }

      // Upload PDFs
      for (final pdfFilePath in _pdfFilePaths) {
        final pdfBytes = await File(pdfFilePath).readAsBytes();
        final pdfStorageRef =
            _storage.ref().child('formData/${databaseRef.key}/pdf.pdf');
        await pdfStorageRef.putData(pdfBytes);
        final pdfUrl = await pdfStorageRef.getDownloadURL();
        await databaseRef.child('pdf').push().set({'url': pdfUrl});
      }
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Be safe! We alerted your nearby hospital'),
        ),
      );
    }
  }

  Future<void> _loadDataFromPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = _prefs!.getString('name') ?? '';
      _ageController.text = _prefs!.getString('age') ?? '';
      _genderController.text = _prefs!.getString('gender') ?? '';
      _addressController.text = _prefs!.getString('address') ?? '';
      _contactController.text = _prefs!.getString('contact') ?? '';
      _emailController.text = _prefs!.getString('email') ?? '';
      _bloodGroupController.text = _prefs!.getString('bloodGroup') ?? '';
      _heightController.text = _prefs!.getString('height') ?? '';
      _weightController.text = _prefs!.getString('weight') ?? '';
      _allergiesController.text = _prefs!.getString('allergies') ?? '';
      _medicationsController.text = _prefs!.getString('medications') ?? '';
      _medicalHistoryController.text =
          _prefs!.getString('medicalHistory') ?? '';
      _pdfFilePaths = _prefs!.getStringList('pdfFilePaths') ?? [];
      _imageFilePath = _prefs!.getString('imageFilePath');
      _dataSubmitted = _prefs!.getBool('dataSubmitted') ?? false;
      if (_imageFilePath != null && _imageFilePath!.isNotEmpty) {
        fileToDisplay = File(_imageFilePath!);
      }
    });
  }

  Future<void> _saveDataToPrefs() async {
    await _prefs!.setString('name', _nameController.text);
    await _prefs!.setString('age', _ageController.text);
    await _prefs!.setString('gender', _genderController.text);
    await _prefs!.setString('address', _addressController.text);
    await _prefs!.setString('contact', _contactController.text);
    await _prefs!.setString('email', _emailController.text);
    await _prefs!.setString('bloodGroup', _bloodGroupController.text);
    await _prefs!.setString('height', _heightController.text);
    await _prefs!.setString('weight', _weightController.text);
    await _prefs!.setString('allergies', _allergiesController.text);
    await _prefs!.setString('medications', _medicationsController.text);
    await _prefs!.setString('medicalHistory', _medicalHistoryController.text);
    await _prefs!.setStringList('pdfFilePaths', _pdfFilePaths);
    if (_imageFilePath != null) {
      await _prefs!.setString('imageFilePath', _imageFilePath!);
    }
    await _prefs!.setBool('dataSubmitted', _dataSubmitted);
  }

  Future<void> _pickImage() async {
    setState(() {
      _loading = true;
    });

    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
      if (!status.isGranted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Permission Denied"),
              content: const Text(
                  "Storage permission is required to select images."),
              actions: <Widget>[
                TextButton(
                  child: const Text("OK"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
        setState(() {
          _loading = false;
        });
        return;
      }
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _imageFilePath = result.files.first.path!;
        fileToDisplay = File(_imageFilePath!);
      });
    }

    setState(() {
      _loading = false;
    });
  }

  String _getFileExtension(String path) {
    return path.split('.').last;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      drawer: Drawer(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: const <Widget>[
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                    ),
                    child: Text('Menu'),
                  ),
                  // ListTile(
                  //   title: const Text('Contact'),
                  //   onTap: () async {
                  //     // await _saveFormDataToFirebase();
                  //   },
                  // ),
                ],
              ),
            ),
            ListTile(
              title: const Text('About'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: !_dataSubmitted
              ? Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _buildTextFormField('Name', _nameController),
                      _buildTextFormField('Age', _ageController),
                      _buildTextFormField('Gender', _genderController),
                      _buildTextFormField('Address', _addressController),
                      _buildTextFormField('Contact', _contactController),
                      _buildTextFormField('Email', _emailController),
                      _buildTextFormField('Blood Group', _bloodGroupController),
                      _buildTextFormField('Height', _heightController),
                      _buildTextFormField('Weight', _weightController),
                      _buildTextFormField('Allergies', _allergiesController),
                      _buildTextFormField(
                          'Medications', _medicationsController),
                      _buildTextFormField(
                          'Medical History', _medicalHistoryController),
                      const SizedBox(height: 20.0),
                      ElevatedButton(
                        onPressed: () async {
                          FilePickerResult? result = await FilePicker.platform
                              .pickFiles(
                                  type: FileType.custom,
                                  allowedExtensions: ['pdf']);
                          if (result != null) {
                            setState(() {
                              _pdfFilePaths.add(result.files.first.path!);
                            });
                          }
                        },
                        child: const Text('Select PDF'),
                      ),
                      const SizedBox(height: 20.0),
                      ElevatedButton(
                        onPressed: () {
                          _pickImage();
                        },
                        child: const Text('Select Image'),
                      ),
                      const SizedBox(height: 20.0),
                      if (_pdfFilePaths.isNotEmpty) ...[
                        const Text(
                          'Selected PDFs:',
                          style: TextStyle(fontSize: 16.0),
                        ),
                        for (String pdfFilePath in _pdfFilePaths)
                          Text(
                            pdfFilePath,
                            style: const TextStyle(fontSize: 16.0),
                          ),
                        const SizedBox(height: 20.0),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            'images/pdf.jpg',
                            height: 125.0,
                            width: 110.0,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20.0),
                      if (_imageFilePath != null) ...[
                        Text(
                          'Selected Image: $_imageFilePath',
                          style: const TextStyle(fontSize: 16.0),
                        ),
                        const SizedBox(height: 20.0),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            fileToDisplay!,
                            height: 125.0,
                            width: 110.0,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20.0),
                      Center(
                        child: ElevatedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () async {
                                  if (_formKey.currentState!.validate()) {
                                    if (_pdfFilePaths.isNotEmpty &&
                                        _pdfFilePaths.any((path) =>
                                            File(path).lengthSync() >
                                            0.5 * 1024 * 1024 * 1024)) {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title:
                                                const Text('File Size Error'),
                                            content: const Text(
                                                'PDF file size should be less than 500MB.'),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: const Text('OK'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                      return;
                                    }
                                    await _saveDataToPrefs();
                                    // _saveFormDataToFirebase();
                                    setState(() {
                                      _dataSubmitted = true;
                                    });

                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text('Submitted'),
                                          content: const Text(
                                              'Your data has been submitted successfully'),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                },
                          child: _isSubmitting
                              ? const CircularProgressIndicator()
                              : const Text('Submit'),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Scan QR Code to Get Details',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // You can customize the color
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    normalData
                        ? QrImageView(
                            data: _generateQRData(),
                            version: QrVersions.auto,
                          )
                        : QrImageView(
                            data: _encryptedData,
                            version: QrVersions.auto,
                          ),
                    const SizedBox(height: 20.0),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _dataSubmitted = false;
                        });
                      },
                      child: const Text('Edit Your Details'),
                    ),
                    const SizedBox(height: 10.0),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          normalData = !normalData;
                        });
                      },
                      child: Text(
                          'Show ${normalData ? 'Encrypted' : 'Normal'} Data'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _generateEncryptedData() {
    final key = encrypt.Key.fromSecureRandom(16);
    // Generate QR code data based on the form data
    final Map<String, dynamic> formData = {
      'Name': _nameController.text,
      'Age': _ageController.text,
      'Gender': _genderController.text,
      'Address': _addressController.text,
      'Contact': _contactController.text,
      'Email': _emailController.text,
      'Blood Group': _bloodGroupController.text,
      'Height': _heightController.text,
      'Weight': _weightController.text,
      'Allergies': _allergiesController.text,
      'Medications': _medicationsController.text,
      'Medical History': _medicalHistoryController.text,
    };

    final jsonFormData = jsonEncode(formData);

    // Encrypt the JSON data using the random key
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encrypt(jsonFormData, iv: iv);
    _encryptedData = encrypted.base64;
  }

  String _generateQRData() {
    // Generate QR code data based on the form data
    final Map<String, dynamic> formData = {
      'Name': _nameController.text,
      'Age': _ageController.text,
      'Gender': _genderController.text,
      'Address': _addressController.text,
      'Contact': _contactController.text,
      'Email': _emailController.text,
      'Blood Group': _bloodGroupController.text,
      'Height': _heightController.text,
      'Weight': _weightController.text,
      'Allergies': _allergiesController.text,
      'Medications': _medicationsController.text,
      'Medical History': _medicalHistoryController.text,
    };

    return jsonEncode(formData);
  }

  Widget _buildTextFormField(
      String labelText, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: labelText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.blue),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          validator: (value) {
            if (value!.isEmpty) {
              return 'Please enter the $labelText';
            }
            return null;
          },
        ),
        const SizedBox(height: 20.0),
      ],
    );
  }
}
