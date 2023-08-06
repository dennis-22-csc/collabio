import 'package:flutter/material.dart';
import 'package:collabio/model.dart';
import 'package:collabio/exceptions.dart';
import 'package:collabio/network_handler.dart';
import 'package:collabio/database.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ChatScreen extends StatelessWidget {
  final String currentUserName;
  final String currentUserEmail;
  final String otherPartyName;
  final String otherPartyEmail;

  const ChatScreen({
    Key? key,
    required this.currentUserName,
    required this.currentUserEmail,
    required this.otherPartyName,
    required this.otherPartyEmail,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final messagesModel = Provider.of<MessagesModel>(context);
    final messages = messagesModel.groupedMessages[otherPartyEmail] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(otherPartyEmail),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isCurrentUserMessage = message.senderEmail == currentUserEmail;

                return Row(
                  mainAxisAlignment: isCurrentUserMessage
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      constraints: const BoxConstraints(maxWidth: 250),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(message.timestamp),
                              const SizedBox(height: 8.0),
                              Text(
                                message.message,
                                style: const TextStyle(fontSize: 16.0),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          _buildMessageComposer(context),
        ],
      ),
    );
  }

  Widget _buildMessageComposer(BuildContext context) {
    final TextEditingController textController = TextEditingController();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: textController,
              decoration: const InputDecoration.collapsed(hintText: 'Enter new message'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              _sendMessage(context, textController.text);
              textController.clear();
            },
          ),
        ],
      ),
    );
  }

  void _sendMessage(BuildContext context, String text) async {
    if (text.trim().isNotEmpty) {
      final message = {
      "message_id": const Uuid().v4(),
      "sender_name": currentUserName,
      "sender_email": currentUserEmail,
      "receiver_name": otherPartyName,
      "receiver_email": otherPartyEmail,
      "message": text,
      "timestamp": DateFormat('yyyy-MM-dd HH:mm:ss')
        .format(DateTime.now()),
    };
    final messagesModel = Provider.of<MessagesModel>(context, listen: false);
      
    try {
      await sendMessageData(messagesModel, message, currentUserEmail);
      //showToast("Message sent successfully");
    } catch (error) {
      /*if (error is LocalInsertException){
        showToast("LocalInsertException. ${error.message}");
      } else if (error is SendDataException){
        await DatabaseHelper.deleteMessage(message['message_id']!);
        showToast("SendDataException. ${error.message}");
      } else {
        showToast("Exception. ${error.toString()}");
      }*/
      
    }

    }
  }

  /*void showToast(String message) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    backgroundColor: Colors.black54,
    textColor: Colors.white,
    fontSize: 16.0,
  );
}*/

}