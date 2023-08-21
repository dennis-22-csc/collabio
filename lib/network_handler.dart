import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';
import 'package:collabio/model.dart';
import 'package:collabio/util.dart';
import 'package:collabio/database.dart';

Future<dynamic> fetchUserInfoFromApi(String email) async {
  late String msg;

  try {
    final url = Uri.parse('https://collabio.denniscode.tech/get-user');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({'email': email});

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final contentType = response.headers['content-type'];
      final responseBody = response.body;

      if (contentType?.contains('application/json') == true) {
        final responseData = jsonDecode(responseBody);
        if (responseData.containsKey('error')) {
          return responseData["error"];
        } else if (responseData.containsKey('user')) {
          Map<String, dynamic> results = Map<String, dynamic>.from(responseData['user']);
          return Util.convertJsonToUserInfo(results);
        }
      } else {
        msg = responseBody;
      }
    } else {
      msg = 'HTTP Error: ${response.statusCode}';
    }
  } catch (error) {
    msg = 'User. $error';
  }
  return msg;
}

Future<dynamic> fetchProjectsFromApi() async {
  late String msg;
  try {
    final url = Uri.parse('https://collabio.denniscode.tech/projects');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final contentType = response.headers['content-type'];
      final responseBody = response.body;

      if (contentType?.contains('application/json') == true) {
        final responseData = jsonDecode(responseBody);
        if (responseData.containsKey('error')) {
          return responseData["error"];
        } else if (responseData.containsKey('projects')) {
          final results = responseData['projects'];
          return results.map<Project>((item) {
            return Project.fromMap(item);
          }).toList();
        }
      } else {
        msg = responseBody;
      }
    } else {
      final responseText = response.body.replaceAll(RegExp(r'<[^>]*>'), '');
      msg = 'HTTP Error Projects. $responseText';
    }
  } catch (error) {
    msg = 'Error Projects. $error';
  }
  return msg;
}

Future<dynamic> fetchMessagesFromApi(String email) async {
  late String msg;
  try {
    final url = Uri.parse('https://collabio.denniscode.tech/messages');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({'email': email});

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final contentType = response.headers['content-type'];
      final responseBody = response.body;

      if (contentType?.contains('application/json') == true) {
        dynamic responseData = jsonDecode(responseBody);
        
        if (responseData.containsKey('error')) {
          return responseData["error"];
        } else if (responseData.containsKey('messages')) {
          dynamic jsonData = responseData['messages'];
          
          for (var item in jsonData) {
            item["status"] = "received";
          }
    
          return jsonData.map<Message>((item) {
            return Message.fromMap(item);
          }).toList();
        }
      } else {
        msg = responseBody;
      }
    } else {
      final responseText = response.body.replaceAll(RegExp(r'<[^>]*>'), '');
      msg = 'HTTP Error Messages. $responseText';
    }
  } catch (error) {
    msg = 'Error Messages. $error';
  }
  return msg;
}

Future<String> deleteMessages(List<String> messageIds) async {
  late String msg;
  try {
    final url = Uri.parse('https://collabio.denniscode.tech/del-messages');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({'uuids': messageIds});

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final contentType = response.headers['content-type'];
      final responseBody = response.body;

      if (contentType?.contains('application/json') == true) {
        final responseData = jsonDecode(responseBody);

        if (responseData.containsKey('message')) {
          for (String element in messageIds) {
            await DatabaseHelper.updateMessageStatus(element, "deleted");
          }
          msg = "All messages deleted successfully";
        } else if (responseData.containsKey('results')) {
          Map<String, dynamic> results = Map<String, dynamic>.from(responseData['results']);
          List<String> uuidsList = [];
          List<String> resultsList = [];

          results.forEach((uuid, result) {
            uuidsList.add(uuid);
            resultsList.add('$uuid - $result');
          }); 
          
          Set<String> failedUuidsSet = Set.from(uuidsList);
          for (String element in messageIds) {
            if (!failedUuidsSet.contains(element)) {
              await DatabaseHelper.updateMessageStatus(element, "deleted");
            }
          }
          msg = resultsList[0];
        }
        
      } else {
        msg = "Delete $responseBody";
      }
    } else {
      msg = 'Delete HTTP Error: ${response.statusCode}';
    }
  } catch (error) {
    msg = 'Delete Messages. $error';
  }
  return msg;
}

Future<String> sendProjectData(Map<String, dynamic> projectData) async {
  late String msg;
  String url = 'https://collabio.denniscode.tech/project';

  try {
    final response = await http.post(
      Uri.parse(url),
      body: jsonEncode(projectData),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final contentType = response.headers['content-type'];
      final responseBody = response.body;

      if (contentType?.contains('application/json') == true) {
        return jsonDecode(responseBody);
      } else {
        msg = responseBody;
      }
    } else {
      final responseText = response.body.replaceAll(RegExp(r'<[^>]*>'), '');
      msg = 'HTTP Error Project. $responseText';
    }
  } catch (error) {
    msg = 'Error Project. $error';
  }
  return msg;
}

