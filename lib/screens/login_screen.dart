import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hr_attendant/models/user_model.dart';
import 'package:hr_attendant/services/auth_service.dart';
import 'package:logger/logger.dart';

import 'home_screen.dart';

final log = Logger();

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  final AuthService _authService = AuthService();

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    UserModel? user = await _authService.login(
        _emailController.text, _passwordController.text);

    setState(() {
      _isLoading = false;
    });

    if (user != null) {
      // Navigate to the home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                HomeScreen(updateThemeColor: (MaterialColor color) {})),
      );
    } else {
      // Show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid email or password.')),
      );
    }
  }

  Future<void> _forgetPassword() async {
    TextEditingController emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Forget Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please enter your email address:'),
              const SizedBox(height: 16.0),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange,
                backgroundColor: Colors.orange.withOpacity(0.2),
              ),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Theme.of(context).primaryColor,
              ),
              onPressed: () async {
                String? errorMessage =
                    await _authService.forgetPassword(emailController.text);
                if (errorMessage == null) {
                  // Password reset request was successful
                  // Navigate to the next screen or show a success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'A password reset link has been sent to your email.'),
                    ),
                  );
                } else {
                  // Show the error message using a SnackBar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(errorMessage)),
                  );
                }
                Navigator.of(context).pop();
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: LayoutBuilder(builder: (context, constraints) {
      double screenHeight = constraints.maxHeight;
      double topPartHeight = screenHeight * 0.3;
      double bottomPartHeight = screenHeight * 0.7;
      return Container(
        decoration: BoxDecoration(
          image: const DecorationImage(
              image: AssetImage(
                  'assets/images/bamboo.png'), // Replace with your desired image
              fit: BoxFit.fitWidth,
              alignment: Alignment.topRight),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.0),
              Theme.of(context).primaryColor.withOpacity(0.9),
            ],
          ),
        ),
        child: Column(
          children: [
            // Top part with logo, app name, and background image
            SizedBox(
              height: topPartHeight,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                child: Column(
                  children: [
                    const SizedBox(height: 50.0),
                    Container(
                      width: 250.0,
                      height: 120,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(
                                0.5), // Set shadow color and opacity
                            spreadRadius:
                                5, // Set the spread radius of the shadow
                            blurRadius: 7, // Set the blur radius of the shadow
                            offset:
                                const Offset(0, 3), // Set the offset of the shadow
                          ),
                        ],
                        image: const DecorationImage(
                          image: AssetImage('assets/images/hrms_logo.png'),
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    /*Center(
                          child: Text(
                            'FlexBenHR',
                            style: TextStyle(
                              fontSize: 32.0,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  offset: Offset(2.0, 2.0),
                                  blurRadius: 3.0,
                                  color: Color.fromARGB(255, 255, 255, 255),
                                ),
                                Shadow(
                                  offset: Offset(-2.0, -2.0),
                                  blurRadius: 3.0,
                                  color: Color.fromARGB(255, 255, 255, 255),
                                ),
                              ],
                            ),
                          ),
                        ),*/
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom part with rounded corners and login form
            Container(
              height: bottomPartHeight,
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40.0),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16.0),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity,
                            child: Column(
                              children: [
                                ElevatedButton(
                                  onPressed: _login,
                                  style: ElevatedButton.styleFrom(
                                      //primary: Theme.of(context).primaryColor,
                                      ),
                                  child: const Text('Login'),
                                ),
                                const SizedBox(height: 16.0),
                                TextButton(
                                  onPressed: _forgetPassword,
                                  child: Text(
                                    'Forget Password?',
                                    style: TextStyle(
                                        color: Theme.of(context).primaryColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }));
  }
}
