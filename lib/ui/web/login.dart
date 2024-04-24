import 'package:flutter/material.dart';
import 'package:myapp/ui/app/home.dart';
import 'package:myapp/ui/web/hospitalUi.dart';
import 'package:myapp/ui/web/webHomePage.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LoginType { user, hospital }

class WebLoginPage extends StatefulWidget {
  const WebLoginPage({super.key});

  @override
  _WebLoginPageState createState() => _WebLoginPageState();
}

class _WebLoginPageState extends State<WebLoginPage> {
  bool _passwordVisible = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  LoginType _loginType = LoginType.user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Web Login Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: [
                Radio<LoginType>(
                  value: LoginType.user,
                  groupValue: _loginType,
                  onChanged: (LoginType? value) {
                    setState(() {
                      _loginType = value!;
                      _saveLoginType(value);
                    });
                  },
                ),
                const Text('User Login'),
                Radio<LoginType>(
                  value: LoginType.hospital,
                  groupValue: _loginType,
                  onChanged: (LoginType? value) {
                    setState(() {
                      _loginType = value!;
                      _saveLoginType(value);
                    });
                  },
                ),
                const Text('Hospital Login'),
              ],
            ),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username or Phone Number',
              ),
            ),
            const SizedBox(height: 20.0),
            TextField(
              controller: _passwordController,
              obscureText: !_passwordVisible,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _passwordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _passwordVisible = !_passwordVisible;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                final String email = _usernameController.text;
                final String password = _passwordController.text;
                if (email.isNotEmpty && password.isNotEmpty) {
                  // Save username and password to SharedPreferences
                  _saveLoginData(email, password);

                  // Navigate to the appropriate home page based on login type
                  if (_loginType == LoginType.user) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const WebHomePage()),
                    );
                  } else {
                    // Navigate to the hospital home page
                    // Replace `HospitalHomePage` with the appropriate widget for hospital home page
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>  HospitalHomePage()),
                    );
                  }
                } else {
                  // Show an error message or toast
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter email and password.'),
                    ),
                  );
                }
              },
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveLoginData(String email, String password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('emaill', email);
    await prefs.setString('password', password);
  }

  Future<void> _saveLoginType(LoginType value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('loginType', value.index);
  }

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadLoginType();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('emaill');
    String? password = prefs.getString('password');
    if (email != null && password != null) {
      // Navigate to the appropriate home page based on login type
      if (_loginType == LoginType.user) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        // Navigate to the hospital home page
        // Replace `HospitalHomePage` with the appropriate widget for hospital home page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) =>  HospitalHomePage()),
        );
      }
    }
  }

  Future<void> _loadLoginType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? loginTypeIndex = prefs.getInt('loginType');
    if (loginTypeIndex != null) {
      setState(() {
        _loginType = LoginType.values[loginTypeIndex];
      });
    }
  }
}
