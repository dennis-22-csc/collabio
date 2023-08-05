import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:collabio/project_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  File? _profilePicture;
  String? _email;

  @override
  void initState() {
    super.initState();
    User user = FirebaseAuth.instance.currentUser!; 
    _email = user.email; 
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _selectProfilePicture() async {
    bool directoryExists = await Util._checkAndCreateDirectory(context);

    if (directoryExists) {
      // Permission granted, launch picker
      final picker = ImagePicker();
      final pickedImage = await picker.pickImage(source: ImageSource.gallery);
      if (pickedImage != null) {
        setState(() {
          _profilePicture = File(pickedImage.path);
        });
      }
    } else {
      // Permission not granted, route to ProjectScreen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyProjectPage()),
        );
      });
    }
  }


  Future<void> _createProfile() async {
    String firstName = _firstNameController.text;
    String lastName = _lastNameController.text;
    String about = _aboutController.text;
    String? email = _email;

    if (firstName.isNotEmpty &&
        lastName.isNotEmpty &&
        about.isNotEmpty &&
        _profilePicture != null) {
      try {
        await Util.saveProfileInformation(
          firstName: firstName,
          lastName: lastName,
          about: about,
          email: email!,
        );

        // Save data to shared preferences after successful remote save
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('firstName', firstName);
        await prefs.setString('lastName', lastName);
        await prefs.setString('about', about);

        // Save profile picture to internal storage
        await Util.saveProfilePicture(_profilePicture!);

        WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Success"),
              content: const Text("Profile created successfully."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const MyProjectPage()),
                    );
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
        });
      } catch (e) {
        // Error occurred while saving profile information
        showCustomDialog(context, 'Error', e.toString());
      }
    } else {
      // Display an error message indicating required fields
      showCustomDialog(
        context,
        'Error',
        'Please fill in all the required fields including selecting a profile picture.',
      );
    }
  }

  void showCustomDialog(BuildContext context, String title, String text) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(text),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _selectProfilePicture,
              child: Column(
                children: [
                  const Text(
                    'Upload profile picture',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Container(
                    width: 80.0,
                    height: 80.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[300],
                    ),
                    child: _profilePicture != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(40.0),
                      child: Image.file(
                        _profilePicture!,
                        fit: BoxFit.cover,
                      ),
                    )
                        : Icon(
                      Icons.camera_alt,
                      size: 40.0,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'First Name'),
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Last Name',
              ),
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _aboutController,
              decoration: const InputDecoration(
                labelText: 'About',
                hintText: 'Tell us something about yourself',
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _createProfile,
              child: const Text('Create Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class Util {

   static Future<void> saveProfileInformation({
    required String firstName,
    required String lastName,
    required String about,
    required String email,
  }) async {
    Map<String, dynamic> userData = {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'about': about,
        
      };

    await sendUserData(userData);
  }

   static Future<bool> _requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      return true;
    } else {
      var result = await permission.request();
      if (result == PermissionStatus.granted) {
        return true;
      }
    }
    return false;
  }

static Future<String> sendUserData(Map<String, dynamic> userData) async {
  String url = 'https://collabio.denniscode.tech/users';

  try {
    final response = await http.post(
      Uri.parse(url),
      body: jsonEncode(userData),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      String message = responseData['message'];
      return message;
    } else {
      return 'Failed to save user data. Error code: ${response.statusCode}';
    }
  } catch (e) {
    return 'Error saving user data: $e';
  }
}

   static Future<bool> saveProfilePicture(File profilePicture) async {
     Directory? directory;

     if (Platform.isAndroid) {
       directory = await getExternalStorageDirectory();
       if (directory != null) {
         String newPath = "";

         List<String> paths = directory.path.split("/");
         for (int x = 1; x < paths.length; x++) {
           String folder = paths[x];
           if (folder != "Android") {
             newPath += "/$folder";
           } else {
             break;
           }
         }
         newPath = "$newPath/Collabio/profile_picture";
         directory = Directory(newPath);
       }
     }

     if (directory != null && !await directory.exists()) {
       await directory.create(recursive: true);
     }
     if (directory != null && await directory.exists()) {
       File saveFile = File("${directory.path}/${profilePicture.path.split('/').last}");
       await profilePicture.copy(saveFile.path);
       SharedPreferences prefs = await SharedPreferences.getInstance();
       await prefs.setString('profile_picture', saveFile.path);

       return true;
     }

     return false;
   }


   static Future<bool> _checkAndCreateDirectory(BuildContext context) async {
     if (Platform.isAndroid) {
       if (await _requestPermission(Permission.storage)) {
         Directory? directory = await getExternalStorageDirectory();
         if (directory != null) {
           String newPath = "${directory.path}/Collabio/profile_picture";
           directory = Directory(newPath);
           if (!await directory.exists()) {
             await directory.create(recursive: true);
           }
           return true; // Directory creation successful
         }
       }
     }
     return false; // Directory creation failed
   }

}