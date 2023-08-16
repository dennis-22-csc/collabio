import 'package:collabio/util.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:collabio/user_login.dart';
import 'package:collabio/user_registeration.dart';
import 'package:device_preview/device_preview.dart';
import 'package:collabio/project_page.dart';
import 'package:collabio/network_handler.dart';
import 'package:collabio/database.dart';
import 'package:collabio/model.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

void main() async {
  late bool hasInternet;
  late bool loggedOut;
  String? email;
  User? user;

  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
            statusBarColor: Color(0xFFEBDDFF),
  ));
  hasInternet = await Util.checkInternetConnection();
  loggedOut = await SharedPreferencesUtil.isLoggedOut();

  if (hasInternet) {
    await Util.initializeFirebase();
    FirebaseAuth auth = FirebaseAuth.instance;
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    FirebaseMessaging.instance.subscribeToTopic('news');
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      SharedPreferencesUtil.saveToken(token);
    });

    if (auth.currentUser != null) {
      await auth.currentUser!.reload();
      user = auth.currentUser;

    if (user != null) {
      if (user.email != null) {
        email = user.email;
      } 
    }
  }
}
     
  runApp(
    DevicePreview(
      enabled: false,
      builder: (context) => MultiProvider(
        providers: [
          ChangeNotifierProvider<MessagesModel>(create: (context) => MessagesModel()),
          ChangeNotifierProvider<ProjectsModel>(create: (context) => ProjectsModel()),
        ],
        child: MyApp(key: UniqueKey(), hasInternet: hasInternet, isLoggedOut: loggedOut, user: user, email: email,),
      ),
    ),
  );
}


class MyApp extends StatefulWidget {
  final bool hasInternet; 
  final bool isLoggedOut;
  final String? email;
  final User? user;
  const MyApp({Key? key, required this.hasInternet, required this.isLoggedOut, required this.user, required this.email }) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _hasProfile = false;
  bool _sentToken = false;
  bool _networkOperationCompleted = false;
  bool _errorOccurred = false;
  String _errorMessage = "null";
  
 
  late ThemeData appTheme;
  late String _token; 
 
  @override
  void initState() {
    super.initState();
    if (!widget.hasInternet){
      _showError("Please turn on your internet connection.") ;
    } else if (widget.user != null){
      syncData();
    }
  }

  Future<void> syncData() async {
    await getProfileInfo();
    await loadData();
  }


  Future<void> loadData() async {
      await initDatabase();
      await performNetworkOperation();
  }

  Future<void> getProfileInfo() async {
    bool myProfile = await SharedPreferencesUtil.hasProfile();
    bool sentToken = await SharedPreferencesUtil.sentToken();
    String myToken = await SharedPreferencesUtil.getToken();

    setState(() {
      _hasProfile = myProfile;
      _sentToken = sentToken;
      _token = myToken;
    });
  }
  
  Future<void> initDatabase() async {
    await DatabaseHelper.initDatabase();
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
        _showError("Unable to fetch dependencies at the moment.");
        //_showError(projectResult);
        return;
      }

      if(_hasProfile && !_sentToken) {
        dynamic tokenUpdateResult = await updateTokenSection(widget.email!, _token);
        if (tokenUpdateResult == "Token section updated successfully") {
          await SharedPreferencesUtil.setSentToken(true);
        } else {
          await SharedPreferencesUtil.setSentToken(false);
        }
      } 

      if (widget.user != null && widget.email != null) {
        dynamic messageResult = await fetchMessagesFromApi(widget.email!);
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
          messagesModel.updateGroupedMessages(widget.email!);

          //Set up web socket for new messages
          await connectToSocket(messagesModel, widget.email!);

          // Resend unsent messages
          final messages = await DatabaseHelper.getUnsentMessages();
          if (messages.isNotEmpty) {
            for (var message in messages) {
              await sendMessageData(messagesModel, message, widget.email!);
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
      _showError("Unable to fetch dependencies at the moment.");
      //_showError("An error occurred: $error");
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

    if (_errorOccurred) {
      return _buildErrorScreen();
    }
    
    if (widget.user == null) {
      if (widget.isLoggedOut == true) {
        // user has an account, but logged out
        return MaterialApp(
      theme: appTheme,
      home: const LoginScreen());
      } else {
        // User doesn't have an account, show registration screen
        return MaterialApp(
      theme: appTheme,
      home: const RegistrationScreen());
      }
    }
    else {
      if (widget.user?.email == null) {
        // User has been deleted, show the registration screen
        return MaterialApp(
      theme: appTheme,
      home: const RegistrationScreen());
      } else if (widget.user?.emailVerified == false) {
        // User is not verified, show the login screen
        return MaterialApp(
      theme: appTheme,
      home: const LoginScreen());
      }
    }

    if (!_networkOperationCompleted) {
      return _buildLoadingIndicator();
    }

    return MaterialApp(
      theme: appTheme,
      home: const MyProjectPage(),
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
            title: const Text('Hi Chief'),
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

}