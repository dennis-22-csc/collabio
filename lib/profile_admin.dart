import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:uuid/uuid.dart';

Future<String> createProfile(Map<String, dynamic> userData) async {
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
    msg = 'Error creating profile: $error';
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
      break;
    case 'Profile Picture':
      data['picture_bytes'] = content;
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


Future<String> getProfilePictureString(String imageName) async {
  
  // Construct the path to the image file in the Downloads folder
  String imagePath = '/home/dennis/Downloads/$imageName';
  
  // Access the image file
  File imageFile = File(imagePath);
  
  // Check if the file exists
  if (imageFile.existsSync()) {
    
    // Read the image file as bytes
    List<int> imageBytes = imageFile.readAsBytesSync();
    
    // Return the image bytes as a base64 string
    return base64Encode(imageBytes);
    
  } else {
    return 'Image file does not exist.';
  }
}



void main() async {
  List<String> selectedTags = ["Javascript", "HTML", "CSS", "Python", "Bootstrap", "C", "React"];

  Map<String, dynamic> userData = {
    'first_name': "",
    'last_name': "",
    'email': "",
    'about': "",
    'tags': selectedTags,
    'picture_bytes': await getProfilePictureString("xyz.jpeg"),
    'user_id': const Uuid().v4(),
  };
    
  final createProfileResponse = await createProfile(userData);
  print(createProfileResponse);
}
