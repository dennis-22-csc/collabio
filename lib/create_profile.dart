import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:collabio/project_page.dart';
import 'package:collabio/util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:collabio/exceptions.dart';

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
    bool directoryExists = await Util.checkAndCreateDirectory(context);

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
        Map<String, dynamic> userInfo = {
          'firstName': firstName,
          'lastName': lastName,
          'about': about,
        };
        await SharedPreferencesUtil.setUserInfo(userInfo);
        
        // Save profile picture to internal storage
        await Util.saveProfilePicture(_profilePicture!);
        await SharedPreferencesUtil.setHasProfile(true);
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
        if (e is SendDataException) {
          showCustomDialog(context, 'Error', e.message);
        } else {
          showCustomDialog(context, 'Error', e.toString());
        }
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

