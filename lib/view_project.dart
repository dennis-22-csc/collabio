import 'package:collabio/exceptions.dart';
import 'package:flutter/material.dart';
import 'package:collabio/model.dart';
import 'package:collabio/network_handler.dart';
import 'package:collabio/database.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class ViewProjectScreen extends StatefulWidget {
  final Project project;
  const ViewProjectScreen({
    Key? key,
    required this.project,
  }) : super(key: key);

  @override
  State<ViewProjectScreen> createState() => _ViewProjectScreenState();

}
class _ViewProjectScreenState extends State<ViewProjectScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Project Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Handle menu option
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.project.title,
              style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Text('Posted: ${widget.project.timestamp}'),
            const SizedBox(height: 16.0),
            MarkdownBody(
              data: widget.project.description,
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
              widget.project.posterAbout,
              style: const TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 24.0),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: () {
                  _showMessageDialog(context);
                },
                child: const Text('Message Now'),
              ),
            )
          ],
        ),
      ),
      ),
    );
  }

  void _sendMessage() async {
    
    final message = {
      "message_id": const Uuid().v4(),
      "sender_name": "Dennis",
      "sender_email": "denniskoko@gmail.com",
      "receiver_name": widget.project.posterName,
      "receiver_email": widget.project.posterEmail,
      "message": _messageController.text,
      "timestamp": DateFormat('yyyy-MM-dd HH:mm:ss')
        .format(DateTime.now()),
    };
    final messagesModel = Provider.of<MessagesModel>(context, listen: false);
      
    try {
      await sendMessageData(messagesModel, message, "denniskoko@gmail.com");
      showStatusDialog("Message sent successfully");
    } catch (error) {
      if (error is LocalInsertException){
        showStatusDialog("LocalInsertException. ${error.message}");
      } else if (error is SendDataException){
        await DatabaseHelper.deleteMessage(message['message_id']!);
        showStatusDialog("SendDataException. ${error.message}");
      } else {
        showStatusDialog("Exception. ${error.toString()}");
      }
      
    }

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
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            title: Text('Message ${widget.project.posterName}'),
          ),
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
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
                  onPressed: _sendMessage,
                  child: const Text('Send'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void showStatusDialog(String content){
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hey Chief'),
          content: Text(content),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
  
}
