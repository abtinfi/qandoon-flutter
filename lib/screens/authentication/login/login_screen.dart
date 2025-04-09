import 'package:bakery/screens/authentication/forgot_password/forgot_password_otp_screen.dart';
import 'package:flutter/material.dart';
import '../../../home_screens/home_screen.dart';
import '../signup/signup_screen.dart';
import '/widget/app_bar.dart';

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

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _email.dispose();
    _password.dispose();
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
                            builder: (context) => ForgotPasswordOTPScreen(),
                          ),
                        );
                      },
                      child: Text('Forgot Password?'),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        String email = _email.text;
                        String password = _password.text;
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => HomeScreen()),
                        );
                      }
                    },
                    child: Text('Login'),
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
