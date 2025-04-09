import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../widget/app_bar.dart';
import '../../../utils/otp_tracker.dart';

class SignupOTPScreen extends StatefulWidget {
  final String email;
  final String password;

  const SignupOTPScreen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<SignupOTPScreen> createState() => _SignupOTPScreenState();
}

class _SignupOTPScreenState extends State<SignupOTPScreen> {
  int _secondsRemaining = 0;
  Timer? _timer;
  bool _canResend = false;

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
                    // TODO: SEND OTP To Backend
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Validate OTP
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
