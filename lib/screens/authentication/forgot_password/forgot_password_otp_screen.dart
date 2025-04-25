import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../widget/app_bar.dart';
import 'change_password_screen.dart';

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

class ForgotPasswordEnterEmailScreen extends StatefulWidget {
  const ForgotPasswordEnterEmailScreen({super.key});

  @override
  State<ForgotPasswordEnterEmailScreen> createState() =>
      _ForgotPasswordEnterEmailScreenState();
}

class _ForgotPasswordEnterEmailScreenState
    extends State<ForgotPasswordEnterEmailScreen> {
  final TextEditingController _email = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final String _requestOtpEndpoint = 'https://api.abtinfi.ir/users/request-otp';

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _requestPasswordResetOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(_requestOtpEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _email.text, 'purpose': 'password_reset'}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP sent to your email!")),
        );

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChangePasswordScreen(email: _email.text),
          ),
        );
      } else if (response.statusCode == 400) {
        final errorBody = jsonDecode(response.body);
        String errorMessage = 'Failed to request OTP.';
        if (errorBody != null && errorBody['detail'] != null) {
          errorMessage = errorBody['detail'];
          if (errorMessage.contains(
            "Please wait before requesting a new OTP",
          )) {
            _showErrorDialog(context, errorMessage);
            return;
          }
        }
        _showErrorDialog(context, errorMessage);
      } else {
        _showErrorDialog(
          context,
          'Failed to request OTP. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (!mounted) return;

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
                    'Forgot Password',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 60), // Added const
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      // Added const
                      prefixIcon: Icon(Icons.email),
                      label: Text('Enter your email'),
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
                  ElevatedButton(
                    onPressed: _isLoading ? null : _requestPasswordResetOtp,
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                            : const Text('Send OTP'),
                  ),
                  const SizedBox(height: 16), // Added some space
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Back to Login'),
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
