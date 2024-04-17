import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; 

import 'package:myapp/ui/app/login.dart';
import 'package:myapp/ui/web/login.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hospital',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      
      home: kIsWeb ? const WebLoginPage() : const LoginPage(),
    );
  }
}



