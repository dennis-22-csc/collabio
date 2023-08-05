import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collabio/util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfileSection {
  String title;
  String content;
  ProfileSection({required this.title, required this.content,});
}

class ProfileSectionView extends StatefulWidget {
  final ProfileSection section;
  final Function()? selectProfilePicture;
  final File? profilePicture;

  const ProfileSectionView({
    required Key? key,
    required this.section,
    this.selectProfilePicture,
    this.profilePicture,
  }) : super(key: key);

  @override
  State<ProfileSectionView> createState() => _ProfileSectionViewState();
}

class _ProfileSectionViewState extends State<ProfileSectionView> {
  String? _email;
  TextEditingController _textEditingController = TextEditingController();

  

  @override
  void initState() {
    super.initState();
    User user = FirebaseAuth.instance.currentUser!; 
    _email = user.email;
    _textEditingController = TextEditingController(text: widget.section.content);
    }

@override
void dispose() {
  _textEditingController.dispose();
  super.dispose();
}

 void _updateProfileContent(section) async {
        // Send the updated content to the backend only for the edited sections
        String result = await _updateProfileSection(section.title, section.content);
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Text(result),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      });
      
  }
  
  Future<String> _updateProfileSection(String title, String content) async {
  const String url = 'https://collabio.denniscode.tech/update_profile';
  final Map<String, dynamic> data = {
    'email': _email,
  };

  // Assign the specific content to the corresponding field based on the 'title'
  switch (title) {
    case 'First Name':
      data['first_name'] = content;
      break;
    case 'Last Name':
      data['last_name'] = content;
      break;
    case 'About':
      data['about'] = content;
    default:
      break;
  }

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      // Update the corresponding SharedPreferences value after successful database update
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      switch (title) {
        case 'First Name':
          await prefs.setString('firstName', content);
          break;
        case 'Last Name':
          await prefs.setString('lastName', content);
          break;
        case 'About':
          await prefs.setString('about', content);
        default:
          break;
      }

      return 'Profile section "$title" updated successfully';
    } else {
      return 'Failed to update profile section "$title". Status code: ${response.statusCode}';
    }
  } catch (e) {
    return 'Error occurred while updating profile section "$title": $e';
  }
}

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.section.title),
      subtitle: Text(_textEditingController.text),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () {
          _showEditDialog(context);
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (BuildContext buildContext, Animation animation, Animation secondaryAnimation) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            title: Text('Edit ${widget.section.title}'),
          ),
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: TextField(
                  controller: _textEditingController,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: () {
                    // Handle Save button logic here
                     if (_textEditingController.text != widget.section.content) {
                        widget.section.content = _textEditingController.text;
                        _updateProfileContent(widget.section);
                      }
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ProfileSectionScreen extends StatefulWidget {
  const ProfileSectionScreen({Key? key}) : super(key: key);

  @override
  State<ProfileSectionScreen> createState() => _ProfileSectionScreenState();
}

class _ProfileSectionScreenState extends State<ProfileSectionScreen> {

  File? profilePicture;

  final List<ProfileSection> sections = [
    ProfileSection(title: 'First Name', content: ''),
    ProfileSection(title: 'Last Name', content: ''),
    ProfileSection(title: 'About', content: ''),
  ];

  @override
  void initState() {
    super.initState();
    loadProfilePicture();
    loadProfileContent();
    
  }

  void loadProfilePicture() async {
    String? persistedFilePath = await Util.getPersistedFilePath();

    if (persistedFilePath != null) {
      File existingProfilePicture = File(persistedFilePath);
      if (existingProfilePicture.existsSync()) {
        setState(() {
          profilePicture = existingProfilePicture;
        });
      }
    }
  }

  void loadProfileContent() async {
    sections[0].content = (await SharedPreferencesUtil.getFirstName()) ?? '';
    sections[1].content = (await SharedPreferencesUtil.getLastName()) ?? '';
    sections[2].content = (await SharedPreferencesUtil.getAbout()) ?? '';
    setState(() {});
  }

 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Your Profile')),
        body: ListView.builder(
          itemCount: 1 + sections.length,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: profilePicture != null ? FileImage(profilePicture!) : null,
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.bottomRight,
                          child: IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _selectProfilePicture,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            return ProfileSectionView(key: UniqueKey(), section: sections[index - 1]);
          },
        ),
      );
  }

  void _selectProfilePicture() async {
    bool directoryExists = await Util._checkAndCreateDirectory(context);

    if (directoryExists) {
      final picker = ImagePicker();
      final pickedImage = await picker.pickImage(source: ImageSource.gallery);
      if (pickedImage != null) {
        File newProfilePicture = File(pickedImage.path);

        bool saved = await Util.saveProfilePicture(newProfilePicture);
        if (saved) {
          setState(() {
            profilePicture = newProfilePicture;
          });
        }
      }
    }
  }
}

class Util {
  static Future<String?> getPersistedFilePath() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('profile_picture');
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
      return true;
    }

    return false;
  }
}