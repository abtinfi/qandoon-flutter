// screens/authentication/forgot_password/change_password_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../widget/app_bar.dart';
import '../../../utils/otp_tracker.dart';
import '../login/login_screen.dart';

void _showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
  );
}

class ChangePasswordScreen extends StatefulWidget {
  final String email;

  const ChangePasswordScreen({super.key, required this.email});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _otpController = TextEditingController();

  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _repeatPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _passwordFormKey = GlobalKey<FormState>();

  bool _visibleNewPassword = false;
  bool _visibleRepeatPassword = false;

  int _secondsRemaining = 0;
  Timer? _timer;
  bool _canResend = false;

  bool _isLoadingResend = false;
  bool _isLoadingReset = false;

  final String _requestOtpEndpoint = 'https://api.abtinfi.ir/users/request-otp';
  final String _resetPasswordEndpoint =
      'https://api.abtinfi.ir/users/reset-password';

  @override
  void initState() {
    super.initState();

    if (otpExpiryMap.containsKey(widget.email)) {
      _secondsRemaining = remainingTime(widget.email);
      if (_secondsRemaining > 0) {
        _startTimer();
        _canResend = false;
      } else {
        _canResend = canSendOtp(widget.email);
      }
    } else {
      print(
        'AuthCheckScreen: No OTP tracking data found for ${widget.email}. Navigating back to email entry.',
      );

      _secondsRemaining = 300;
      _startTimer();
      _canResend = false;
      increaseOtpCount(widget.email);
      setOtpExpiry(widget.email, 300);
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

  Future<void> _resendOtp() async {
    if (!_canResend || !canSendOtp(widget.email) || _isLoadingResend) return;

    setState(() {
      _isLoadingResend = true;
    });

    try {
      final response = await http.post(
        Uri.parse(_requestOtpEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email, 'purpose': 'password_reset'}),
      );

      print(
        'Request Password Reset OTP Status Code (Resend): ${response.statusCode}',
      );
      print(
        'Request Password Reset OTP Response Body (Resend): ${response.body}',
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        int expiresIn = 300;
        if (responseBody != null && responseBody['expires_in'] != null) {
          expiresIn = responseBody['expires_in'];
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("A new OTP must be sent successfully!")),
        );

        increaseOtpCount(widget.email);
        setOtpExpiry(widget.email, expiresIn);
        _startTimer(durationInSeconds: expiresIn);
      } else if (response.statusCode == 400) {
        final errorBody = jsonDecode(response.body);
        String errorMessage = 'Failed to request new OTP.';
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
          'Failed to request new OTP. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      _showErrorDialog(
        context,
        'An error occurred while requesting OTP. Please try again.',
      );
      print('Error requesting password reset OTP: $e');
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

  Future<void> _resetPassword() async {
    if (!_passwordFormKey.currentState!.validate()) {
      return;
    }

    if (_otpController.text.length != 5) {
      _showErrorDialog(context, "The OTP code must be entered first.");
      return;
    }

    setState(() {
      _isLoadingReset = true;
    });

    try {
      final response = await http.post(
        Uri.parse(_resetPasswordEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'code': _otpController.text,
          'new_password': _newPasswordController.text,
        }),
      );

      print('Reset Password Status Code: ${response.statusCode}');
      print('Reset Password Response Body: ${response.body}');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password must be reset successfully. Login is required."),
          ),
        );

        resetOtpTracker(widget.email);

        Navigator.of(context).pop();

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else if (response.statusCode == 400) {
        final errorBody = jsonDecode(response.body);
        String errorMessage = 'Failed to reset password.';
        if (errorBody != null && errorBody['detail'] != null) {
          errorMessage = errorBody['detail'];
          if (errorMessage == "Invalid OTP") {
            _showErrorDialog(context, errorMessage);
            _otpController.clear();
            _newPasswordController.clear();
            _repeatPasswordController.clear();
            return;
          }
        }
        _showErrorDialog(context, errorMessage);
      } else {
        _showErrorDialog(
          context,
          'Password reset failed. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      _showErrorDialog(
        context,
        'An error occurred while resetting password. Please try again.',
      );
    } finally {
      setState(() {
        _isLoadingReset = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _newPasswordController.dispose();
    _repeatPasswordController.dispose();
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
                  "Enter the OTP sent to ${widget.email}",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 40),
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
                    _showResetPasswordDialog(context);
                  },
                  onChanged: (value) {},
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (_otpController.text.length == 5) {
                      _showResetPasswordDialog(context);
                    } else {
                      _showErrorDialog(
                        context,
                        "The OTP code must be entered first.",
                      );
                    }
                  },
                  child: const Text("Verify"),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: actualCanResend ? _resendOtp : null,
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

  void _showResetPasswordDialog(BuildContext context) {
    _newPasswordController.clear();
    _repeatPasswordController.clear();
    _visibleNewPassword = false;
    _visibleRepeatPassword = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              titlePadding: const EdgeInsets.only(
                top: 16,
                right: 16,
                left: 24,
                bottom: 8,
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Reset Password"),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close),
                  ),
                ],
              ),
              content: Form(
                key: _passwordFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      obscureText: !_visibleNewPassword,
                      controller: _newPasswordController,
                      keyboardType: TextInputType.visiblePassword,
                      decoration: InputDecoration(
                        labelText: "New Password",
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setStateDialog(() {
                              _visibleNewPassword = !_visibleNewPassword;
                            });
                          },
                          icon: Icon(
                            _visibleNewPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "A new password must be entered";
                        } else if (value.length < 6) {
                          return "The password must be at least 6 characters";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      obscureText: !_visibleRepeatPassword,
                      controller: _repeatPasswordController,
                      keyboardType: TextInputType.visiblePassword,
                      decoration: InputDecoration(
                        labelText: "Repeat Password",
                        prefixIcon: const Icon(Icons.lock_reset),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setStateDialog(() {
                              _visibleRepeatPassword = !_visibleRepeatPassword;
                            });
                          },
                          icon: Icon(
                            _visibleRepeatPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "The password must be repeated";
                        }
                        if (value != _newPasswordController.text) {
                          return "Passwords must match";
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed:
                      _isLoadingReset
                          ? null
                          : () {
                            if (_passwordFormKey.currentState!.validate()) {
                              _resetPassword();
                            }
                          },
                  child:
                      _isLoadingReset
                          ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                          : const Text("Confirm"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
