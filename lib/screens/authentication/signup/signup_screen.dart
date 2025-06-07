import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'signup_otp_screen.dart';
import '/widget/app_bar.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _email = TextEditingController();
  final _name = TextEditingController();
  final _password = TextEditingController();
  final _repeatPassword = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final _registerEndpoint = 'https://api.abtinfi.ir/users/register';

  bool _visiblePassword = false;
  bool _visibleRepeatPassword = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    _password.dispose();
    _repeatPassword.dispose();
    super.dispose();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Registration Failed'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Future<void> _performRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(_registerEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _email.text.trim(),
          'name': _name.text.trim(),
          'password': _password.text,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => SignupOTPScreen(email: _email.text.trim()),
          ),
        );
      } else if (response.statusCode == 400) {
        final body = jsonDecode(response.body);
        final errorMessage = body['detail'] ?? 'Registration failed.';
        _showErrorDialog(errorMessage);
      } else {
        _showErrorDialog(
          'Unexpected error. Status code: ${response.statusCode}',
        );
      }
    } catch (_) {
      _showErrorDialog('A connection error occurred. Try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: appBar(context),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Text(
                    'Sign Up',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 48),

                  /// Email
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.email),
                      labelText: 'Email',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      final emailRegex = RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      );
                      if (!emailRegex.hasMatch(value.trim())) {
                        return 'A valid email address must be entered';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  /// Name
                  TextFormField(
                    controller: _name,
                    keyboardType: TextInputType.name,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person),
                      labelText: 'Name',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  /// Password
                  TextFormField(
                    controller: _password,
                    obscureText: !_visiblePassword,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock),
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _visiblePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed:
                            () => setState(
                              () => _visiblePassword = !_visiblePassword,
                            ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      } else if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  /// Repeat Password
                  TextFormField(
                    controller: _repeatPassword,
                    obscureText: !_visibleRepeatPassword,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_reset),
                      labelText: 'Repeat Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _visibleRepeatPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed:
                            () => setState(
                              () =>
                                  _visibleRepeatPassword =
                                      !_visibleRepeatPassword,
                            ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password confirmation must be provided';
                      }
                      if (_password.text != value) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  /// Submit Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _performRegistration,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                            : const Text('Sign Up'),
                  ),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Already have an account? Login'),
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
