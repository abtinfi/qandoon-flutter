import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../auth_check_screen.dart';
import '../signup/signup_screen.dart';
import '../forgot_password/forgot_password_otp_screen.dart';
import '/widget/app_bar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();
  final String _loginEndpoint = 'https://api.abtinfi.ir/users/login';

  bool _visiblePassword = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Login Failed'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Future<void> _performLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(_loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _email.text.trim(),
          'password': _password.text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final accessToken = responseBody['access_token'];

        if (accessToken != null) {
          await _storage.write(key: 'jwt_token', value: accessToken);

          final userResponse = await http.get(
            Uri.parse('https://api.abtinfi.ir/users/me'),
            headers: {'Authorization': 'Bearer $accessToken'},
          );

          if (userResponse.statusCode == 200) {
            await _storage.write(key: 'user', value: userResponse.body);
          }

          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AuthCheckScreen()),
          );
        } else {
          _showErrorDialog('Invalid response format from server.');
        }
      } else if (response.statusCode == 401 || response.statusCode == 404) {
        final body = jsonDecode(response.body);
        _showErrorDialog(body['message'] ?? 'Invalid email or password.');
      } else {
        _showErrorDialog(
          'Unexpected error. Status code: ${response.statusCode}',
        );
      }
    } catch (_) {
      if (!mounted) return;
      _showErrorDialog('An error occurred. Please try again.');
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
                    'Login',
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
                        return 'Enter a valid email address';
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
                    validator:
                        (value) =>
                            (value == null || value.isEmpty)
                                ? 'Password is required'
                                : null,
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (_) => const ForgotPasswordEnterEmailScreen(),
                          ),
                        );
                      },
                      child: const Text('Forgot Password?'),
                    ),
                  ),

                  const SizedBox(height: 12),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _performLogin,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                            : const Text('Login'),
                  ),

                  const SizedBox(height: 24),

                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      );
                    },
                    child: const Text("Don't have an account? Sign up"),
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
