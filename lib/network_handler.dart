import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';
import 'package:collabio/model.dart';
import 'package:collabio/util.dart';
import 'package:collabio/exceptions.dart';
import 'package:collabio/database.dart';

/*Future<Map<String, dynamic>> fetchUserInfoFromApi(String email) async {
  try {
    final url = Uri.parse('http://collabio.denniscode.tech/get-user');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({'email': email});

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final contentType = response.headers['content-type'];
      final responseBody = response.body;

      if (contentType?.contains('application/json') == true) {
        final jsonData = jsonDecode(responseBody);
        return Util.convertJsonToUserInfo(jsonData);
      } else {
        throw FetchUserException(responseBody);
      }
    } else {
      throw FetchUserException('HTTP Error: ${response.statusCode}');
    }
  } catch (error) {
    throw FetchUserException('User. $error');
  }
}*/

Future<List<Project>> fetchProjectsFromApi() async {
  try {
    final url = Uri.parse('http://collabio.denniscode.tech/projects');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final contentType = response.headers['content-type'];
      final responseBody = response.body;

      if (contentType?.contains('application/json') == true) {
        final jsonData = jsonDecode(responseBody);
        return jsonData.map<Project>((item) {
          return Project.fromMap(item);
        }).toList();
      } else {
        throw FetchProjectsException(responseBody);
      }
    } else {
      throw FetchProjectsException('HTTP Error: ${response.statusCode}');
    }
  } catch (error) {
    throw FetchProjectsException('Projects. $error');
  }
}

Future<List<Message>> fetchMessagesFromApi(String email) async {
  try {
    final url = Uri.parse('http://collabio.denniscode.tech/messages');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({'email': email});

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final contentType = response.headers['content-type'];
      final responseBody = response.body;

      if (contentType?.contains('application/json') == true) {
        final jsonData = jsonDecode(responseBody) as List<dynamic>;
        return jsonData.map<Message>((item) {
          return Message.fromMap(item);
        }).toList();
      } else {
        throw FetchMessagesException(responseBody);
      }
    } else {
      throw FetchMessagesException('HTTP Error: ${response.statusCode}');
    }
  } catch (error) {
    throw FetchMessagesException('Messages. $error');
  }
}

// Method to delete messages from the API using the inserted message ids
Future<void> deleteMessages(List<String> messageIds) async {
  try {
    final url = Uri.parse('http://collabio.denniscode.tech/del-messages');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({'uuids': messageIds});

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final contentType = response.headers['content-type'];
      final responseBody = response.body;

      if (contentType?.contains('application/json') == true) {
        final responseData = jsonDecode(responseBody);
        if (responseData.containsKey('failed_uuids')) {
          final failedUuids = (responseData['failed_uuids'] as List<dynamic>).cast<String>();
          await SharedPreferencesUtil.storeFailedMessageUuids(failedUuids);
        }
      } else {
        throw DeleteMessagesException(responseBody);
      }
    } else {
      throw DeleteMessagesException('HTTP Error: ${response.statusCode}');
    }
  } catch (error) {
    throw DeleteMessagesException('Delete Messages. $error');
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

    if (response.statusCode == 200) {
      final contentType = response.headers['content-type'];
      final responseBody = response.body;

      if (contentType?.contains('application/json') == true) {
        return jsonDecode(responseBody);
      } else {
        throw SendDataException(responseBody);
      }
    } else {
      throw SendDataException('HTTP Error: ${response.statusCode}');
    }
  } catch (error) {
    throw SendDataException('Post Project. $error');
  }
}

Future<void> sendMessageData(MessagesModel messagesModel, Map<String, dynamic> messageData, String currentUserEmail) async {
  String url = 'http://collabio.denniscode.tech/message';

  try {
    await DatabaseHelper.insertMessage(messageData);
  } catch (error) {
    throw LocalInsertException('Send Message Local. $error');
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
          messagesModel.updateGroupedMessages(currentUserEmail);
        } else {
          throw SendDataException('Send Message Internal $responseData');
        }
      } else {
        throw SendDataException(responseBody);
      }
    } else {
      throw SendDataException('HTTP Error: ${response.statusCode}');
    }
  } catch (error) {
    throw SendDataException('Send Message External. $error');
  }
}

Future<void> sendUserData(Map<String, dynamic> userData) async {
  String url = 'http://collabio.denniscode.tech/create-user';

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
        if (responseData != "User inserted successfully.") {
          throw SendDataException(responseData);
        }
      }
      
    } else {
      throw SendDataException('Failed to save user data. Error code: ${response.statusCode}');
    }
  } catch (error) {
    throw SendDataException('Error saving user data: $error');
  }
}

Future<String> updateProfileSection(String email, String title, dynamic content) async {
  late String msg;
  const String url = 'http://collabio.denniscode.tech/update_profile';
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


