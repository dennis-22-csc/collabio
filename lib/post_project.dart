import 'package:collabio/util.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:collabio/network_handler.dart';
import 'package:collabio/project_page.dart';

class ProjectUploadScreen extends StatefulWidget {
  const ProjectUploadScreen({Key? key}) : super(key: key);

  @override
  State<ProjectUploadScreen> createState() => _ProjectUploadScreenState();
}

class _ProjectUploadScreenState extends State<ProjectUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _projectTitleController = TextEditingController();
  final TextEditingController _projectDescriptionController = TextEditingController();
  final List<String> _selectedTags = [];
  String? _email;
  String? _name;

  @override
  void initState() {
    super.initState();
    User user = FirebaseAuth.instance.currentUser!; 
    _email = user.email; 
    fetchName();
  }

  Future<void> fetchName() async {
    String fName = (await SharedPreferencesUtil.getFirstName()) ?? '';
    String lName = (await SharedPreferencesUtil.getLastName()) ?? '';
    setState(() {
      _name = '$fName $lName';
    });
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

  void _publishProject() async {
    if (_formKey.currentState!.validate()) {
      // Gather all the required project information
      String projectTitle = _projectTitleController.text;
      String projectDescription = _projectDescriptionController.text;
      DateTime currentTime = DateTime.now();
      String? title;
      String? result;

      // Prepare the data to be sent to the remote URL
      Map<String, dynamic> projectData = {
        'title': projectTitle,
        'timestamp': currentTime.toString(),
        'description': projectDescription,
        'tags': _selectedTags,
        'poster_name': _name,
        'poster_email': _email,
      };

      
        result = await sendProjectData(projectData);
        if (result.startsWith('Project inserted successfully.')) {
          title = 'Success';
        } else {
          title = 'Error';
        }
      

      // Show a dialog to indicate that the project has been published
      WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title!),
            content: Text(result!),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MyProjectPage(), ), );
                },
              ),
            ],
          );
        },
      );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MyProjectPage(), ), );
            },
          ),
        title: const Text('Publish Project'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
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
                      decoration: const InputDecoration(
                        hintText: 'Enter technologies/languages/frameworks/skills',
                        labelText: 'Technologies/Languages/Frameworks/Skills',
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
                      _addTag(_tagController.text);
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
                    return Chip(
                      label: Text(tag),
                      deleteIcon: const Icon(Icons.cancel),
                      onDeleted: () {
                        _removeTag(tag);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _publishProject,
                child: const Text('Publish'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
