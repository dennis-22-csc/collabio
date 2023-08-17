import 'package:flutter/material.dart';
import 'package:collabio/model.dart';
import 'package:collabio/chat_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:collabio/util.dart';
import 'package:collabio/project_page.dart';

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
  
  }

  @override
  Widget build(BuildContext context) {
    final messagesModel = Provider.of<MessagesModel>(context);
    final groupedMessages = messagesModel.groupedMessages;
    final sortedKeys = groupedMessages.keys.toList()
      ..sort((a, b) {
        final mostRecentMessageA = groupedMessages[a]!.first;
        final mostRecentMessageB = groupedMessages[b]!.first;
        return mostRecentMessageB.timestamp.compareTo(mostRecentMessageA.timestamp);
      });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MyProjectPage(), ), );
            },
          ),
        title: const Text('Inbox'),
      ),
      body: groupedMessages.isEmpty
          ? const Center(
              child: Text("No messages in inbox"),
            )
          : ListView.builder(
              itemCount: sortedKeys.length,
              itemBuilder: (context, index) {
                
                final groupKey = sortedKeys[index];
                final messages = groupedMessages[groupKey]!;
                final mostRecentMessage = messages.first;
                String otherPartyName = "unknown";
                String senderName = mostRecentMessage.senderName.trim();
                String receiverName = mostRecentMessage.receiverName.trim();
                String userName = widget.currentUserName.trim();
                if (Util.areEquivalentStrings(senderName, userName)) {
                  // If the current user is the sender, then the other party is the receiver
                  otherPartyName = receiverName;
                } else if (Util.areEquivalentStrings(receiverName, userName)) {
                  // If the current user is the receiver, then the other party is the sender
                  otherPartyName = senderName;
                }
                return _buildConversationCard(mostRecentMessage: mostRecentMessage, otherPartyName: otherPartyName, groupKey: groupKey);
              },
            ),
    );
  }
  
  Widget _buildConversationCard({required Message mostRecentMessage, required otherPartyName, required String groupKey}) {
  return ListTile(
  leading: CircleAvatar(
    radius: 20,
    child: Text(
      Util.getLetters(otherPartyName),
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
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
  subtitle: Row (
    children: [
      Expanded(
        flex: 1,
        child: Text(
          Util.formatToOneLine(mostRecentMessage.message),
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
      ),
      Flexible(
        flex: 0,
        child: buildMessageStatusIcon(mostRecentMessage.status),
      )
    ],
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


Widget buildMessageStatusIcon(String status) {
  switch (status) {
    case 'sent':
      return const Row(
        children: [
          SizedBox(width: 4.0),
          Icon(Icons.check, color: Colors.blue, size: 15),
        ],
      );
    case 'pending':
      return const Row(
        children: [
          SizedBox(width: 4.0),
          Icon(Icons.schedule, color: Colors.grey, size: 15),
        ],
      );
    case 'failed':
      return const Row(
        children: [
          SizedBox(width: 4.0),
          Icon(Icons.error, color: Colors.red, size: 15),
        ],
      );
    default:
      return const SizedBox.shrink();
  }
}



}