Future<String> sendMessageData(MessagesModel messagesModel, Map<String, dynamic> messageData, String currentUserEmail) async {
  late String msg;
  String url = 'https://collabio.denniscode.tech/message';

  try {
    await DatabaseHelper.insertMessage(messageData);
    messagesModel.updateGroupedMessages(currentUserEmail);
  } catch (error) {
    msg = 'Send Message Local. $error';
  }

  try {
    final response = await http.post(
      Uri.parse(url),
      body: jsonEncode(messageData),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final contentType = response.headers['content-type'];
      final responseBody = response.body;

      if (contentType?.contains('application/json') == true) {
        final responseData = jsonDecode(responseBody);
        if (responseData == "Message inserted successfully.") {
          await DatabaseHelper.updateMessageStatus(messageData["message_id"], "sent");
          messagesModel.updateGroupedMessages(currentUserEmail);
          return "Message inserted successfully.";
        } else {
          msg = 'Send Message Internal $responseData';
        }
        
      } else {
        msg = responseBody;
      }
    } else {
      final responseText = response.body.replaceAll(RegExp(r'<[^>]*>'), '');
      msg = 'HTTP Error Message. $responseText';
    }
  } catch (error) {
    msg = 'Send Message External. $error';
  }

  await DatabaseHelper.updateMessageStatus(messageData["message_id"], "failed");
  messagesModel.updateGroupedMessages(currentUserEmail);  
  return msg;
}

Future<String> sendUserData(Map<String, dynamic> userData) async {
  late String msg;
  String url = 'https://collabio.denniscode.tech/create-user';

  try {
    final response = await http.post(
      Uri.parse(url),
      body: jsonEncode(userData),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final contentType = response.headers['content-type'];
      final responseBody = response.body;

      if (contentType?.contains('application/json') == true) {
        final responseData = jsonDecode(responseBody);
        msg = responseData;
      }
      
    } else {
      final responseText = response.body.replaceAll(RegExp(r'<[^>]*>'), '');
      msg = 'HTTP Error User. $responseText';
      }
  } catch (error) {
    msg = 'Error saving user data: $error';
  }
  return msg;
}

Future<String> updateProfileSection(String email, String title, dynamic content) async {
  late String msg;
  const String url = 'https://collabio.denniscode.tech/update_profile';
  final Map<String, dynamic> data = {
    'email': email,
  };
  // Assign the specific content to the corresponding field based on the 'title'
  switch (title) {
    case 'First Name':
      data['first_name'] = content;
      break;
    case 'Last Name':
      data['last_name'] = content;
      break;
    case 'About':
      data['about'] = content;
    case 'Skills':
      data['tags'] = content;
    default:
      break;
  }

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final contentType = response.headers['content-type'];
      final responseBody = response.body;

      if (contentType?.contains('application/json') == true) {
        final responseData = jsonDecode(responseBody);
        if (responseData == "Profile updated successfully") {
          SharedPreferencesUtil.updateUserInfo(title, content);
          msg = "Profile section $title updated successfully";
        } else {
          msg = responseData;
        }
      } 
    } else {
      final responseText = response.body.replaceAll(RegExp(r'<[^>]*>'), '');
      msg = 'Failed to update profile section $title. $responseText';
    }
  } catch (e) {
    msg = 'Error occurred while updating profile section "$title". $e';
  }
  return msg;
}

Future<String> updateTokenSection(String email, String token) async {
  late String msg;
  const String url = 'https://collabio.denniscode.tech/update_profile';
  final Map<String, dynamic> data = {
    'email': email,
    'firebase_token': token,
  };
  
  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final contentType = response.headers['content-type'];
      final responseBody = response.body;

      if (contentType?.contains('application/json') == true) {
        final responseData = jsonDecode(responseBody);
        if (responseData == "Profile updated successfully") {
          msg = "Token section updated successfully";
        } else {
          msg = responseData;
        }
      } 
    } else {
      final responseText = response.body.replaceAll(RegExp(r'<[^>]*>'), '');
      msg = 'Failed to update token section. $responseText';
    }
  } catch (e) {
    msg = 'Error occurred while updating token section". $e';
  }
  return msg;
}

Future<String> connectToSocket(MessagesModel messagesModel, String currentUserEmail) async {
    late String msg;
    IO.Socket? socket;
    Set<String> receivedMessageIds = {};
    Set<String> receivedProjectIds = {};

    try {
      socket = IO.io('https://collabio.denniscode.tech', <String, dynamic>{
        'transports': ['websocket'],
        'query': 'email=$currentUserEmail',
      });

      socket.on('new_message', (data) {
        dynamic message = jsonDecode(data);
        message["status"] = "received";
        final messageId = message['message_id'];
        if (!receivedMessageIds.contains(messageId)) {
          DatabaseHelper.insertMessage(message);
          messagesModel.updateGroupedMessages(currentUserEmail);
          receivedMessageIds.add(messageId);
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


      msg = "Connection successful";
    } catch (error) {
      msg = '$error';
    }
    return msg;
  }


