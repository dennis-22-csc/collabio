import 'package:flutter/material.dart';
import 'package:collabio/model.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatelessWidget {
  final String currentUserEmail;
  final String otherPartyEmail;

  const ChatScreen({
    Key? key,
    required this.currentUserEmail,
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
      body: ListView.builder(
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          return ListTile(
            title: Text(message.timestamp),
            subtitle: Text(message.message),
          );
        },
      ),
    );
  }
}