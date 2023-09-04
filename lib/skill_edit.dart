import 'package:flutter/material.dart';
import 'package:collabio/network_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:collabio/model.dart';
import 'package:provider/provider.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'dart:async';

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
  final _formKey = GlobalKey<FormState>();
  bool _addButtonPressed = false;
  bool _done = false;
  final FocusNode _focusNode = FocusNode();
  late StreamSubscription<bool> keyboardSubscription;
  List<String> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    initTags();
    _focusNode.addListener(_onFocusChange);
    // Register to listen to keyboard visibility changes.
    var keyboardVisibilityController = KeyboardVisibilityController();
    keyboardSubscription = keyboardVisibilityController.onChange.listen((bool visible) {
        if (_focusNode.hasFocus && !visible) {
          _focusNode.unfocus();
        }
    });
  }

  void initTags() {
    setState(() {
      _selectedTags = widget.content;
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
  Future<void> updateProfileContent(String email, String title, dynamic content) async {
        if (_focusNode.hasFocus) {
          _focusNode.unfocus();
        }
        final String result = await updateProfileSection(email, title, content);  
        if (result == "Profile section $title updated successfully") {
          if (!mounted) return;
          context.pop();
          updateProfileInfo(context);
        } else {
          showStatusDialog("Can't perform any updates at the moment");
        }
  }
  
  @override
  Widget build(BuildContext context) {
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final double tagHeight = keyboardHeight + 50;

    return WillPopScope(
     onWillPop: () async {
      context.pop();
      return false;
     },
     child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
          },
        ),
        title: const Text('Edit Skills'),
      ),
      body: Form (
          key: _formKey,
          child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _selectedTags.length,
              itemBuilder: (context, index) {
                String tag = _selectedTags[index];
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
              focusNode: _focusNode,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              scrollPadding: EdgeInsets.only(bottom: tagHeight),
              decoration: const InputDecoration(
                hintText: 'Add a new skill',
              ),
              validator: (value) {
                if (value == null || value.isEmpty && _selectedTags.isEmpty && !_done) {
                  return 'Adding a skill is required.';
                }
                if (value.isNotEmpty && !_addButtonPressed) {
                  return 'Tap the Add Skill button to add this skill.';
                }
                if (value.isEmpty && _selectedTags.length <= 1 && !_selectedTags.contains(value.trim()) && !_done) {
                  return 'Please enter more skills.';
                }
                if (value.isEmpty && _selectedTags.length > 1 && !_selectedTags.contains(value.trim()) && !_done && _addButtonPressed) {
                  return 'Feel free to enter more skills. Done? Tap Save.';
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () {
                _focusNode.requestFocus();
                setState(() {
                  _addButtonPressed = true;
                });
                if (_tagController.text.isNotEmpty && !_selectedTags.contains(_tagController.text.trim())){
                  _addTag(_tagController.text.trim());
                }
              },
              child: const Text('Add Skill'),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: _focusNode.hasFocus ? null : () {
                if (_formKey.currentState != null && _formKey.currentState!.validate()) {
                  updateProfileContent(widget.email, widget.title, _selectedTags);
                }
              },
              child: const Text('Save'),
            ),
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
                context.pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void updateProfileInfo(BuildContext context) {
    final profileInfoModel = Provider.of<ProfileInfoModel>(context, listen: false);
    profileInfoModel.updateTags();  
  }
}
