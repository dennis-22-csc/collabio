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
  bool isLoggedOut = false;
  bool _fetchCompleted = false;
  bool _errorOccurred = false;
  String _errorMessage = "null";
  User? user;
  String? _email;
  late ThemeData appTheme;
  late FirebaseAuth _auth;

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
      await checkIsLoggedOut();
      loadData();
    }
  }

  Future<void> loadData() async {
    if (_auth.currentUser != null) {
      await _auth.currentUser!.reload();
      setState(() {
        user = _auth.currentUser;
      });
      _setEmail();
      initDatabase();
      fetchApiData();
    } else {
      setState(() {
        _fetchCompleted = true;
      });
    }
  }
  Future<void> checkIsLoggedOut() async {
    bool loggedOut = await SharedPreferencesUtil.isLoggedOut();
    setState(() {
      isLoggedOut = loggedOut;
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

  Future<void> fetchApiData() async {
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
        _fetchCompleted = true;
      });
    } catch (error) {
      _showError("An error occurred: $error");
    }
  }

  void _showError(String errorMessage) {
    setState(() {
      _errorOccurred = true;
      _errorMessage = errorMessage;
      _fetchCompleted = true;
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

     if (!_fetchCompleted) {
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

  /*Widget buildReloadFutureBuilder() {
    if (user == null) {
      if (isLoggedOut == true) {
        // user has an account, but logged out
        return const LoginScreen();
      } else {
        // User doesn't have an account, show registration screen
        return const RegistrationScreen();
      }

    } else {
      return FutureBuilder<void>(
        future: _reloadUser(),
        builder: (BuildContext context, AsyncSnapshot<void> reloadSnapshot) {
          if (reloadSnapshot.connectionState == ConnectionState.waiting) {
            // Reloading user data, show loading indicator
            return Scaffold(
              body: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(appTheme.colorScheme.onPrimary), backgroundColor: appTheme.colorScheme.onBackground,
                    ),
                ),
            );
          } else if (reloadSnapshot.hasError) {
            // Handle reload error
            final error = reloadSnapshot.error;

              return AlertDialog(
                  title: const Text('Error'),
                  content: Text('An error occurred: ${error.toString()}'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
              );

          } else {
            // User data reload successful, check if the email is null
            if (user?.email == null) {
              // User has been deleted, show the registration screen
              return const RegistrationScreen();
            } else if (user?.emailVerified == null) {
              // User is not verified, show the login screen
              return const LoginScreen();
            } else {
              // User exists, is logged in, and verified, show the project page
              return const MyProjectPage();
            }
          }
        },
      );
    }
  }*/

  Widget buildMainScreen() {
    if (user == null) {
      if (isLoggedOut == true) {
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