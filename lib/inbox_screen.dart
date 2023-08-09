import 'package:flutter/material.dart';
import 'package:collabio/model.dart';
import 'package:collabio/chat_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:collabio/util.dart';

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
    final sortedKeys = groupedMessages.keys.toList()
      ..sort((a, b) {
        final mostRecentMessageA = groupedMessages[a]!.last;
        final mostRecentMessageB = groupedMessages[b]!.last;
        return mostRecentMessageB.timestamp.compareTo(mostRecentMessageA.timestamp);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
      ),
      body: groupedMessages.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount: sortedKeys.length,
              itemBuilder: (context, index) {
                
                final groupKey = sortedKeys[index];
                final messages = groupedMessages[groupKey]!;
                final mostRecentMessage = messages.last;
                String otherPartyName = "unknown";
                if (mostRecentMessage.senderName == widget.currentUserName) {
                  // If the current user is the sender, then the other party is the receiver
                  otherPartyName = mostRecentMessage.receiverName;
                } else if (mostRecentMessage.receiverName == widget.currentUserName) {
                  // If the current user is the receiver, then the other party is the sender
                  otherPartyName = mostRecentMessage.senderName;
                }
                return _buildConversationCard(mostRecentMessage: mostRecentMessage, otherPartyName: otherPartyName, groupKey: groupKey);
              },
            ),
    );
  }
  
  Widget _buildConversationCard({required Message mostRecentMessage, required otherPartyName, required String groupKey}) {
  String firstLetter = otherPartyName.isNotEmpty ? otherPartyName[0].toUpperCase() : '';
    return ListTile(
  leading: CircleAvatar(
    radius: 20,
    backgroundColor: Colors.blue,
    child: Text(
      firstLetter,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
  ),
  
  title: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        otherPartyName,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
      _buildTimestamp(mostRecentMessage.timestamp),
    ],
  ),
  subtitle: Text(
    mostRecentMessage.message,
    style: const TextStyle(
      fontSize: 16,
    ),
  ),
  onTap: () {
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

}

Widget _buildTimestamp(String timestamp) {
  final DateTime messageTime = DateTime.parse(timestamp);
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime yesterday = today.subtract(const Duration(days: 1));
  final DateFormat yearMonthDayFormatter = DateFormat('d/M/yy');
  String separatorText = '';

  if (messageTime.isAfter(today)) {
    separatorText = Util.formatTime(context, timestamp);
  } else if (messageTime.isAfter(yesterday)) {
    separatorText = 'Yesterday';
  } else {
    separatorText = yearMonthDayFormatter.format(messageTime);
  }

  return Text(
        separatorText,
        style: const TextStyle(
          color: Colors.grey,
        ),
      );
}

}