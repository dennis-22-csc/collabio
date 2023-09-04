import 'package:flutter/material.dart';
import 'package:collabio/network_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:collabio/model.dart';
import 'package:provider/provider.dart';

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
  final _formKey = GlobalKey<FormState>();
  
  void updateProfileContent(String email, String title, dynamic content) async {
    final result = await updateProfileSection(email, title, content);
    if (result == "Profile section $title updated successfully") {
    if (!mounted) return;
    context.pop();
    updateProfileInfo(context);
    } else {
      showStatusDialog("Can't perform any profile updates at the moment");
    }
        
  }
  
  
  @override
  Widget build(BuildContext context) {
    return  WillPopScope(
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
            title: Text('Edit ${widget.title}'),
          ),
          body: Form (
          key: _formKey,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: TextFormField(
                  controller: widget.textEditingController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  maxLines: widget.title != "About" ? 1 : 5,
                  validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "This field can't be empty.";
                  }
                  return null;
                },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: () {
                    final updatedContent = widget.textEditingController.text.trim();
                     if (updatedContent != widget.content && _formKey.currentState != null && _formKey.currentState!.validate()) {
                        updateProfileContent(widget.email, widget.title, updatedContent);
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
    
    switch (widget.title) {
    case 'First Name':
      profileInfoModel.updateName();  
      break;
    case 'Last Name':
      profileInfoModel.updateName();  
      break;
    case 'About':
      profileInfoModel.updateAbout();  
    default:
      break;
  }
  }
}
