import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:myapp/ui/app/about.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void initState() {
    super.initState();
    _loadDataFromPrefs();
    _generateEncryptedData();
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
                children: <Widget>[
                  const DrawerHeader(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                    ),
                    child: Text('Menu'),
                  ),
                  ListTile(
                    title: const Text('Contact'),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("Message"),
                            content: const Text("Updated successfully"),
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
                    },
                  ),
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
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              if (_pdfFilePaths.isNotEmpty &&
                                  _pdfFilePaths.any((path) =>
                                      File(path).lengthSync() >
                                      5 * 1024 * 1024)) {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('File Size Error'),
                                      content: const Text(
                                          'PDF file size should be less than 5MB.'),
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

                              setState(() {
                                _dataSubmitted = true;
                              });
                              await _saveDataToPrefs();
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
                          child: const Text('Submit'),
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
