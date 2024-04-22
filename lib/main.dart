import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; 

import 'package:myapp/ui/app/login.dart';
import 'package:myapp/ui/web/login.dart';

void  main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if(kIsWeb){}else{ await Firebase.initializeApp(
    options: const FirebaseOptions(apiKey:  "AIzaSyADn_f0_rTQYvKmzeN21HGI9ldjnnIM2Kk", 
    appId: "1:24627419390:android:f5aff618247afb96c12daf",
     messagingSenderId: "24627419390", 
    projectId: "hospital-1c0f8")
  );}
  await Firebase.initializeApp(
    options: const FirebaseOptions(apiKey:  "AIzaSyADn_f0_rTQYvKmzeN21HGI9ldjnnIM2Kk", 
    appId: "1:24627419390:android:f5aff618247afb96c12daf",
     messagingSenderId: "24627419390", 
    projectId: "hospital-1c0f8")
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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



