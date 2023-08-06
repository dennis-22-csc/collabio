import 'package:flutter/material.dart';
import 'package:collabio/model.dart';
import 'package:collabio/chat_screen.dart';
import 'package:provider/provider.dart';

class InboxScreen extends StatefulWidget {
  final String currentUserName;
  final String currentUserEmail;

  const InboxScreen({Key? key, required this.currentUserName, required this.currentUserEmail}) : super(key: key);

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  @override
  void initState() {
    super.initState();
    final messagesModel = Provider.of<MessagesModel>(context, listen: false);
    messagesModel.updateGroupedMessages(widget.currentUserEmail);
  }

  @override
  Widget build(BuildContext context) {
    final messagesModel = Provider.of<MessagesModel>(context);
    final groupedMessages = messagesModel.groupedMessages;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
      ),
      body: groupedMessages.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount: groupedMessages.keys.length,
              itemBuilder: (context, index) {
                final groupKey = groupedMessages.keys.elementAt(index);
                final messages = groupedMessages[groupKey]!;
                final mostRecentMessage = messages.last;
                return ListTile(
                  title: Text(groupKey),
                  subtitle: Text(mostRecentMessage.message),
                  onTap: () {
                    String otherPartyName = "unknown";

                    if (mostRecentMessage.senderName == widget.currentUserName) {
                      // If the current user is the sender, then the other party is the receiver
                      otherPartyName = mostRecentMessage.receiverName;
                    } else if (mostRecentMessage.receiverName == widget.currentUserName) {
                      // If the current user is the receiver, then the other party is the sender
                      otherPartyName = mostRecentMessage.senderName;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          currentUserName: widget.currentUserName,
                          currentUserEmail: widget.currentUserEmail,
                          otherPartyName: otherPartyName,
                          otherPartyEmail: groupKey,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}