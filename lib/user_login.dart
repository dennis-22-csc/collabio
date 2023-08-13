import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:collabio/email_verification.dart';
import 'package:collabio/user_registeration.dart';
import 'package:collabio/util.dart';
import 'package:collabio/project_page.dart';
import 'package:collabio/network_handler.dart';
import 'package:collabio/password_reset_screen.dart';

class LoginScreen extends StatefulWidget {

  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  bool hasProfile = false; 

  Future<void> loginUser(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user?.emailVerified == true) {
        // Get and set profile info in cases where app data was cleared
        if (!hasProfile) {
          final fetchResult = await fetchUserInfoFromApi(email);
          if (fetchResult is Map<String, dynamic>) {
            SharedPreferencesUtil.setUserInfo(fetchResult);
            SharedPreferencesUtil.setHasProfile(true);
          }
        }
        SharedPreferencesUtil.setLoggedOut(false);
        // User login successful and email verified, show project page
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
              builder: (context) => const MyProjectPage(),
          ),
          );
        });
      } else {
        // User registration successful but not yet verified, navigate to email verification screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => EmailVerificationScreen.withUser(user: userCredential.user),
            ),
          );
        });
      }
    } on FirebaseAuthException catch (e) {
      // User login failed
      String message;
      if (e.code == 'invalid-email') {
        message = 'The email address is invalid.';
      } else if (e.code == 'wrong-password') {
        message = 'The password is incorrect.';
      } else if (e.code == 'user-disabled') {
        message = 'The user account has been disabled, please re-register.';
      } else if (e.code == 'user-not-found') {
        message = 'The user account was not found, please register.';
      } else {
        message = 'Authentication error';
      }
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Login Failed'),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  void dispose(){
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Login'),
    ),
    resizeToAvoidBottomInset: false, // Prevents the keyboard from causing overflow
    body: SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter your email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    String email = _emailController.text.trim();
                    String password = _passwordController.text;
                    loginUser(email, password);
                  }
                },
                child: const Text('Login'),
              ),
              const SizedBox(height: 16.0),
              Column(
                children: [
                  const Text(
                    "Don't yet have an account?",
                    style: TextStyle(
                      fontSize: 16.0,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegistrationScreen(),
                        ),
                      );
                    },
                    child: const Text('Create Account'),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PasswordResetScreen(),
                    ),
                  );
                },
                child: const Text('Forgot Password?'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

}