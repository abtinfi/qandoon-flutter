import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../widget/app_bar.dart';
import '../../../utils/otp_tracker.dart';
import 'change_password_screen.dart';

class ForgotPasswordEnterEmailScreen extends StatefulWidget {
  const ForgotPasswordEnterEmailScreen({super.key});

  @override
  State<ForgotPasswordEnterEmailScreen> createState() =>
      _ForgotPasswordEnterEmailScreenState();
}

class _ForgotPasswordEnterEmailScreenState
    extends State<ForgotPasswordEnterEmailScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isResending = false;
  bool _canResend = false;

  Timer? _timer;
  int _secondsRemaining = 0;

  final String _requestOtpEndpoint = 'https://api.abtinfi.ir/users/request-otp';

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  void _startTimer({int duration = 180}) {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = duration;
      _canResend = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0;
          _canResend = true;
        });
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  Future<void> _requestOtp({bool isResend = false}) async {
    final email = _emailController.text.trim();

    if (!_formKey.currentState!.validate()) return;
    if (isResend && !canSendOtp(email)) {
      _showErrorDialog("You’ve reached the maximum number of OTP requests.");
      return;
    }

    if (_isLoading || _isResending) return;

    setState(() {
      isResend ? _isResending = true : _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(_requestOtpEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'purpose': 'password_reset'}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final expiresIn = body['expires_in'] ?? 180;

        increaseOtpCount(email);
        setOtpExpiry(email, expiresIn);
        _startTimer(duration: expiresIn);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP sent to your email.")),
        );

        if (!isResend) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChangePasswordScreen(email: email),
            ),
          );
        }
      } else {
        final body = jsonDecode(response.body);
        final error = body['detail'] ?? 'Failed to send OTP. Try again later.';
        _showErrorDialog(error);
      }
    } catch (_) {
      _showErrorDialog("Connection error. Please try again.");
    } finally {
      setState(() {
        _isLoading = false;
        _isResending = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = _emailController.text.trim();
    final canActuallyResend = _canResend && canSendOtp(email) && !_isResending;

    return Scaffold(
      appBar: appBar(context),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Text(
                    'Forgot Password',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 60),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.email),
                      labelText: 'Enter your email',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Email can't be empty";
                      }
                      final emailRegex = RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      );
                      if (!emailRegex.hasMatch(value)) {
                        return "Please enter a valid email address";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _requestOtp(),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    )
                        : const Text('Send OTP'),
                  ),
                  const SizedBox(height: 24),
                  if (_secondsRemaining > 0)
                    Text('Resend available in $_secondsRemaining seconds'),
                  if (_secondsRemaining == 0 && canSendOtp(email))
                    TextButton(
                      onPressed: canActuallyResend
                          ? () => _requestOtp(isResend: true)
                          : null,
                      child: _isResending
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Text("Didn't receive it? Resend OTP"),
                    ),
                  if (!canSendOtp(email))
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'You’ve reached the maximum resend limit.',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
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
