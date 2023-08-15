import 'package:collabio/util.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:collabio/firebase_options.dart';
import 'package:collabio/user_login.dart';
import 'package:collabio/user_registeration.dart';
import 'package:device_preview/device_preview.dart';
import 'package:collabio/project_page.dart';
import 'package:collabio/network_handler.dart';
import 'package:collabio/database.dart';
import 'package:collabio/model.dart';
import 'dart:io';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    DevicePreview(
      enabled: false,
      builder: (context) => MultiProvider(
        providers: [
          ChangeNotifierProvider<MessagesModel>(create: (context) => MessagesModel()),
          ChangeNotifierProvider<ProjectsModel>(create: (context) => ProjectsModel()),
        ],
        child: MyApp(key: UniqueKey()),
      ),
    ),
  );
  
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isFirebaseInitialized = false;
  bool _hasProfile = false;
  bool _sentToken = false;
  bool _isLoggedOut = false;
  bool _networkOperationCompleted = false;
  bool _errorOccurred = false;
  String _errorMessage = "null";
  User? user;
  String? _email;
  late ThemeData appTheme;
  late FirebaseAuth _auth;
  late String _token; 

  @override
  void initState() {
    super.initState();
    initializeFirebaseAndLoadData();
  }

  Future<void> initializeFirebaseAndLoadData() async {
    await initializeFirebase();
    if (mounted) {
      setState(() {
        _auth = FirebaseAuth.instance;
      });
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      FirebaseMessaging.instance.subscribeToTopic('news');
      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        SharedPreferencesUtil.saveToken(token);
      });
      await getProfileInfo();
      syncData();
    }
  }

  Future<void> syncData() async {
    if (_auth.currentUser != null) {
      await _auth.currentUser!.reload();
      setState(() {
        user = _auth.currentUser;
      });
      _setEmail();
      initDatabase();
      performNetworkOperation();
    } else {
      setState(() {
        _networkOperationCompleted = true;
      });
    }
  }

  Future<void> getProfileInfo() async {
    bool myProfile = await SharedPreferencesUtil.hasProfile();
    bool sentToken = await SharedPreferencesUtil.sentToken();
    bool loggedOut = await SharedPreferencesUtil.isLoggedOut();
    String myToken = await SharedPreferencesUtil.getToken();

    setState(() {
      _hasProfile = myProfile;
      _sentToken = sentToken;
      _isLoggedOut = loggedOut;
      _token = myToken;
    });
  }
  
  Future<void> initDatabase() async {
    await DatabaseHelper.initDatabase();
  }

  Future<void> initializeFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    setState(() {
      _isFirebaseInitialized = true;

    });
  }

  Future<void> _setEmail() async {
    if (user != null) {
      if (user?.email != null) {
        setState(() {
          _email = user?.email;
        });
      }
    }
  }

  Future<void> performNetworkOperation() async {
    try {
      final projectResult = await fetchProjectsFromApi();
      final List<String> receivedMessageIds = await DatabaseHelper.getMessageIdsWithStatus("received");

      if (projectResult is List<Project>) {
        await DatabaseHelper.insertProjects(projectResult);
        List<String> tags = (await SharedPreferencesUtil.getTags()) ?? ["mobile app development", "web development"];
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final projectsModel = Provider.of<ProjectsModel>(context, listen: false);
          projectsModel.updateProjects(tags, 10);
        });
      } else {
        _showError(projectResult);
        return;
      }

      if(_hasProfile && !_sentToken) {
        dynamic tokenUpdateResult = await updateTokenSection(_email!, _token);
        if (tokenUpdateResult == "Token section updated successfully") {
          await SharedPreferencesUtil.setSentToken(true);
        } else {
          await SharedPreferencesUtil.setSentToken(false);
        }
      } 

      if (user != null && _email != null) {
        dynamic messageResult = await fetchMessagesFromApi(_email!);
        if (messageResult is List<Message>) {
            await DatabaseHelper.insertMessages(messageResult);
        } else {
          _showError(messageResult);
          return;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          //Get initial messages from local database
          final messagesModel = Provider.of<MessagesModel>(context, listen: false);
          messagesModel.updateGroupedMessages(_email!);

          //Set up web socket for new messages
          await connectToSocket(messagesModel, _email!);

          // Resend unsent messages
          final messages = await DatabaseHelper.getUnsentMessages();
          if (messages.isNotEmpty) {
            for (var message in messages) {
              await sendMessageData(messagesModel, message, _email!);
            }
          }
        
        });

      }

      if (receivedMessageIds.isNotEmpty) {
        await deleteMessages(receivedMessageIds); 
      }

      setState(() {
        _networkOperationCompleted = true;
      });
    } catch (error) {
      _showError("An error occurred: $error");
    }
  }

  void _showError(String errorMessage) {
    setState(() {
      _errorOccurred = true;
      _errorMessage = errorMessage;
      _networkOperationCompleted = true;
    });
  }


  @override
  Widget build(BuildContext context) {
    appTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    );

    if (!_isFirebaseInitialized) {
      return _buildLoadingIndicator();
    }

     if (!_networkOperationCompleted) {
      return _buildLoadingIndicator();
    }

    if (_errorOccurred) {
      return _buildErrorScreen();
    }

    return MaterialApp(
      theme: appTheme,
      home: buildMainScreen(),
    );
  }

  Widget _buildLoadingIndicator() {
    return MaterialApp(
      theme: appTheme,
      home: Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(appTheme.colorScheme.onPrimary),
            backgroundColor: appTheme.colorScheme.onBackground,
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
            title: const Text('Error'),
            content: Text(_errorMessage),
            actions: [
              TextButton(
                onPressed: () {
                  exit(0); // Terminate the app
                },
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget buildMainScreen() {
    if (user == null) {
      if (_isLoggedOut == true) {
        // user has an account, but logged out
        return const LoginScreen();
      } else {
        // User doesn't have an account, show registration screen
        return const RegistrationScreen();
      }
    }
    else {
      if (user?.email == null) {
        // User has been deleted, show the registration screen
        return const RegistrationScreen();
      } else if (user?.emailVerified == false) {
        // User is not verified, show the login screen
        return const LoginScreen();
      } else {
        // User exists, is logged in, and verified, show the project page
        return const MyProjectPage();
      }
    }
  }
}