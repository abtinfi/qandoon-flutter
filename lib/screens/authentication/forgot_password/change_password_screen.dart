import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../widget/app_bar.dart';
import '../../../utils/otp_tracker.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String email;

  const ChangePasswordScreen({super.key, required this.email});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController repeatPasswordController =
      TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool _visiblePassword = false;
  bool _visibleRepeatPassword = false;

  int _secondsRemaining = 0;
  Timer? _timer;
  bool _canResend = false;
  String? otpCode;

  @override
  void initState() {
    super.initState();

    if (!otpExpiryMap.containsKey(widget.email)) {
      increaseOtpCount(widget.email);
      _secondsRemaining = remainingTime(widget.email);
      _startTimer();

      // TODO: Send OTP API call
      _canResend = false;
    } else {
      _secondsRemaining = remainingTime(widget.email);
      if (_secondsRemaining > 0) {
        _startTimer();
        _canResend = false;
      } else {
        _canResend = true;
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = remainingTime(widget.email);
      if (remaining == 0) {
        timer.cancel();
        setState(() {
          _canResend = true;
          _secondsRemaining = 0;
        });
      } else {
        setState(() {
          _secondsRemaining = remaining;
          _canResend = false;
        });
      }
    });
  }

  void _resendOtp() {
    if (!_canResend || !canSendOtp(widget.email)) return;

    increaseOtpCount(widget.email);
    _startTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "OTP sent again (${otpRequestCount[widget.email]}/$maxAttempts)",
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                Text("An OTP has been sent to ${widget.email}"),
                const SizedBox(height: 20),
                PinCodeTextField(
                  appContext: context,
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
                    otpCode = value;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) {
                        return StatefulBuilder(
                          builder: (context, setStateDialog) {
                            return AlertDialog(
                              titlePadding: const EdgeInsets.only(
                                top: 16,
                                right: 16,
                                left: 24,
                                bottom: 8,
                              ),
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Reset Password"),
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: const Icon(Icons.close),
                                  ),
                                ],
                              ),
                              content: Form(
                                key: formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextFormField(
                                      obscureText: !_visiblePassword,
                                      controller: newPasswordController,
                                      keyboardType:
                                          TextInputType.visiblePassword,
                                      decoration: InputDecoration(
                                        labelText: "New Password",
                                        prefixIcon: const Icon(
                                          Icons.lock_outline,
                                        ),
                                        suffixIcon: IconButton(
                                          onPressed: () {
                                            setStateDialog(() {
                                              _visiblePassword =
                                                  !_visiblePassword;
                                            });
                                          },
                                          icon: Icon(
                                            _visiblePassword
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return "Enter a new password";
                                        } else if (value.length < 6) {
                                          return "Password must be at least 6 characters";
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      obscureText: !_visibleRepeatPassword,
                                      controller: repeatPasswordController,
                                      keyboardType:
                                          TextInputType.visiblePassword,
                                      decoration: InputDecoration(
                                        labelText: "Repeat Password",
                                        prefixIcon: const Icon(
                                          Icons.lock_reset,
                                        ),
                                        suffixIcon: IconButton(
                                          onPressed: () {
                                            setStateDialog(() {
                                              _visibleRepeatPassword =
                                                  !_visibleRepeatPassword;
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
                                          return "Repeat your password";
                                        }
                                        if (value !=
                                            newPasswordController.text) {
                                          return "Passwords do not match";
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                ElevatedButton(
                                  onPressed: () {
                                    if (formKey.currentState!.validate()) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Password changed successfully!",
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text("Confirm"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                  child: const Text("Verify"),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed:
                      (_canResend && canSendOtp(widget.email))
                          ? _resendOtp
                          : null,
                  child: Text(
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
