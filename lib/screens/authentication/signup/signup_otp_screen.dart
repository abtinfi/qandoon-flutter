import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../utils/otp_tracker.dart';
import '../../../widget/app_bar.dart';
import '../auth_check_screen.dart';
import '../login/login_screen.dart';

class SignupOTPScreen extends StatefulWidget {
  final String email;

  const SignupOTPScreen({super.key, required this.email});

  @override
  State<SignupOTPScreen> createState() => _SignupOTPScreenState();
}

class _SignupOTPScreenState extends State<SignupOTPScreen> {
  final _otpController = TextEditingController();
  final _storage = const FlutterSecureStorage();

  Timer? _timer;
  int _secondsRemaining = 180; // 3 minutes
  bool _canResend = false;

  bool _isLoadingVerify = false;
  bool _isLoadingResend = false;

  final _verifyEndpoint = 'https://api.abtinfi.ir/users/verify-email';
  final _requestOtpEndpoint = 'https://api.abtinfi.ir/users/request-otp';

  @override
  void initState() {
    super.initState();
    _startOtpFlow();
  }

  void _startOtpFlow({int expiresIn = 180}) {
    setOtpExpiry(widget.email, expiresIn);
    increaseOtpCount(widget.email);
    _startTimer(duration: expiresIn);
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
          _canResend = true;
          _secondsRemaining = 0;
        });
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  Future<void> _requestNewOtp() async {
    if (_isLoadingResend || !canSendOtp(widget.email)) return;

    setState(() => _isLoadingResend = true);

    try {
      final response = await http.post(
        Uri.parse(_requestOtpEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email, 'purpose': 'registration'}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final expiresIn = responseBody['expires_in'] ?? 180;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A new OTP has been sent to your email.')),
        );

        _startOtpFlow(expiresIn: expiresIn);
      } else {
        final body = jsonDecode(response.body);
        final error = body['detail'] ?? 'Failed to resend OTP.';
        _showErrorDialog(error);
      }
    } catch (_) {
      _showErrorDialog('Network error while requesting new OTP.');
    } finally {
      setState(() => _isLoadingResend = false);
    }
  }

  Future<void> _verifyOtp(String code) async {
    if (code.length != 5 || _isLoadingVerify) return;

    setState(() => _isLoadingVerify = true);

    try {
      final response = await http.post(
        Uri.parse(_verifyEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email, 'code': code}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['access_token'];

        if (accessToken != null) {
          await _storage.write(key: 'jwt_token', value: accessToken);
          resetOtpTracker(widget.email);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AuthCheckScreen()),
          );
        } else {
          _showErrorDialog('Invalid response from server.');
        }
      } else if (response.statusCode == 400) {
        final body = jsonDecode(response.body);
        final error = body['detail'] ?? 'Invalid or expired OTP.';
        _showErrorDialog(error);
        _otpController.clear();
      } else {
        _showErrorDialog('Unexpected error. Code: ${response.statusCode}');
      }
    } catch (_) {
      _showErrorDialog('Network error. Please try again.');
    } finally {
      setState(() => _isLoadingVerify = false);
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
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canActuallyResend = _canResend && canSendOtp(widget.email);

    return Scaffold(
      appBar: appBar(context),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                Text(
                  'We have sent a 5-digit code to:',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.email,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                PinCodeTextField(
                  appContext: context,
                  controller: _otpController,
                  length: 5,
                  keyboardType: TextInputType.number,
                  animationType: AnimationType.fade,
                  enableActiveFill: true,
                  autoDismissKeyboard: true,
                  textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  animationDuration: const Duration(milliseconds: 180),
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(8),
                    fieldHeight: 55,
                    fieldWidth: 50,
                    activeFillColor: Colors.white,
                    selectedFillColor: Colors.grey.shade100,
                    inactiveFillColor: Colors.grey.shade200,
                    activeColor: Theme.of(context).primaryColor,
                    selectedColor: Theme.of(context).primaryColor,
                    inactiveColor: Theme.of(context).disabledColor,
                  ),
                  onCompleted: _verifyOtp,
                  onChanged: (_) {},
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoadingVerify ? null : () => _verifyOtp(_otpController.text),
                  child: _isLoadingVerify
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : const Text('Verify'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: canActuallyResend ? _requestNewOtp : null,
                  child: _isLoadingResend
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Text(
                    canActuallyResend
                        ? 'Resend OTP'
                        : 'Resend in $_secondsRemaining seconds',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
