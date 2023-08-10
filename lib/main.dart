import 'package:collabio/util.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  late ThemeData appTheme;

  @override
  void initState() {
    super.initState();
    initializeFirebase().then((_) {
      if (mounted) {
        setState(() {
          user = FirebaseAuth.instance.currentUser;
        });
      }
    });
    checkIsLoggedOut();
    initDatabase();
    fetchApiData(); 
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


  Future<void> fetchApiData() async {
    try {
      final projectResult = await fetchProjectsFromApi();
      final messageResult = await fetchMessagesFromApi("denniskoko@gmail.com");

      if (projectResult is List<Project>) {
        await DatabaseHelper.insertProjects(projectResult);
      } else {
        _showError(projectResult);
        return;
      }

      if (messageResult is List<Message>) {
        await DatabaseHelper.insertMessages(messageResult);
      } else {
        _showError(messageResult);
        return;
      }

      // Check for any failed UUIDs in shared preferences
      //final failedUuids = await SharedPreferencesUtil.fetchFailedIdsFromSharedPrefs();

      // Include the failed UUIDs along with the newly inserted UUIDs
      //final allUuids = [...insertedIds, ...failedUuids];

      // Call the /del-messages API with all UUIDs (both inserted and failed)
      //await deleteMessages(allUuids);
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        //Get initial messages from local database
        final messagesModel = Provider.of<MessagesModel>(context, listen: false);
        messagesModel.updateGroupedMessages("denniskoko@gmail.com");

        //Set up web socket for new messages
        final socketResult = await connectToSocket(messagesModel, "denniskoko@gmail.com");
        if (socketResult != "Connection successful") {
          _showError(socketResult);
          return;
        }
      });
      
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
      home: buildReloadFutureBuilder(),
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

  Widget buildReloadFutureBuilder() {
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
        future: user?.reload(),
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
  }
   
}