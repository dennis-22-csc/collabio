import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:collabio/model.dart';
import 'package:provider/provider.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  UserCredential? userCredential;
  bool isObscure= false;
  late ProfileInfoModel profileInfoModel;

  Future<void> registerUser(String email, String password) async {
    
    try {
      userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      showStatusDialog('Success in registration', 'Please verify email');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        showStatusDialog('You already have an account', 'Please proceed to login');
      } else {
        // User registration failed
        showStatusDialog('Error in registration', '$e');
      }     
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  profileInfoModel = Provider.of<ProfileInfoModel>(context, listen: false);
   
  return Scaffold(
    appBar: AppBar(
      title: const Text('Create Account'),
    ),
    resizeToAvoidBottomInset: false,
    body: SingleChildScrollView(
      child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
              obscureText: !isObscure,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                    icon: Icon(isObscure ? Icons.visibility : Icons.visibility_off,),
                    onPressed: () {
                      setState(() {
                        isObscure = !isObscure;
                      });
                    },
                  ),
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
                  registerUser(email, password);
                }
              },
              child: const Text('Register'),
            ),
            const SizedBox(height: 16.0),
            Column(
              children: [
                const Text(
                  'Already registered?',
                  style: TextStyle(
                    fontSize: 16.0,
                  ),
                ),
                const SizedBox(height: 8.0),
                ElevatedButton(
                  onPressed: () {
                    context.goNamed("login");
                  },
                  child: const Text('Login'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  ));
}

void showStatusDialog(String title, String content){
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (title == 'Success in registration') {
                  context.goNamed("email-verification");
                }else if (title == "You already have an account") {
                  context.goNamed("login");
                } else {
                  context.pop();
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
}


}