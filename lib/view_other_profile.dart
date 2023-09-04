import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:collabio/network_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:collabio/model.dart';
import 'package:collabio/util.dart';
import 'package:collabio/database.dart';
import 'dart:typed_data';

class ViewOtherProfileScreen extends StatefulWidget {
  final String userId;

  const ViewOtherProfileScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<ViewOtherProfileScreen> createState() => _ViewOtherProfileScreenState();

}
class _ViewOtherProfileScreenState extends State<ViewOtherProfileScreen> {
  String? email;
  String? _name;
  late Map<String, dynamic> user;
  bool _hasProfile = false;
  final TextEditingController _messageController = TextEditingController();
 
  @override
  void initState() {
    super.initState();
    User user = FirebaseAuth.instance.currentUser!; 
    email = user.email;
  }

  Future<dynamic> fetchUserInfo() async {
    try {
      final fetchResult = await fetchOtherUserInfoFromApi(widget.userId);
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
        title: const Text('User Profile'),
      ),
      body: FutureBuilder<dynamic>(
          future: fetchUserInfo(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center (child: CircularProgressIndicator(),);
            } else if (snapshot.hasError) {
              return Center(
              child: Text('Error: ${snapshot.error}'),
              );
            } else if (snapshot.hasData && snapshot.data is String && snapshot.data == "No user is found") {
              return const Center(
              child: Text('No user matching the ID'),
              );
            }  else if (snapshot.hasData && snapshot.data is String && snapshot.data != "No user is found") {
              return const Center(
              child: Text('Unable to fetch the profile at the moment'),
              );
            }
              
            user = snapshot.data!; 
            List<String> tagsList = List<String>.from(user['tags']);
            Uint8List? pictureBytes = Util.convertBase64ToImage(user['pictureBytes']);
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 80,
                    backgroundImage:  pictureBytes != null ? MemoryImage(pictureBytes) : null,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "First Name",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user["firstName"],
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Last Name",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                    user["lastName"],
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "About",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user["about"],
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Skills ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: tagsList.length,
                        itemBuilder: (context, index) {
                          return Padding (
                            padding: const EdgeInsets.only(right: 10, top: 10),
                            child: Chip(
                              label: Padding(
                                padding: const EdgeInsets.only(bottom: 18),
                                child: Text(tagsList[index]),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (_hasProfile && email != user["email"]) {
                      _showMessageDialog(context);
                    } else if (email == user["email"]) {
                      showErrorDialog("You can't message yourself");
                    } else {
                      showProfileDialog("You can't message the user without creating a profile.");
                    }
                  },
                  child: const Text('Message User'),
                ),
                ), 
              ],
            ),
            );
          },
      ),
     ),
    );
  }

  void _sendMessage() async {
    
    final message = {
      "message_id": const Uuid().v4(),
      "sender_name": _name,
      "sender_email": email,
      "receiver_name": '$user["first_name"] $user["last_name"]',
      "receiver_email": user["email"],
      "message": _messageController.text.trim(),
      "timestamp": DateFormat('yyyy-MM-dd HH:mm:ss')
        .format(DateTime.now()),
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
            title: Text('Message $user["first_name"] $user["last_name"]'),
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