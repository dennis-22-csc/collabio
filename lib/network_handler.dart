import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';
import 'package:collabio/model.dart';
import 'package:collabio/util.dart';
import 'package:collabio/exceptions.dart';
import 'package:collabio/database.dart';

Future<List<Project>> fetchProjectsFromApi() async {
    
    try{
      final url = Uri.parse('http://collabio.denniscode.tech/projects');
      final response = await http.get(url);
      
      final jsonData = jsonDecode(response.body);
      
      return jsonData.map<Project>((item) {
          return Project.fromMap(item);
      }).toList();
      
    } catch (error) {
      throw FetchProjectsException('Projects. $error');
    }
    
}

Future<List<Message>> fetchMessagesFromApi(String email) async {
  
  try {
  // Fetch messages from the API
  final url = Uri.parse('http://collabio.denniscode.tech/messages');
  final headers = {'Content-Type': 'application/json'};
  final body = jsonEncode({'email': email});

  final response = await http.post(url, headers: headers, body: body);

  final jsonData = jsonDecode(response.body) ['status'] as List<dynamic>; 
  return jsonData.map<Message>((item) {
    return Message.fromMap(item);
  }).toList();
    
  } catch (error) {
    throw FetchMessagesException('Messages. $error');
  }
  
}

// Method to delete messages from the API using the inserted message ids
Future<void> deleteMessages(List<String> messageIds) async {
  try{
  final url = Uri.parse('http://collabio.denniscode.tech/del-messages');
  final headers = {'Content-Type': 'application/json'};
  final body = jsonEncode({'uuids': messageIds});

  final response = await http.post(url, headers: headers, body: body);

    final responseData = jsonDecode(response.body);
    if (responseData.containsKey('failed_uuids')) {
      final failedUuids = (responseData['failed_uuids'] as List<dynamic>).cast<String>();
      await SharedPreferencesUtil.storeFailedMessageUuids(failedUuids);
    } 
  } catch (error) {
    throw DeleteMessagesException ('Delete Messages. $error');
  }
}

Future<String> sendProjectData(Map<String, dynamic> projectData) async {
  String url = 'http://collabio.denniscode.tech/projects';

  try {
    final response = await http.post(
      Uri.parse(url),
      body: jsonEncode(projectData),
      headers: {'Content-Type': 'application/json'},
    );

    final responseData = jsonDecode(response.body);
    return responseData['message']; 
  } catch (e) {
    throw SendDataException('Post Project. $e');
  }
}

Future<void> sendMessageData(MessagesModel messagesModel, Map<String, dynamic> messageData, String currentUserEmail) async {
  String url = 'http://collabio.denniscode.tech/message';

  try {
    await DatabaseHelper.insertMessage(messageData);
  } catch (e) {
    throw LocalInsertException ('Send Message Local. $e');
  }
  try {
    final response = await http.post(
    Uri.parse(url),
    body: jsonEncode(messageData),
    headers: {'Content-Type': 'application/json'},
    );

    dynamic responseData = jsonDecode(response.body);
    final result = responseData['result'];
    if (result == "Message inserted successfully.") {
      messagesModel.updateGroupedMessages(currentUserEmail);
    } else {
      throw SendDataException ('Send Message Internal $result');
    }
    
  } catch (e) {
    throw SendDataException ('Send Message External. $e');
  }
    
  
}


Future<void> connectToSocket(MessagesModel messagesModel, String currentUserEmail) async {
    IO.Socket? socket;
    Set<String> receivedMessageIds = {};
    Set<String> receivedProjectIds = {};

    try {
      socket = IO.io('http://collabio.denniscode.tech', <String, dynamic>{
        'transports': ['websocket'],
        'query': 'email=$currentUserEmail',
      });

      socket.on('new_message', (data) {
        List<String> messageIds = [];
        final message = jsonDecode(data);
        final messageId = message['message_id'];
        if (!receivedMessageIds.contains(messageId)) {
          DatabaseHelper.insertMessage(message);
          messageIds.add(messageId);
          messagesModel.updateGroupedMessages(currentUserEmail);
          receivedMessageIds.add(messageId);
          deleteMessages(messageIds);
        }
      });

      socket.on('new_project', (data) {
        final project = jsonDecode(data);
        final projectId = project['project_id'];
        if (!receivedProjectIds.contains(projectId)) {
          DatabaseHelper.insertProject(project);
          receivedProjectIds.add(projectId);
        }
      });

      
    } catch (error) {
      throw SocketException ('$error');
    }

  }


