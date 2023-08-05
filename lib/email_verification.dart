import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:collabio/project_page.dart';


class EmailVerificationScreen extends StatefulWidget {
  final User? user;

  // Constructor for user parameter
  const EmailVerificationScreen.withUser({Key? key, required this.user}) : super(key: key);


  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool isEmailVerified = false;
  Timer? timer;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (widget.user != null) {
      // User parameter is provided, handle user verification
      handleUserVerification();
    }
  }

  void handleUserVerification() {
    final user = widget.user;
    // Perform user verification process
    user?.sendEmailVerification();
    timer =
        Timer.periodic(const Duration(seconds: 3), (_) => checkEmailVerified());
  }
  checkEmailVerified() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    await currentUser?.reload();

    setState(() {
      isEmailVerified = currentUser?.emailVerified ?? false;
    });

    if (isEmailVerified) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email Successfully Verified")),
        );
      });

      timer?.cancel();

      // Redirect to the project page
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyProjectPage()),
        );
      });
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null && currentUser.emailVerified) {
      // User has already verified their email, redirect to project screen
      return const MyProjectPage();
    } else {
      return SafeArea(
        child: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 35),
                const SizedBox(height: 30),
                const Center(
                  child: Text(
                    'Check your \n Email',
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Center(
                    child: Text(
                      'We have sent you an email on ${currentUser?.email}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.0),
                  child: Center(
                    child: Text(
                      'Verifying email....',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 57),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: ElevatedButton(
                    child: const Text('Resend'),
                    onPressed: () {
                      try {
                        currentUser?.sendEmailVerification();
                      } catch (e) {
                        debugPrint('$e');
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

}