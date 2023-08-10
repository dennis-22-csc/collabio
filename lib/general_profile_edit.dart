import 'package:flutter/material.dart';
import 'package:collabio/network_handler.dart';
import 'package:collabio/view_profile.dart';

class ProfileEditDialog extends StatefulWidget {
  final TextEditingController textEditingController;
  final String email;
  final String title;
  final String content;

  const ProfileEditDialog({
    Key? key,
    required this.textEditingController,
    required this.email,
    required this.title,
    required this.content,
  }) : super(key: key);

  @override
  State<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<ProfileEditDialog> {
  
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
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileSectionScreen(),)
                  );
                }
              ),
            ],
          );
        },
      );
      });
      
  }
  
  
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            title: Text('Edit ${widget.title}'),
          ),
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: TextField(
                  controller: widget.textEditingController,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: () {
                    // Handle Save button logic here
                     if (widget.textEditingController.text != widget.content) {
                        updateProfileContent(widget.email, widget.title, widget.textEditingController.text);
                      }
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ); 
    
  }
}
