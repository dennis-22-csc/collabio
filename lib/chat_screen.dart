import 'package:flutter/material.dart';
import 'package:collabio/model.dart';
//import 'package:collabio/exceptions.dart';
import 'package:collabio/network_handler.dart';
//import 'package:collabio/database.dart';
import 'package:collabio/util.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
//import 'package:fluttertoast/fluttertoast.dart';

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
        title: Text(otherPartyName),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isCurrentUserMessage = message.senderEmail == currentUserEmail;

                bool showDateSeparator = index == 0 ||
                    !Util.isSameDay(
                      messages[index - 1].timestamp,
                      message.timestamp,
                    );

                return Column(
                  children: [
                    if (showDateSeparator)
                      _buildDateSeparator(message.timestamp),
                    Row(
                      mainAxisAlignment: isCurrentUserMessage
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 4.0),
                          constraints: const BoxConstraints(maxWidth: 250),
                          child: Card (
                            child: Row (
                              children: [
                                Expanded(
                                child: Padding (
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column (
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        message.message,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          Util.formatTime(context, message.timestamp),
                                          style: const TextStyle(fontSize: 12, color: Colors.grey)
                                          )
                                        )
                                    ],
                                  )
                                )
                                )
                              ],
                            ) 
                          )


                        ),
                      ],
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


  Widget _buildDateSeparator(String timestamp) {
  final DateTime messageTime = DateTime.parse(timestamp);
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime yesterday = today.subtract(const Duration(days: 1));
  final DateFormat dayFormatter = DateFormat('EEEE'); // Format for day name
  final DateFormat monthDayFormatter = DateFormat('MMMM d'); // Format for month and day
  final DateFormat yearMonthDayFormatter = DateFormat('d MMMM y'); // Format for day, month, and year
  String separatorText = '';

  if (messageTime.isAfter(today)) {
    separatorText = 'Today';
  } else if (messageTime.isAfter(yesterday)) {
    separatorText = 'Yesterday';
  } else if (messageTime.isBefore(yesterday.subtract(const Duration(days: 7)))) {
    separatorText = yearMonthDayFormatter.format(messageTime);
  } else {
    separatorText = messageTime.isBefore(today.subtract(const Duration(days: 7)))
        ? monthDayFormatter.format(messageTime)
        : dayFormatter.format(messageTime);
  }

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
            child: TextField(
              controller: textController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                hintText: 'Enter new message',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(40.0),
                ),
              ),
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
    } catch (error) {
      // Handle errors
    }
  }

  } 
  
}