import 'package:flutter/material.dart';
import 'package:collabio/model.dart';
import 'package:collabio/network_handler.dart';
import 'package:collabio/util.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class ChatScreen extends StatefulWidget {
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
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late MessagesModel messagesModel;

  @override
  void initState() {
    super.initState();
  }
  void _sendMessage(BuildContext context, String text) async {
    if (text.trim().isNotEmpty) {
      final message = {
      "message_id": const Uuid().v4(),
      "sender_name": widget.currentUserEmail,
      "sender_email": widget.currentUserEmail,
      "receiver_name": widget.otherPartyName,
      "receiver_email": widget.otherPartyEmail,
      "message": text,
      "timestamp": DateFormat('yyyy-MM-dd HH:mm:ss')
        .format(DateTime.now()),
      "status": "pending",
    };
    
    sendMessageData(messagesModel, message, widget.currentUserEmail);
  }

  } 

  @override
  Widget build(BuildContext context) {
    messagesModel = Provider.of<MessagesModel>(context);
    final messages = messagesModel.groupedMessages[widget.otherPartyEmail] ?? [];

    List<String> oldestMessageIds = Util.getOldestMessageIdsGroupedBy24Hours(messages);


    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              context.pop();
            },
          ),
        title: Text(widget.otherPartyName),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                
                // Check if a date separator should be added
                if (oldestMessageIds.contains(message.id)) {
                  final separatorText = _getSeparatorText(message.timestamp);

                  return Column(
                    children: [
                      _buildDateSeparator(separatorText),
                      _buildMessage(context, message),
                    ],
                  );
                }

                return _buildMessage(context, message);
              },
            ),
          ),
          _buildMessageComposer(context),
        ],
      ),
    );
  }

 
String _getSeparatorText(String timestamp) {
  final DateTime messageTime = DateTime.parse(timestamp);
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime yesterday = today.subtract(const Duration(days: 1));
  final DateFormat dayFormatter = DateFormat('EEEE');
  final DateFormat monthDayFormatter = DateFormat('MMMM d');
  final DateFormat yearMonthDayFormatter = DateFormat('d MMMM y');

  if (messageTime.isAfter(today)) {
    return 'Today';
  } else if (messageTime.isAfter(yesterday)) {
    return 'Yesterday';
  } else if (messageTime.isBefore(yesterday.subtract(const Duration(days: 7)))) {
    return yearMonthDayFormatter.format(messageTime);
  } else {
    return messageTime.isBefore(today.subtract(const Duration(days: 7)))
        ? monthDayFormatter.format(messageTime)
        : dayFormatter.format(messageTime);
  }
}


  Widget _buildMessage(BuildContext context, Message message) {
  final isCurrentUserMessage = message.senderEmail == widget.currentUserEmail;
  
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      mainAxisAlignment: isCurrentUserMessage
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          constraints: const BoxConstraints(maxWidth: 250),
          child: Card(
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Text(
                                message.message,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                Util.formatTime(context, message.timestamp),
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                              buildMessageStatusIcon(message.status),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildDateSeparator(String separatorText) {
  
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Center(
      child: Text(
        separatorText,
        style: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
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
          child: Container(
            height: 50,
            margin: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: TextField(
              controller: textController,
              maxLines: null,
              expands: true,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline, 
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                hintText: 'Enter new message',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(40.0),
                ),
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.send),
          onPressed: () {
            if (textController.text.trim().isNotEmpty) {
              _sendMessage(context, textController.text.trim());
              textController.clear();
            } 
          },
        ),
      ],
    ),
  );
}

  Widget buildMessageStatusIcon(String status) {
  switch (status) {
    case 'sent':
      return const Row(
        children: [
          SizedBox(width: 4.0),
          Icon(Icons.check, color: Colors.blue, size: 10),
        ],
      );
    case 'pending':
      return const Row(
        children: [
          SizedBox(width: 4.0),
          Icon(Icons.schedule, color: Colors.grey, size: 10),
        ],
      );
    case 'failed':
      return const Row(
        children: [
          SizedBox(width: 4.0),
          Icon(Icons.error, color: Colors.red, size: 10),
        ],
      );
    default:
      return const SizedBox.shrink();
  }
}

  
}