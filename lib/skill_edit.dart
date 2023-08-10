import 'package:flutter/material.dart';
import 'package:collabio/network_handler.dart';
import 'package:collabio/view_profile.dart';

class SkillEditDialog extends StatefulWidget {
  final String email;
  final String title;
  final dynamic content;

  const SkillEditDialog({
    Key? key,
    required this.email,
    required this.title,
    required this.content,
  }) : super(key: key);

  @override
  State<SkillEditDialog> createState() => _SkillEditDialogState();
}

class _SkillEditDialogState extends State<SkillEditDialog> {
  
  final TextEditingController _tagController = TextEditingController();

  void _addTag(String tag) {
    setState(() {
      widget.content.add(tag);
      _tagController.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() {
      widget.content.remove(tag);
    });
  }

  void updateProfileContent(String email, String title, dynamic content) async {
        String result = '';
        
        result = await updateProfileSection(email, title, content);
          
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
                  Navigator.pushReplacement(
              context,
              MaterialPageRoute(
              builder: (context) => const ProfileSectionScreen(),
          ),
          );
                },
              ),
            ],
          );
        },
      );
      });
      
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text('Edit Skills'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.content.length,
              itemBuilder: (context, index) {
                String tag = widget.content[index];
                return ListTile(
                  title: Text(tag),
                  trailing: IconButton(
                    icon: const Icon(Icons.cancel),
                    onPressed: () {
                      _removeTag(tag);
                    },
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            child: TextFormField(
              controller: _tagController,
              onFieldSubmitted: (value) {
                _addTag(value);
              },
              decoration: const InputDecoration(
                hintText: 'Add a new skill',
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () {
                _addTag(_tagController.text);
              },
              child: const Text('Add Skill'),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () {
                updateProfileContent(widget.email, widget.title, widget.content);
              },
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
