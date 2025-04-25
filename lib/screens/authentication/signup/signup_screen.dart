import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'signup_otp_screen.dart';
import '/widget/app_bar.dart';

void _showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Okay'),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
  );
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _repeatPassword = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _visiblePassword = false;
  bool _visibleRepeatPassword = false;
  bool _isLoading = false;

  final String _registerEndpoint = 'https://api.abtinfi.ir/users/register';

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    _password.dispose();
    _repeatPassword.dispose();
    super.dispose();
  }

  Future<void> _performRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, String> requestBody = {
        'email': _email.text,
        'name': _name.text,
        'password': _password.text,
      };

      final response = await http.post(
        Uri.parse(_registerEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => SignupOTPScreen(email: _email.text),
          ),
        );
      } else if (response.statusCode == 400) {
        final errorBody = jsonDecode(response.body);
        String errorMessage = 'Registration failed.';
        if (errorBody != null && errorBody['detail'] != null) {
          errorMessage = errorBody['detail'];
        }
        _showErrorDialog(context, errorMessage);
      } else {
        _showErrorDialog(
          context,
          'Registration failed. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      _showErrorDialog(
        context,
        'An error occurred. Please check your connection and try again.',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: appBar(context),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24), // Added const
            physics: const BouncingScrollPhysics(), // Added const
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sign Up',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 60), // Added const
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      // Added const
                      prefixIcon: Icon(Icons.email),
                      label: Text('email'),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Email can't be empty";
                      }
                      final emailRegex = RegExp(
                        r'^[\w-\\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      );
                      if (!emailRegex.hasMatch(value)) {
                        return "Please enter a valid email address";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24), // Added const
                  TextFormField(
                    controller: _name,
                    keyboardType: TextInputType.name,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person),
                      label: Text('Name'),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Name can't be empty";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24), // Added const

                  TextFormField(
                    controller: _password,
                    keyboardType: TextInputType.text,
                    obscureText: !_visiblePassword,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _visiblePassword = !_visiblePassword;
                          });
                        },
                        icon: Icon(
                          _visiblePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                      prefixIcon: const Icon(Icons.lock), // Added const
                      label: const Text('password'), // Added const
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        // Added null check
                        return "Password can't be empty";
                      } else if (value.length < 6) {
                        return "Password must be at least 6 characters";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24), // Added const
                  TextFormField(
                    controller: _repeatPassword,
                    keyboardType: TextInputType.text,
                    obscureText: !_visibleRepeatPassword,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _visibleRepeatPassword = !_visibleRepeatPassword;
                          });
                        },
                        icon: Icon(
                          _visibleRepeatPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                      prefixIcon: const Icon(Icons.lock_reset), // Added const
                      label: const Text('repeat password'), // Added const
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        // Added null check
                        return "Repeat Password can't be empty";
                      }
                      if (_password.text != _repeatPassword.text) {
                        return "Passwords do not match";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24), // Added const
                  ElevatedButton(
                    onPressed: _isLoading ? null : _performRegistration,
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                            : const Text('Sign Up'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Already have an account? Login',
                    ), // Added const
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
