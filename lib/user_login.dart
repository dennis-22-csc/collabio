import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:collabio/email_verification.dart';
import 'package:collabio/user_registeration.dart';
import 'package:collabio/util.dart';
import 'package:collabio/project_page.dart';
import 'package:collabio/network_handler.dart';
import 'package:collabio/password_reset_screen.dart';
import 'package:collabio/database.dart';
import 'package:collabio/model.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:collabio/view_profile.dart';
import 'package:collabio/view_project.dart';
import 'package:collabio/post_project.dart';
import 'package:collabio/inbox_screen.dart';
import 'package:collabio/chat_screen.dart';
import 'package:collabio/create_profile.dart';

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
  bool _login = false;
  bool _hasProfile = false;
  
  @override
  void initState() {
    super.initState();
    syncData();
  }

Future<void> syncData() async {
    await getProfileInfo();
    await initDatabase();
  }

Future<void> getProfileInfo() async {
    bool myProfile = await SharedPreferencesUtil.hasProfile();
   
    setState(() {
      _hasProfile = myProfile;
    });
  }

  Future<void> loginUser(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user?.emailVerified == true) {
        // Get and set profile info in cases where app data was cleared
        if (!_hasProfile) {
          final fetchResult = await fetchUserInfoFromApi(email);
          if (fetchResult is Map<String, dynamic>) {
            SharedPreferencesUtil.setUserInfo(fetchResult);
            SharedPreferencesUtil.setHasProfile(true);
          }
        }
        SharedPreferencesUtil.setLoggedOut(false);
        if (!mounted) return;
        final profileInfoModel = Provider.of<ProfileInfoModel>(context, listen: false);
        await profileInfoModel.updateProfileInfo();
        setState(() {
        _login = true;
      });
        // Fetch dependencies
        await fetchApiData(userCredential.user!, email);
      } else {     
        // User registration successful but not yet verified, navigate to email verification screen
        if (!mounted) return;
        context.goNamed("email-verification", extra: userCredential.user);
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
      final projectResult = await fetchProjectsFromApi();
      final List<String> receivedMessageIds = await DatabaseHelper.getMessageIdsWithStatus("received");

      if (projectResult is List<Project>) {
        await DatabaseHelper.insertProjects(projectResult);
        List<String> tags = (await SharedPreferencesUtil.getTags()) ?? ["mobile app development", "web development"];
        if (!mounted) return;
        final projectsModel = Provider.of<ProjectsModel>(context, listen: false);
        projectsModel.updateProjects(tags, 10);
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

      if (!mounted) return;
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
  appTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    );
   final goRouter = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            if (!_login) {
              return MaterialApp(
                theme: appTheme,
                home: buildLoginScreen(),
              );
            }
            if (!_fetchCompleted) {
              return _buildLoadingIndicator();
            }
            if (_errorOccurred) {
              return _buildErrorScreen();
            }
            return MaterialApp(
              theme: appTheme,
              home: const MyProjectPage(),
              );
          },
        ),
        GoRoute(
          name: "login",
          path: '/login',
          pageBuilder: (context, state) => MaterialPage<void>(
            key: state.pageKey,
            child: const LoginScreen(),
          ),
        ),
        GoRoute(
          name: "registration",
          path: '/registration',
          pageBuilder: (context, state) => MaterialPage<void>(
            key: state.pageKey,
            child: const RegistrationScreen(),
          ),
        ),
        GoRoute(
          name: "projects",
          path: '/projects',
          pageBuilder: (context, state) => MaterialPage<void>(
            key: state.pageKey,
            child: const MyProjectPage(),
          ),
        ),
        GoRoute(
          name: "view-profile",
          path: '/view-profile',
          pageBuilder: (context, state) => MaterialPage<void>(
            key: state.pageKey,
            child: const ProfileSectionScreen(),
          ),
        ),
        GoRoute(
          name: "view-project",
          path: '/view-project',
          pageBuilder: (context, state) {
            final Project project = state.extra as Project;
            final viewProjectScreen = ViewProjectScreen(project: project);
            return MaterialPage<void>(
              key: state.pageKey,
              child: viewProjectScreen,
            );
          },
        ),
        GoRoute(
          name: "post-project",
          path: '/post-project',
          pageBuilder: (context, state) => MaterialPage<void>(
            key: state.pageKey,
            child: const ProjectUploadScreen(),
          ),
        ),
        GoRoute(
          name: "password-reset",
          path: '/password-reset',
          pageBuilder: (context, state) => MaterialPage<void>(
            key: state.pageKey,
            child: const PasswordResetScreen(),
          ),
        ),
        GoRoute(
          name: 'inbox',
          path: '/inbox/:currentUserName/:currentUserEmail',
          pageBuilder: (context, state) => MaterialPage<void>(
            key: state.pageKey,
            child: InboxScreen(currentUserName: state.pathParameters["currentUserName"]!, currentUserEmail: state.pathParameters["currentUserEmail"]!,),
          ),
        ),
        GoRoute(
          name: "email-verification",
          path: '/email-verification',
          pageBuilder: (context, state) {
            final User user = state.extra as User;
            final emailVerificationScreen = EmailVerificationScreen.withUser(user: user);
            return MaterialPage<void>(
              key: state.pageKey,
              child: emailVerificationScreen,
            );
          },
        ),
        GoRoute(
          name: "create-profile",
          path: '/create-profile',
          pageBuilder: (context, state) => MaterialPage<void>(
            key: state.pageKey,
            child: const ProfileScreen(),
          ),
        ),
        GoRoute(
          name: "chat",
          path: '/chat/:currentUserName/:currentUserEmail/:otherPartyName/:otherPartyEmail',
          pageBuilder: (context, state) => MaterialPage<void>(
            key: state.pageKey,
            child: ChatScreen(currentUserName: state.pathParameters["currentUserName"]!, currentUserEmail: state.pathParameters["currentUserEmail"]!, otherPartyName: state.pathParameters["otherPartyName"]!, otherPartyEmail: state.pathParameters["otherPartyEmail"]!),
          ),
        ),
      ],
    );

    return MaterialApp.router(
      theme: appTheme,
      routeInformationProvider: goRouter.routeInformationProvider,
      routerDelegate: goRouter.routerDelegate,
      routeInformationParser: goRouter.routeInformationParser,
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
                       context.goNamed("registration");
                    },
                    child: const Text('Create Account'),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  context.goNamed("password-reset");
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