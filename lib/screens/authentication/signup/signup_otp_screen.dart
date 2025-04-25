import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../widget/app_bar.dart';
import '../../../utils/otp_tracker.dart';
import '../login/login_screen.dart';
import '../auth_check_screen.dart';

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

class SignupOTPScreen extends StatefulWidget {
  final String email;

  const SignupOTPScreen({super.key, required this.email});

  @override
  State<SignupOTPScreen> createState() => _SignupOTPScreenState();
}

class _SignupOTPScreenState extends State<SignupOTPScreen> {
  final TextEditingController _otpController = TextEditingController();

  int _secondsRemaining = 0;
  Timer? _timer;
  bool _canResend = false;

  bool _isLoadingVerify = false;
  bool _isLoadingResend = false;

  final String _verifyEndpoint = 'https://api.abtinfi.ir/users/verify-email';
  final String _requestOtpEndpoint = 'https://api.abtinfi.ir/users/request-otp';

  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();

    if (!otpExpiryMap.containsKey(widget.email) ||
        remainingTime(widget.email) <= 0) {
      increaseOtpCount(widget.email);
      _secondsRemaining = remainingTime(widget.email);
      _startTimer();
      _canResend = false;
    } else {
      _secondsRemaining = remainingTime(widget.email);
      _startTimer();
      _canResend = false;
    }

    if (remainingTime(widget.email) == 0 && canSendOtp(widget.email)) {
      _canResend = true;
    }
  }

  void _startTimer({int durationInSeconds = 300}) {
    _timer?.cancel();

    int initialSeconds =
        remainingTime(widget.email) > 0
            ? remainingTime(widget.email)
            : durationInSeconds;
    if (initialSeconds <= 0) {
      setState(() {
        _canResend = true;
        _secondsRemaining = 0;
      });
      return;
    }

    _secondsRemaining = initialSeconds;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 0) {
        timer.cancel();
        setState(() {
          _canResend = true;
          _secondsRemaining = 0;
        });
      } else {
        setState(() {
          _secondsRemaining--;
          _canResend = false;
        });
      }
    });
  }

  Future<void> _requestNewOtp() async {
    if (!_canResend || !canSendOtp(widget.email) || _isLoadingResend) return;

    setState(() {
      _isLoadingResend = true;
    });

    try {
      final response = await http.post(
        Uri.parse(_requestOtpEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email, 'purpose': 'registration'}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        int expiresIn = 300;
        if (responseBody != null && responseBody['expires_in'] != null) {
          expiresIn = responseBody['expires_in'];
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("New OTP sent successfully!")),
        );
        increaseOtpCount(widget.email);
        setOtpExpiry(widget.email, expiresIn);
        _startTimer(durationInSeconds: expiresIn);
      } else if (response.statusCode == 400) {
        final errorBody = jsonDecode(response.body);
        String errorMessage = 'Failed to request new OTP.';
        if (errorBody != null && errorBody['detail'] != null) {
          errorMessage = errorBody['detail'];
          if (errorMessage == "Email already registered and verified") {
            _showErrorDialog(
              context,
              "Your email is already verified. Please log in.",
            );
            return;
          } else if (errorMessage.contains(
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
          'Failed to request new OTP. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showErrorDialog(
        context,
        'An error occurred while requesting OTP. Please try again.',
      );
    } finally {
      setState(() {
        _isLoadingResend = false;
      });
      setState(() {
        _canResend =
            remainingTime(widget.email) <= 0 && canSendOtp(widget.email);
      });
    }
  }

  Future<void> _verifyOtp(String otpCode) async {
    if (_isLoadingVerify) return;

    if (otpCode.length != 5) {
      _showErrorDialog(context, "Please enter the full 5-digit code.");
      return;
    }

    setState(() {
      _isLoadingVerify = true;
    });

    try {
      final response = await http.post(
        Uri.parse(_verifyEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email, 'code': otpCode}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final String? accessToken = responseBody['access_token'];
        final String? tokenType = responseBody['token_type'];

        if (accessToken != null && tokenType != null) {
          await _storage.write(key: 'jwt_token', value: accessToken);

          if (!mounted) return;

          resetOtpTracker(widget.email);

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AuthCheckScreen()),
          );
        } else {
          _showErrorDialog(
            context,
            'Verification failed: Invalid response format from server.',
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } else if (response.statusCode == 400) {
        final errorBody = jsonDecode(response.body);
        String errorMessage = 'Invalid or expired OTP.';
        if (errorBody != null && errorBody['detail'] != null) {
          errorMessage = errorBody['detail'];
        }
        _showErrorDialog(context, errorMessage);
        _otpController.clear();
      } else {
        _showErrorDialog(
          context,
          'Verification failed. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showErrorDialog(
        context,
        'An error occurred during verification. Please check your connection.',
      );
    } finally {
      setState(() {
        _isLoadingVerify = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool actualCanResend =
        _canResend && canSendOtp(widget.email) && !_isLoadingResend;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: appBar(context),
        body: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(), // Added const
            padding: const EdgeInsets.all(24), // Added const
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Added
              children: [
                Text(
                  "An OTP has been sent to ${widget.email}",
                  textAlign: TextAlign.center, // Added
                  style: Theme.of(context).textTheme.titleMedium, // Added
                ),
                const SizedBox(height: 40), // Added some space
                PinCodeTextField(
                  appContext: context,
                  controller: _otpController,
                  length: 5,
                  obscureText: false,
                  animationType: AnimationType.fade,
                  keyboardType: TextInputType.number,
                  autoDismissKeyboard: true,
                  textStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(8),
                    fieldHeight: 55,
                    fieldWidth: 50,
                    activeFillColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade800
                            : Colors.white,
                    inactiveFillColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade700
                            : Colors.grey.shade200,
                    selectedFillColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade600
                            : Colors.grey.shade100,
                    activeColor: Theme.of(context).colorScheme.primary,
                    selectedColor: Theme.of(context).colorScheme.primary,
                    inactiveColor: Theme.of(context).disabledColor,
                    fieldOuterPadding: const EdgeInsets.symmetric(
                      horizontal: 2,
                    ),
                  ),
                  animationDuration: const Duration(milliseconds: 300),
                  enableActiveFill: true,
                  onCompleted: (value) {
                    _verifyOtp(value);
                  },
                  onChanged: (value) {},
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed:
                      _isLoadingVerify
                          ? null
                          : () {
                            _verifyOtp(_otpController.text);
                          },
                  child:
                      _isLoadingVerify
                          ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                          : const Text("Verify"),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: actualCanResend ? _requestNewOtp : null,
                  child:
                      _isLoadingResend
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.blue,
                              strokeWidth: 2,
                            ),
                          )
                          : Text(
                            !canSendOtp(widget.email)
                                ? "Maximum attempts reached"
                                : _canResend
                                ? "Resend OTP"
                                : "Resend in $_secondsRemaining seconds",
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
