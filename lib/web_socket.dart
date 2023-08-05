import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';

class SocketListener {
  void connectToSocket(String currentUserEmail) {
    IO.Socket? socket;
    Set<String> receivedMessageIds = {};
    Set<String> receivedProjectIds = {};

    socket = IO.io('http://collabio.denniscode.tech', <String, dynamic>{
      'transports': ['websocket'],
      'query': 'email=$currentUserEmail',
    });

    /*socket.on('connect', (_) {
      print('Connected to Socket.IO server');
    });

    socket.on('disconnect', (_) {
      print('Disconnected from Socket.IO server');
    });*/

    socket.on('new_message', (data) {
      final message = jsonDecode(data);
      final messageId = message['message_id'];
      if (!receivedMessageIds.contains(messageId)) {
        print('Received new message: $message');
        receivedMessageIds.add(messageId);
      }
    });

    socket.on('new_project', (data) {
      final project = jsonDecode(data);
      final projectId = project['project_id'];
      if (!receivedProjectIds.contains(projectId)) {
        print('Received new project: $project');
        receivedProjectIds.add(projectId);
      }
    });


  }
  }

void main() {
  final currentUserEmail = 'denniskoko@gmail.com';
  final socketListener = SocketListener();
  socketListener.connectToSocket(currentUserEmail);
}