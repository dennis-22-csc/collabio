import 'package:flutter/material.dart';
import 'package:collabio/model.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:collabio/util.dart';
import 'package:go_router/go_router.dart';

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

  Future<Map<String, List<Message>>> getMessages() async {
    final messagesModel = Provider.of<MessagesModel>(context);
    return messagesModel.groupedMessages;
  }

 @override
Widget build(BuildContext context) {
   final  profileInfoModel = Provider.of<ProfileInfoModel>(context);
    
  return Scaffold(
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          context.goNamed("projects");
          if(!profileInfoModel.didPush) profileInfoModel.updateDidPush(true);
        },
      ),
      title: const Text('Inbox'),
    ),
    body: FutureBuilder<Map<String, List<Message>>>(
      future: getMessages(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text("Error: ${snapshot.error}"),
          );
        } else if (snapshot.data == null || snapshot.data!.isEmpty) {
          return const Center(
            child: Text("No messages in inbox"),
          );
        } else {
          final messages = snapshot.data!;
          final sortedKeys = messages.keys.toList()
            ..sort((a, b) {
              final mostRecentMessageA = messages[a]!.first;
              final mostRecentMessageB = messages[b]!.first;
              return mostRecentMessageB.timestamp.compareTo(mostRecentMessageA.timestamp);
            });

          return ListView.builder(
            itemCount: sortedKeys.length,
            itemBuilder: (context, index) {
              final groupKey = sortedKeys[index];
              final messagesForGroup = messages[groupKey]!;
              final mostRecentMessage = messagesForGroup.first;
              String currentUserName = widget.currentUserName.trim();
              final otherPartyName = getOtherPartyName(mostRecentMessage, currentUserName); // Replace with your logic
              return _buildConversationCard(
                mostRecentMessage: mostRecentMessage,
                otherPartyName: otherPartyName,
                groupKey: groupKey,
              );
            },
          );
        }
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
        child: buildMessageStatusIcon(mostRecentMessage),
      )
    ],
  ),
  onTap: () {
    context.pushNamed("chat", pathParameters: {'currentUserName': widget.currentUserName, 'currentUserEmail': widget.currentUserEmail, 'otherPartyName': otherPartyName, 'otherPartyEmail': groupKey});
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


Widget buildMessageStatusIcon(Message message) {
  switch (message.status) {
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
    case 'received':
      if (message.senderEmail == widget.currentUserEmail) {
        return const Row(
        children: [
          SizedBox(width: 4.0),
          Icon(Icons.check, color: Colors.blue, size: 15),
        ],
      );
      }
      return const SizedBox.shrink();
    default:
      return const SizedBox.shrink();
  }
}

String getOtherPartyName(Message message, String currentUserName) {
  final senderName = message.senderName.trim();
  final receiverName = message.receiverName.trim();

  if (Util.areEquivalentStrings(senderName, currentUserName)) {
    // If the current user is the sender, the other party is the receiver
    return receiverName;
  } else if (Util.areEquivalentStrings(receiverName, currentUserName)) {
    // If the current user is the receiver, the other party is the sender
    return senderName;
  } else {
    // If neither sender nor receiver is the current user, return "John Doe"
    return "John Doe";
  }
}


}