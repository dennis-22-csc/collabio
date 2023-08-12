import 'package:flutter/material.dart';
import 'package:collabio/model.dart';
import 'package:collabio/network_handler.dart';
import 'package:collabio/util.dart';
import 'package:collabio/create_profile.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ViewProjectScreen extends StatefulWidget {
  final Project project;
  const ViewProjectScreen({
    Key? key,
    required this.project,
  }) : super(key: key);

  @override
  State<ViewProjectScreen> createState() => _ViewProjectScreenState();

}
class _ViewProjectScreenState extends State<ViewProjectScreen> {
  final TextEditingController _messageController = TextEditingController();
  String? name;
  String? email;
  bool hasProfile = false;


  @override
  void initState() {
    super.initState();
    User user = FirebaseAuth.instance.currentUser!; 
    email = user.email; 
    loadNames();
    getProfileStatus();
  }

  void loadNames() async {
    String fName = (await SharedPreferencesUtil.getFirstName()) ?? '';
    String lName = (await SharedPreferencesUtil.getLastName()) ?? '';
    setState(() {
      name = '$fName $lName';
    });
  }

  void getProfileStatus() async {
    bool myProfile = await SharedPreferencesUtil.hasProfile();
    setState(() {
      hasProfile = myProfile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Project Details'),
      ),
      body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.project.title,
              style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Text('Poster: ${widget.project.posterName}'),
            const SizedBox(height: 8.0),
            Text('Posted: ${Util.extractDate(widget.project.timestamp)}'),
            const SizedBox(height: 16.0),
            MarkdownBody(
              data: widget.project.description,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(fontSize: 16.0),
              ),
            ),
            const SizedBox(height: 24.0),
            const Text(
              'About the poster',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              widget.project.posterAbout,
              style: const TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 24.0),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: () {
                  if (hasProfile) {
                    _showMessageDialog(context);
                  } else {
                    showProfileDialog("You can't message the poster without creating a profile.");
                  }
                  
                },
                child: const Text('Message Now'),
              ),
            )
          ],
        ),
      ),
      ),
    );
  }

  void _sendMessage() async {
    
    final message = {
      "message_id": const Uuid().v4(),
      "sender_name": name,
      "sender_email": email,
      "receiver_name": widget.project.posterName,
      "receiver_email": widget.project.posterEmail,
      "message": _messageController.text,
      "timestamp": DateFormat('yyyy-MM-dd HH:mm:ss')
        .format(DateTime.now()),
      "status": "pending",
    };
    final messagesModel = Provider.of<MessagesModel>(context, listen: false);
    String result = await sendMessageData(messagesModel, message, email!);
    showStatusDialog(result);
  
    _messageController.clear();
  }

  void _showMessageDialog(BuildContext context) {
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
            title: Text('Message ${widget.project.posterName}'),
          ),
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: 'Type your message...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: _sendMessage,
                  child: const Text('Send'),
                ),
              ),
            ],
          ),
        );
      },
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
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void showProfileDialog(String content){
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hey Chief'),
          content: Text(content),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
  
}
