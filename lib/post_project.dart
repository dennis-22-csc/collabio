import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:collabio/network_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:collabio/model.dart';

class ProjectUploadScreen extends StatefulWidget {
  const ProjectUploadScreen({Key? key}) : super(key: key);

  @override
  State<ProjectUploadScreen> createState() => _ProjectUploadScreenState();
}

class _ProjectUploadScreenState extends State<ProjectUploadScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _projectTitleController = TextEditingController();
  final TextEditingController _projectDescriptionController = TextEditingController();
  final List<String> _selectedTags = [];
  String? _email;
  String? _name;
  String? _about;
  bool _addButtonPressed = false;
  bool _done = false;
  final FocusNode _focusNode = FocusNode();
  late StreamSubscription<bool> keyboardSubscription;
  ProfileInfoModel? _profileInfoModel;

  @override
  void initState() {
    super.initState();
    User user = FirebaseAuth.instance.currentUser!; 
    _email = user.email;
     _focusNode.addListener(_onFocusChange);
    // Register to listen to keyboard visibility changes.
    var keyboardVisibilityController = KeyboardVisibilityController();
    keyboardSubscription = keyboardVisibilityController.onChange.listen((bool visible) {
        if (_focusNode.hasFocus && !visible) {
          _focusNode.unfocus();
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

  void _publishProject() async {
      // Gather all the required project information
      String projectTitle = _projectTitleController.text;
      String projectDescription = _projectDescriptionController.text;
      DateTime currentTime = DateTime.now();
      String? result;

      // Prepare the data to be sent to the remote URL
      Map<String, dynamic> projectData = {
        'title': projectTitle,
        'timestamp': currentTime.toString(),
        'description': projectDescription,
        'tags': _selectedTags,
        'poster_name': _name,
        'poster_email': _email,
        'poster_about': _about,
      };

        // Send project
        result = await sendProjectData(projectData);
        if (result.startsWith('Project inserted successfully.')) {
          showStatusDialog("Project posted");
        } else {
          showStatusDialog("Can't post projects at the moment");
        }
  }

@override
  void dispose() {
    keyboardSubscription.cancel();
    _projectTitleController.dispose();
    _projectDescriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final  profileInfoModel = Provider.of<ProfileInfoModel>(context);
    _about = profileInfoModel.about; 
    _name = profileInfoModel.name;
    _profileInfoModel = profileInfoModel;

    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final double tagHeight = keyboardHeight + 50;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              //context.pop();
              context.goNamed("projects");
              _profileInfoModel!.updateDidPush(true);
            },
          ),
        title: const Text('Publish Project'),
      ),
      body: Padding (
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  hintText: 'Enter project title',
                  labelText: 'Project title',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a project title';
                  }
                  return null;
                },
                controller: _projectTitleController,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Enter project description',
                  labelText: 'Project description',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a project description';
                  }
                  return null;
                },
                controller: _projectDescriptionController,
                maxLines: 5,
              ),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      scrollPadding: EdgeInsets.only(bottom: tagHeight),
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        labelText: 'Technologies/Languages/Frameworks/Skills',
                        hintText: "Enter a tag",
                      ) ,
                      controller: _tagController,
                      focusNode: _focusNode,
                      validator: (value) {
                          if (value == null || value.isEmpty &&  _selectedTags.isEmpty && !_done) {
                            return 'This field is required.';
                          }
                          if (value.isNotEmpty && !_addButtonPressed) {
                            return 'Tap the + button to add this tag.';
                          }
                          if (value.isEmpty && _selectedTags.length <= 1 && !_selectedTags.contains(value.trim()) && !_done) {
                            return 'Please enter more tags.';
                          }
                          if (value.isEmpty && _selectedTags.length > 1 && !_selectedTags.contains(value.trim()) && !_done && _addButtonPressed) {
                            return 'Feel free to enter more tags. Done? Skip.';
                          }
                          if (_selectedTags.contains(value.trim())) {
                            return 'This tag has already been entered';
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
                    String tag = _selectedTags[index];
                    return Padding (
                      padding: const EdgeInsets.only(right: 10),
                      child: Chip(
                      label: Text(tag),
                      deleteIcon: const Icon(Icons.cancel),
                      onDeleted: () {
                        _removeTag(tag);
                      },
                    )
                    );
                  },
                ),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed:  _focusNode.hasFocus ? null : (){
                  if (_formKey.currentState != null && _formKey.currentState!.validate()) {
                     _publishProject();
                  }
                },
                child: const Text('Publish'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showStatusDialog(String content){
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hi there'),
          content: Text(content),
          actions: [
            ElevatedButton(
              onPressed: () {
                context.goNamed("projects");
                _profileInfoModel!.updateDidPush(true);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
