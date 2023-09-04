import 'package:flutter/material.dart';
import 'package:collabio/model.dart';
import 'package:collabio/database.dart';
import 'package:collabio/network_handler.dart';
import 'package:collabio/util.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';


class ViewProjectScreen extends StatefulWidget {
  final Project? project;
  final String? projectId;

  const ViewProjectScreen({
    Key? key,
    this.project,
    this.projectId,
  }) : super(key: key);

  @override
  State<ViewProjectScreen> createState() => _ViewProjectScreenState();

}
class _ViewProjectScreenState extends State<ViewProjectScreen> {
  final TextEditingController _messageController = TextEditingController();
  String? email;
  String? _name;
  late Project project;
  bool _hasProfile = false;

  @override
  void initState() {
    super.initState();
    User user = FirebaseAuth.instance.currentUser!; 
    email = user.email;
  }

  Future<Project?> _fetchProject() async {
  try {
    final fetchResult = await DatabaseHelper.getProjectById(widget.projectId!);
    
    if (fetchResult == "Project not found") {
      return null;
    }

    return fetchResult;
  } catch (error) {
    rethrow;
  }
}

  @override
  Widget build(BuildContext context) {
    final  profileInfoModel = Provider.of<ProfileInfoModel>(context);
    _hasProfile = profileInfoModel.hasProfile; 
    _name = profileInfoModel.name;

    return WillPopScope(
     onWillPop: () async {
      context.goNamed("projects");
      if(!profileInfoModel.didPush) profileInfoModel.updateDidPush(true);
      return false;
     },
     child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.goNamed("projects");
            if(!profileInfoModel.didPush) profileInfoModel.updateDidPush(true);
          },
        ),
        title: const Text('Project Details'),
      ),
      body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child:  FutureBuilder<Project?>(
          future: widget.project != null ? Future.value(widget.project) : _fetchProject(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(),);
            } else if (snapshot.hasError) {
              return Center(
              child: Text('Error: ${snapshot.error}'),
              );
            } else if (!snapshot.hasData) {
              return const Center(
              child: Text('No project matching the ID.'),
              );
            }
              
            project = snapshot.data!; 

            return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project.title,
              style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Text('Poster: ${project.posterName}'),
            const SizedBox(height: 8.0),
            Text('Posted: ${Util.extractDate(project.timestamp)}'),
            const SizedBox(height: 16.0),
            MarkdownBody(
              data: project.description,
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
              project.posterAbout,
              style: const TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 24.0),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: () {
                  if (_hasProfile && email != project.posterEmail) {
                    _showMessageDialog(context);
                    
                  } else if (email == project.posterEmail) {
                    showErrorDialog("You can't message yourself");
                  } else {
                    showProfileDialog("You can't message the poster without creating a profile.");
                  }
                  
                },
                child: const Text('Message Now'),
              ),
            )
          ],
        );
          },
        ),
      ),
      ),
     ),
    );
  }

  void _sendMessage() async {
    
    final message = {
      "message_id": const Uuid().v4(),
      "sender_name": _name,
      "sender_email": email,
      "receiver_name": project.posterName,
      "receiver_email": project.posterEmail,
      "message": _messageController.text.trim(),
      "timestamp": DateTime.now().toUtc().microsecondsSinceEpoch.toString(),
      "status": "pending",
    };
    final sender = <String, dynamic>{
    'email': message['sender_email'],
     'name': message['sender_name'],
    };
    final receiver = <String, dynamic>{
    'email': message['receiver_email'],
     'name': message['receiver_name'],
    };
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final messagesModel = Provider.of<MessagesModel>(context, listen: false);
      final profileInfoModel = Provider.of<ProfileInfoModel>(context, listen: false);
        profileInfoModel.updatePostStatus("Sending Message");
        profileInfoModel.updatePostColor('black');
        profileInfoModel.updateSilentSend(false);
        context.goNamed("projects");
        sendMessageData(profileInfoModel, messagesModel, message, email!);
        DatabaseHelper.insertUser(sender);
        DatabaseHelper.insertUser(receiver);
        profileInfoModel.updateUsers();
    });
  }

  void _showMessageDialog(BuildContext context) {
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (BuildContext buildContext, Animation animation, Animation secondaryAnimation) {
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
            title: Text('Message ${project.posterName}'),
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
          ),
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

