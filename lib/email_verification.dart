import 'dart:async';
import 'package:flutter/material.dart';
import 'package:collabio/model.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class EmailVerificationScreen extends StatefulWidget {
  
  const EmailVerificationScreen({Key? key}) : super(key: key);


  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? timer;
  late ProfileInfoModel profileInfoModel;

  @override
  void initState() {
    super.initState();
    profileInfoModel = Provider.of<ProfileInfoModel>(context, listen: false);

    if (profileInfoModel.user != null && !profileInfoModel.user!.emailVerified) {
      handleUserVerification();
    }
  }

  Future<void> handleUserVerification() async {
    // Perform user verification process
    profileInfoModel.user?.sendEmailVerification();
    timer = Timer.periodic(const Duration(seconds: 3), (_) => checkEmailVerified());
  }

  Future<void> checkEmailVerified() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    await currentUser?.reload();

    if (currentUser?.emailVerified == true) {
      showStatusDialog(currentUser, "Email Successfully Verified");
    }
  }


  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                          'We have sent a verification email to ${profileInfoModel.user?.email}',
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
                            profileInfoModel.user?.sendEmailVerification();
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

  void showStatusDialog(User? currentUser, String content){
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Hi there"),
          content: Text(content),
          actions: [
            ElevatedButton(
              onPressed: () {
                context.goNamed("login");
                 profileInfoModel.updateUserTemp(currentUser);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
}

}