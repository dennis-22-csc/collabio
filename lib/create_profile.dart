import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:collabio/project_page.dart';
import 'package:collabio/util.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  File? _profilePicture;
  String? _email;
  final List<String> _selectedTags = [];

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
    _tagController.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    setState(() {
      _selectedTags.add(tag);
      _tagController.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _selectedTags.remove(tag);
    });
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
  WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
  String firstName = _firstNameController.text;
  String lastName = _lastNameController.text;
  String about = _aboutController.text;
  String? email = _email;
  late String msg;
  late String title;

  if (firstName.isNotEmpty &&
      lastName.isNotEmpty &&
      about.isNotEmpty &&
      _selectedTags.isNotEmpty &&
      _profilePicture != null) {
    String result = await Util.saveProfileInformation(
      firstName: firstName,
      lastName: lastName,
      about: about,
      email: email!,
      tags: _selectedTags,
    );
    if (result == "User inserted successfully.") {
      try {
        // Save data to shared preferences after successful remote save
        Map<String, dynamic> userInfo = {
          'firstName': firstName,
          'lastName': lastName,
          'about': about,
          'tags': _selectedTags,
        };
        await SharedPreferencesUtil.setUserInfo(userInfo);

        // Save profile picture to internal storage
        await Util.saveProfilePicture(_profilePicture!);
        await SharedPreferencesUtil.setHasProfile(true);
        msg = "Profile created successfully";
        title = "Success";
      } catch (e) {
        //msg = 'Error $e.toString()';
        msg = "Can't create profile at the moment";
        title = "Error";
      }
    } else {
      //msg = "Failed to create profile $result";
      msg = "Can't create profile at the moment";
      title = "Error";
    }
  } else {
    msg = 'Please fill in all the required fields including uploading a profile picture.';
    title = "Error";
  }
  showStatusDialog(title, msg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Profile'),
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
                hintText: 'Write something about yourself',
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16.0),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        hintText: 'Enter skills',
                        labelText: 'Skills',
                      ),
                      controller: _tagController,
                      onFieldSubmitted: (value) {
                        _addTag(value);
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      if (_tagController.text.isNotEmpty){
                      _addTag(_tagController.text);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              SizedBox(
                height: 50.0,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedTags.length,
                  itemBuilder: (BuildContext context, int index) {
                    String technology = _selectedTags[index];
                    return Padding (
                      padding: const EdgeInsets.only(right: 10),
                      child: Chip(
                      label: Text(technology),
                      deleteIcon: const Icon(Icons.cancel),
                      onDeleted: () {
                        _removeTag(technology);
                      },
                    ),
                    );
                  },
                ),
              ),
            ElevatedButton(
              onPressed: _createProfile,
              child: const Text('Create Profile'),
            ),
          ],
        ),
      ),
    );
  }

  void showStatusDialog(String title, String content){
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hey Chief'),
          content: Text(content),
          actions: [
            ElevatedButton(
              onPressed: () {
                 Navigator.of(context).pop();
                if (title == "Success") {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const MyProjectPage()),
                  );
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