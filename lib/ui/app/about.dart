import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';


class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  late StreamSubscription<UserAccelerometerEvent> _accelerometerSubscription;

  double _x = 0.0;
  double _y = 0.0;
  double _z = 0.0;

  @override
  void initState() {
    super.initState();
    _accelerometerSubscription =
        userAccelerometerEvents.listen((UserAccelerometerEvent event) {
      setState(() {
        _x = event.x;
        _y = event.y;
        _z = event.z;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _accelerometerSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accelerometer'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text('X: $_x',style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.normal,
          ),),
            const SizedBox(height: 15,),
            Text('Y: $_y',style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.normal,
          ),), 
            const SizedBox(height: 15,),
            Text('Z: $_z',style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.normal,
          ),),
          ],
        ),
      ),
    );
  }
}
