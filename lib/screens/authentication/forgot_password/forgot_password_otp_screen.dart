import 'package:flutter/material.dart';
import '../signup/signup_screen.dart';
import '/widget/app_bar.dart';
import 'change_password_screen.dart';

class ForgotPasswordOTPScreen extends StatefulWidget {
  const ForgotPasswordOTPScreen({super.key});

  @override
  State<ForgotPasswordOTPScreen> createState() =>
      _ForgotPasswordOTPScreenState();
}

class _ForgotPasswordOTPScreenState extends State<ForgotPasswordOTPScreen> {
  final TextEditingController _email = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _email.dispose();
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
                    'Forgot Password',
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
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        String email = _email.text;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (context) => ChangePasswordScreen(email: email),
                          ),
                        );
                      }
                    },
                    child: Text('Send OTP'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SignupScreen(),
                        ),
                      );
                    },
                    child: Text('Don’t have an account? Sign up'),
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
