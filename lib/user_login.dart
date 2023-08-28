import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:collabio/util.dart';
import 'package:collabio/project_page.dart';
import 'package:collabio/network_handler.dart';
import 'package:collabio/database.dart';
import 'package:collabio/model.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

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
  bool _fetchCompleted = false;
  bool _errorOccurred = false;
  String _errorMessage = "null";
  late ThemeData appTheme;
  late ProfileInfoModel profileInfoModel;
  late bool _hasProfile;
  bool _login = false;
  bool isObscure= false;

  @override
  void initState() {
    super.initState();
    initDatabase();
  }



  Future<void> loginUser(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user?.emailVerified == true) {
        SharedPreferencesUtil.setLogInStatus(true);
        profileInfoModel.updateLogInUserStatus();
        profileInfoModel.updateUserTemp(userCredential.user);
        setState(() {
        _login = true;
        });
        // Fetch dependencies
        await fetchApiData(userCredential.user!, email);
      } else {     
        // User registration successful but not yet verified, navigate to email verification screen
        //WidgetsBinding.instance.addPostFrameCallback((_) async {
        //context.goNamed("email-verification", extra: userCredential.user);
        //});
      }
    } on FirebaseAuthException catch (e) {
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
      _showError(message);
    }
  }

  Future<void> fetchApiData(User user, String email) async {
    try {
      if (!_hasProfile) {
          final fetchResult = await fetchUserInfoFromApi(email);
          if (fetchResult is Map<String, dynamic>) {
            await SharedPreferencesUtil.setUserInfo(fetchResult);
            await SharedPreferencesUtil.setHasProfile(true);
            bool storagePermitted = await Util.requestPermission(Permission.storage);
            if (!storagePermitted) {
              _showError("You need to grant storage access for media storage");
              await _auth.signOut();
              await SharedPreferencesUtil.setHasProfile(false);
              await profileInfoModel.updateProfileInfo();
              SharedPreferencesUtil.setLogOutStatus(true);
              profileInfoModel.updateLogOutUserStatus();
            }
            await Util.saveProfilePicture(fetchResult["pictureBytes"]);
            await profileInfoModel.updateProfileInfo();
          } else {
            _showError("Unable to fetch dependencies at the moment.");
            //_showError(fetchResult);
            return;
          } 
      }
          
      final projectResult = await fetchProjectsFromApi();
      final List<String> receivedMessageIds = await DatabaseHelper.getMessageIdsWithStatus("received");

      if (projectResult is List<Project>) {
        await DatabaseHelper.insertProjects(projectResult);
        List<String> tags = (await SharedPreferencesUtil.getTags());
        WidgetsBinding.instance.addPostFrameCallback((_) async {
        final projectsModel = Provider.of<ProjectsModel>(context, listen: false);
        projectsModel.updateProjects(tags, 10);
        });
      } else {
        _showError("Unable to fetch dependencies at the moment.");
        //_showError(projectResult);
        return;
      }

      dynamic messageResult = await fetchMessagesFromApi(email);
      if (messageResult is List<Message>) {
        await DatabaseHelper.insertMessages(messageResult);
      } else {
        _showError("Unable to fetch dependencies at the moment.");
        //_showError(messageResult);
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) async {
      //Get initial messages from local database
      final messagesModel = Provider.of<MessagesModel>(context, listen: false);
      messagesModel.updateGroupedMessages(email);

      //Set up web socket for new messages
      await connectToSocket(messagesModel, email);

      // Resend unsent messages
      final messages = await DatabaseHelper.getUnsentMessages();
      if (messages.isNotEmpty) {
        for (var message in messages) {
          await sendMessageData(messagesModel, message, email);
        }
      }
      });
      
      if (receivedMessageIds.isNotEmpty) {
        await deleteMessages(receivedMessageIds); 
      }

      setState(() {
        _fetchCompleted = true;
      });
    } catch (error) {
      _showError("Unable to fetch dependencies at the moment.");
      //_showError("An error occurred: $error");
    }
  }

  void _showError(String errorMessage) {
    setState(() {
      _errorOccurred = true;
      _errorMessage = errorMessage;
      _fetchCompleted = true;
      _login = true;
    });
  }

  Future<void> initDatabase() async {
    await DatabaseHelper.initDatabase();
  }

  @override
  void dispose(){
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  

  @override
Widget build(BuildContext context) {
  profileInfoModel = Provider.of<ProfileInfoModel>(context, listen: false);
  _hasProfile = profileInfoModel.hasProfile;

  appTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    );

    if (!_login) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        home: buildLoginScreen(),
      );
    }
    if (!_fetchCompleted) return _buildLoadingIndicator();
            
    if (_errorOccurred) return _buildErrorScreen();
            
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const MyProjectPage(),
      );
  }

Widget buildLoginScreen() {
  
  return Scaffold(
    appBar: AppBar(
      title: const Text('Login'),
    ),
    resizeToAvoidBottomInset: false,
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
                       profileInfoModel.updateLogOutUserStatusTemp(false);
                    },
                    child: const Text('Create Account'),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  profileInfoModel.updateForgotPasswordTemp(true);
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

Widget _buildLoadingIndicator() {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const Scaffold(
        backgroundColor: Color(0xFFEBDDFF),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Fetching dependencies",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: Scaffold(
        body: Center(
          child: AlertDialog(
            title: const Text('Hi there'),
            content: Text(_errorMessage),
            actions: [
              TextButton(
                onPressed: () {
                 setState(() {
                  _errorOccurred = false;
                  _fetchCompleted = false;
                  _login = false;
                });
                },
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      ),
    );
  }


}