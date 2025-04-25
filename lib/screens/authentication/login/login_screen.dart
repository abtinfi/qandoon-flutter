import 'package:bakery/screens/authentication/forgot_password/forgot_password_otp_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import '../auth_check_screen.dart';
import '../signup/signup_screen.dart';
import '/widget/app_bar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _visiblePassword = false;
  bool _isLoading = false;
  final String _loginEndpoint = 'https://api.abtinfi.ir/users/login';
  final _storage = const FlutterSecureStorage();
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _email.dispose();
    _password.dispose();
  }

  void _showErrorDialog(String message) {
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

  Future<void> _performLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, String> requestBody = {
        'email': _email.text,
        'password': _password.text,
      };

      final response = await http.post(
        Uri.parse(_loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        final String? accessToken = responseBody['access_token'];
        final String? tokenType = responseBody['token_type'];

        if (accessToken != null && tokenType != null) {
          await _storage.write(key: 'jwt_token', value: accessToken);
          if (!mounted) return;

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AuthCheckScreen()),
          );
        } else {
          _showErrorDialog(
            'Login failed: Invalid response format from server.',
          );
        }
      } else if (response.statusCode == 401 || response.statusCode == 404) {
        final errorBody = jsonDecode(response.body);
        _showErrorDialog(errorBody['message'] ?? 'Invalid email or password.');
      } else {
        _showErrorDialog('Login failed. Status code: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(
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
            padding: EdgeInsets.all(24),
            physics: BouncingScrollPhysics(),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Login',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  SizedBox(height: 60),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
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
                  SizedBox(height: 24),
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
                      prefixIcon: Icon(Icons.lock),
                      label: Text('password'),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Password can't be empty";
                      }
                      return null;
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    const ForgotPasswordEnterEmailScreen(),
                          ),
                        );
                      },
                      child: const Text('Forgot Password?'), // Added const
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _performLogin,
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                            : const Text('Login'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (context) => const SignupScreen(), // Added const
                        ),
                      );
                    },
                    child: const Text(
                      'Don’t have an account? Sign up',
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
