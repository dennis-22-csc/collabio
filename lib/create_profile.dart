import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:collabio/util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'dart:async';
import 'package:collabio/model.dart';
import 'package:provider/provider.dart';

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
  String? _userId;

  final List<String> _selectedTags = [];
  final _formKey = GlobalKey<FormState>();
  bool _addButtonPressed = false;
  bool _done = false;
  final FocusNode _focusNode = FocusNode();
  late StreamSubscription<bool> keyboardSubscription;

  @override
  void initState() {
    super.initState();
    User user = FirebaseAuth.instance.currentUser!; 
    _email = user.email;
    _userId = user.uid;

    _focusNode.addListener(_onFocusChange);
    // Register to listen to keyboard visibility changes.
    var keyboardVisibilityController = KeyboardVisibilityController();
    keyboardSubscription = keyboardVisibilityController.onChange.listen((bool visible) {
        if (_focusNode.hasFocus && !visible) {
          _focusNode.unfocus();
        }
    });
    
  }

  @override
  void dispose() {
    keyboardSubscription.cancel();
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
      _tagController.clear();

      if (_selectedTags.length < 2) {
        _done = false;
      }
    });
  }

void _onFocusChange() {
  if (!_focusNode.hasFocus) {
    setState(() {
      if (_selectedTags.length > 1 && _tagController.text.isEmpty) {
      _done = true;
    } else {
      _done = false;
    }
    });
  } else {
    setState(() {
      if (_selectedTags.length > 1 && _tagController.text.isEmpty) {
      _done = false;
    } 
    });
  }
}


  Future<void> _selectProfilePicture() async {
    try {
    bool directoryExists = await Util.checkAndCreateDirectory(context);

    if (directoryExists) {
      // Permission granted, launch picker
      final picker = ImagePicker();
      final pickedImage = await picker.pickImage(source: ImageSource.gallery,);
      if (pickedImage != null) {
        File imageFile = File(pickedImage.path);
        File? compressedImageFile = await Util.compressFile(imageFile);
        setState(() {
          _profilePicture = compressedImageFile;
        });
      }
    } else {
      // Permission not granted, route to ProjectScreen
      if (!mounted) return;
      context.goNamed("projects");
    }

    } catch (error) {
      showStatusDialog("Upload Error", error.toString());
    }

  }


  void _createProfile() async {
  WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
  String firstName = _firstNameController.text.trim();
  String lastName = _lastNameController.text.trim();
  String about = _aboutController.text.trim();
  String? email = _email;
  late String msg;
  late String title;

  if (_profilePicture != null) {
    // Save profile picture to internal storage
      String? imageString = await Util.getImageString(_profilePicture!);
      bool savedPicture = await Util.saveProfilePicture(imageString);
      
      if (savedPicture) {
        String result = await Util.saveProfileInformation(
        firstName: firstName,
        lastName: lastName,
        about: about,
        email: email!,
        tags: _selectedTags,
        pictureBytes: imageString,
        userId: _userId!,
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
        await SharedPreferencesUtil.setHasProfile(true);
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final profileInfoModel = Provider.of<ProfileInfoModel>(context, listen: false);
          profileInfoModel.updateProfileInfo();
        });
        msg = "Profile created successfully";
        title = "Success";
      } catch (e) {
        msg = 'Error $e.toString()';
        //msg = "Can't create profile at the moment";
        title = "Error";
        SharedPreferencesUtil.saveProfilePicturePath('');
      }
    } else {
      msg = "Failed to create profile $result";
      //msg = "Can't create profile at the moment";
      title = "Error";
      SharedPreferencesUtil.saveProfilePicturePath('');
    }
    } else {
      msg = 'Unable to save profile picture to internal storage.';
      title = "Error";
    }
    
  } else {
    msg = 'Please select and upload a profile picture.';
    title = "Error";
  }
  showStatusDialog(title, msg);
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final double tagHeight = keyboardHeight + 50;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              context.goNamed("projects");
            },
          ),
        title: const Text('Create Profile'),
      ),
      body: SingleChildScrollView (
        padding: const EdgeInsets.all(16.0),
        child: Form (
          key: _formKey,
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
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: const InputDecoration(labelText: 'First Name'),
                keyboardType: TextInputType.text,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _lastNameController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                ),
                keyboardType: TextInputType.text,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _aboutController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'About',
                  hintText: 'Write something about yourself',
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        scrollPadding: EdgeInsets.only(bottom: tagHeight),
                        decoration: const InputDecoration(
                          hintText: 'Enter skill',
                          labelText: 'Skills',
                        ),
                        controller: _tagController,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.text,
                        validator: (value) {
                          if (value == null || value.isEmpty &&  _selectedTags.isEmpty && !_done) {
                            return 'This field is required.';
                          }
                          if (value.isNotEmpty && !_addButtonPressed) {
                            return 'Tap the + button to add this skill.';
                          }
                          if (value.isEmpty && _selectedTags.length <= 1 && !_selectedTags.contains(value.trim()) && !_done) {
                            return 'Please enter more skills.';
                          }
                          if (value.isEmpty && _selectedTags.length > 1 && !_selectedTags.contains(value.trim()) && !_done && _addButtonPressed) {
                            return 'Feel free to enter more skills. Done? Skip.';
                          }
                          if (_selectedTags.contains(value.trim())) {
                            return 'This skill has already been entered';
                          }
                          
                          return null;
                        },
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            setState(() {
                              _addButtonPressed = false;
                            });
                          }
                        },
                        onFieldSubmitted: (value) {
                          _addTag(value.trim());
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        _focusNode.requestFocus();
                        setState(() {
                          _addButtonPressed = true;
                        });
                        if (_tagController.text.isNotEmpty && !_selectedTags.contains(_tagController.text.trim())){
                        _addTag(_tagController.text.trim());
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
                onPressed: _focusNode.hasFocus ? null : () {
                  if (_formKey.currentState != null && _formKey.currentState!.validate()) {
                    _createProfile();
                  }
                },
                child: const Text('Create Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showStatusDialog(String title, String content){
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hi there'),
          content: Text(content),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (title == "Success") {
                  context.goNamed("projects");
                } else {
                  context.pop();
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