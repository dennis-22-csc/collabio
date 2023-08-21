import 'package:flutter/material.dart';
import 'package:collabio/model.dart';
import 'package:collabio/network_handler.dart';
import 'package:collabio/util.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';


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
  String? email;
  late ProfileInfoModel _profileInfoModel;

  @override
  void initState() {
    super.initState();
    User user = FirebaseAuth.instance.currentUser!; 
    email = user.email;
    getProfileModel();
  }

Future<void> getProfileModel() async {
    final  profileInfoModel = Provider.of<ProfileInfoModel>(context);
  
    setState(() {
      _profileInfoModel = profileInfoModel;
    });
  }

  @override
  Widget build(BuildContext context) {
    final  profileInfoModel = Provider.of<ProfileInfoModel>(context);
  
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
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
                  if (profileInfoModel.hasProfile! && email != widget.project.posterEmail) {
                    _showMessageDialog(context);
                  } else if (email == widget.project.posterEmail) {
                    showErrorDialog("You can't message yourself");
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
      "sender_name": _profileInfoModel.name,
      "sender_email": email,
      "receiver_name": widget.project.posterName,
      "receiver_email": widget.project.posterEmail,
      "message": _messageController.text.trim(),
      "timestamp": DateFormat('yyyy-MM-dd HH:mm:ss')
        .format(DateTime.now()),
      "status": "pending",
    };
    final messagesModel = Provider.of<MessagesModel>(context, listen: false);
    final result = await sendMessageData(messagesModel, message, email!);

    if (result == "Message inserted successfully.") {
      showStatusDialog("Message sent.");
    } else {
      showStatusDialog("Message not sent, will be sent when the server is reachable.");
    }
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
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                context.pop();
              },
            ),
            title: Text('Message ${widget.project.posterName}'),
          ),
          body: Column(
            children: [
              Container(
                height: 150,
                padding: const EdgeInsets.all(20),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  expands: true,
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
                  onPressed: () {
                    if (_messageController.text.trim().isNotEmpty) {
                      _sendMessage();
                    }
                  },
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
          title: const Text('Hi there'),
          content: Text(content),
          actions: [
            ElevatedButton(
              onPressed: () {
                context.pushNamed("inbox", pathParameters: {'currentUserName': _profileInfoModel.name!, 'currentUserEmail': email!});
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void showErrorDialog(String content){
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


  void showProfileDialog(String content){
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hi there'),
          content: Text(content),
          actions: [
            ElevatedButton(
              onPressed: () {
                context.goNamed("create-profile");
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
  
}
