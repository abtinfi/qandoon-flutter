import 'package:bakery/screens/authentication/signup/signup_otp_screen.dart';
import 'package:flutter/material.dart';
import '/widget/app_bar.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _repeatPassword = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _visiblePassword = false;
  bool _visibleRepeatPassword = false;

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _email.dispose();
    _password.dispose();
    _repeatPassword.dispose();
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
                    'Sign Up',
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
                      } else if (value.length < 6) {
                        return "Password must be at least 6 characters";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 24),
                  TextFormField(
                    controller: _repeatPassword,
                    keyboardType: TextInputType.text,
                    obscureText: !_visibleRepeatPassword,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _visibleRepeatPassword = !_visibleRepeatPassword;
                          });
                        },
                        icon: Icon(
                          _visibleRepeatPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                      prefixIcon: Icon(Icons.lock_reset),
                      label: Text('repeat password'),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Repeat Password can't be empty";
                      }
                      if (_password.text != _repeatPassword.text) {
                        return "Passwords do not match";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        String email = _email.text;
                        String password = _password.text;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (context) => SignupOTPScreen(
                                  email: email,
                                  password: password,
                                ),
                          ),
                        );
                      }
                    },
                    child: Text('Sign Up'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Already have an account? Login'),
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
