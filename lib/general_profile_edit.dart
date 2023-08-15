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
        
        final String result = await updateProfileSection(email, title, content);
        if (result == "Profile section $title updated successfully") {
          showStatusDialog("$title updated successfully");
        } else {
          showStatusDialog("Can't perform any profile update at the moment");
        }
        
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

  void showStatusDialog(String content){
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hey Chief'),
          content: Text(content),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileSectionScreen(),));
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
