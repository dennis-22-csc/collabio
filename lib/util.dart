import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:collabio/model.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:collabio/firebase_options.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:math';

class Util {
  
  static Future<File?> compressFile(File file) async{
    
    final filePath = file.absolute.path;

    final lastIndex = filePath.lastIndexOf(RegExp(r'.jp'));
    final splitted = filePath.substring(0, (lastIndex));
    final outPath = "${splitted}_out${filePath.substring(lastIndex)}";
    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path, outPath,
      quality: 15,
    );
    

    if (result != null) {
      return File(result.path);
    } else {
      return null;
    }
  
  }

  static Future<String> getImageString(File profilePicture) async {
    final imageBytes = await profilePicture.readAsBytes();
    final encodedImage = base64Encode(imageBytes);
    return encodedImage;
  }
  static String formatToOneLine(String message) {
  return message.replaceAll(RegExp(r'\n'), ' ').trim();
  }
  
  static Future<bool> initializeFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  }
  static Future<bool> checkInternetConnection() async {
  bool isConnected = await InternetConnectionChecker().hasConnection;
  return isConnected;
}
  static String extractDate(String timestamp) {
  DateTime dateTime = DateTime.parse(timestamp);
  String formattedDate = "${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}";
  return formattedDate;
}

  static String getLetters(String otherPartyName) {
    List<String> nameParts = otherPartyName.split(" ");
  
    String firstLetter = nameParts.isNotEmpty ? nameParts[0][0].toUpperCase() : '';
    String lastLetter = nameParts.length > 1 ? nameParts[nameParts.length - 1][0].toUpperCase() : '';
  
    return "$firstLetter$lastLetter";
  }

  static String formatTime(BuildContext context, String timestamp) {
    final preciseTimestamp = int.parse(timestamp);
    final formatTimeStamp = DateTime.fromMicrosecondsSinceEpoch(preciseTimestamp).toString();
  
    final bool is24HoursFormat = MediaQuery.of(context).alwaysUse24HourFormat;
    final DateTime time = DateTime.parse(formatTimeStamp);
    final DateFormat formatter = DateFormat(is24HoursFormat ? 'HH:mm' : 'h:mm a');


    return formatter.format(time);
  }


static Uint8List? convertBase64ToImage(String imageString) {
    try {
      // Decode base64 string to bytes
      List<int> imageBytes = base64Decode(imageString);

      // Return Uint8List image bytes
      return Uint8List.fromList(imageBytes);
    } catch (e) {
      return null;
    }
}

static Map<String, dynamic> convertJsonToUserInfo(Map<String, dynamic> jsonData) {
  List<String> tagsList = List<String>.from(jsonData['tags']);

  return {
    'email': jsonData['email'] ?? '',
    'firstName': jsonData['first_name'],
    'lastName': jsonData['last_name'],
    'about': jsonData['about'],
    'tags': tagsList,
    'pictureBytes': jsonData['picture_bytes'] ?? '',
    'userId': jsonData['user_id'],
  };
}

  static bool areEquivalentStrings(String str1, String str2) {
  List<String> words1 = str1.split(' ');
  List<String> words2 = str2.split(' ');

  words1.sort();
  words2.sort();

  return words1.join(' ') == words2.join(' ');
}

  static List<Project> getMatchingProjects(List<String> keywords, List<Project> projects, int startRange, int endRange) {
  // Calculate match percentage for each project based on skills in description and tags
  for (Project project in projects) {
    int matchingTagCount = 0;
    int matchingTitleCount = 0;

    List<String> projectTags = project.tags.map((tag) => tag.trim().toLowerCase()).toList();
    List<String> projectTitleWords = project.title.toLowerCase().split(RegExp(r'\s+'));

    for (String skill in keywords) {
      if (projectTags.contains(skill.toLowerCase())) {
        matchingTagCount++;
      }

      if (projectTitleWords.contains(skill.toLowerCase())) {
        matchingTitleCount++;
      }
    }

    double tagWeight = 2; // Tags are assigned more weight
    double matchPercentage = ((matchingTagCount * tagWeight) + matchingTitleCount) /
        (keywords.length * tagWeight + projectTitleWords.length) * 100;
    project.matchPercentage = matchPercentage;
  }

  // Filter projects based on matching skills in description and tags
  List<Project> matchingProjects = projects.where((project) {
    List<String> projectTags = project.tags.map((tag) => tag.trim().toLowerCase()).toList();
    List<String> projectTitleWords = project.title.toLowerCase().split(RegExp(r'\s+'));

    return keywords.any((keyword) =>
        projectTags.contains(keyword.toLowerCase()) ||
        projectTitleWords.contains(keyword.toLowerCase()));
  }).toList();

  // Sort projects based on match percentage (higher to lower)
  matchingProjects.sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));

  int totalProjects = matchingProjects.length;
  int adjustedStartRange = min(startRange, totalProjects);
  int adjustedEndRange = min(endRange, totalProjects);
  // Return matching projects within the specified range
  return matchingProjects.sublist(adjustedStartRange, adjustedEndRange);

  }

  static List<Project> getMatchingProjectsSearch(List<String> keywords, List<Project> projects, int startRange, int endRange) {
  // Create an empty list to store the filtered projects
  List<Project> filteredMatchingProjects = [];

  // Create a set to keep track of projects that match all keywords
  Set<Project> projectsMatchingAllKeywords = Set.from(projects);

  // Create a list to store the keywords used for filtering
  List<String> usedKeywords = [];

  // Create a map of tag patterns
  Map<String, List<String>> tagPatterns = {
    "web development": ["web", "web development", "web design", "website development", "website design", "web app", "web application development"],
    "web design": ["web", "web development", "web design", "website development", "website design", "web app", "web application development"],
    "web": ["web", "web development", "web design", "website development", "website design", "web app", "web application development"],
    "website development": ["web", "web development", "web design", "website development", "website design", "web app", "web application development"],
    "website design": ["web", "web development", "web design", "website development", "website design", "web app", "web application development"],
    "web app": ["web", "web development", "web design", "website development", "website design", "web app", "web application development"],
    "web application development": ["web", "web development", "web design", "website development", "website design", "web app", "web application development"],
    "android development": ["app development", "android development", "android app development", "android application development", "android"],
    "android app development": ["app development", "android development", "android app development", "android application development", "android"],
    "android application development": ["app development","android development", "android app development", "android application development", "android"],
    "android": ["app development", "android development", "android app development", "android application development", "android"],
    "ios": ["app development", "ios development", "ios app development", "ios application development", "ios"],
    "ios application development": ["app development", "ios development", "ios app development", "ios application development", "ios"],
    "ios app development": ["app development", "ios development", "ios app development", "ios application development", "ios"],
    "ios development": ["app development", "ios development", "ios app development", "ios application development", "ios"],
    "app development": ["app development", "ios development", "ios app development", "ios application development", "ios", "android development", "android app development", "android application development", "android"],
  
  };

  keywords = keywords.map((keyword) => keyword.toLowerCase()).toList();

  // Iterate through the keywords
  for (String keyword in keywords) {
    if (tagPatterns.containsKey(keyword)) {
      usedKeywords.add(keyword);
      List<Project> matchingProjects = projects.where((project) =>
          tagPatterns[keyword]!.any((tag) =>
              project.tags.any((t) => t.toLowerCase() == tag.toLowerCase()))).toList();

      // Update the set of projects that match all keywords
      projectsMatchingAllKeywords = projectsMatchingAllKeywords.intersection(Set.from(matchingProjects));
    }
  }

  // Convert the set of matching projects back to a list
  filteredMatchingProjects = projectsMatchingAllKeywords.toList();

  List<String> otherKeywords = keywords.where((keyword) => !usedKeywords.contains(keyword)).toList();

  if (otherKeywords.isNotEmpty) {
    filteredMatchingProjects = filterProjectsByKeywords(filteredMatchingProjects, otherKeywords);
  }

  int totalProjects = filteredMatchingProjects.length;
  int adjustedStartRange = min(startRange, totalProjects);
  int adjustedEndRange = min(endRange, totalProjects);
  // Return matching projects within the specified range
  return filteredMatchingProjects.sublist(adjustedStartRange, adjustedEndRange);
}

static List<Project> filterProjectsByKeywords(List<Project> projects, List<String> keywords) {
  List<Project> filteredProjects = [];

  for (var project in projects) {
    List<String> projectTags = project.tags.map((tag) => tag.toLowerCase()).toList();
    if (keywords.every((keyword) => projectTags.contains(keyword.toLowerCase()))) {
      filteredProjects.add(project);
    }
  }

  return filteredProjects;
}

  static String timeToString(String timestamp) {
  DateTime now = DateTime.now();
  DateTime inputTime = DateTime.parse(timestamp);
  Duration difference = now.difference(inputTime);

  if (difference.inSeconds < 60) {
    return '${difference.inSeconds} seconds ago';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes} minutes ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} hours ago';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} days ago';
  } else if (difference.inDays < 30) {
    int weeks = (difference.inDays / 7).floor();
    return '$weeks week${weeks > 1 ? "s" : ""} ago';
  } else {
    int months = (difference.inDays / 30).floor();
    return '$months month${months > 1 ? "s" : ""} ago';
  }
}


static List<String> getOldestMessageIdsGroupedBy24Hours(List<Message> messages) {
  
  // Create a copy of the newMessages list
  List<Message> sortedMessages = List.from(messages);

  // Sort the copy of the list
  sortedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

  List<String> oldestMessageIds = [];
  List<Message> currentGroup = [];

  for (int i = 0; i < sortedMessages.length; i++) {
    if (currentGroup.isEmpty) {
      currentGroup.add(sortedMessages[i]);
    } else {
      if (DateTime.parse(toTimeString(sortedMessages[i].timestamp)).difference(DateTime.parse(toTimeString(currentGroup.last.timestamp))).inHours <= 24) {
        currentGroup.add(sortedMessages[i]);
      } else {
        oldestMessageIds.add(currentGroup.first.id);
        currentGroup = [sortedMessages[i]];
      }
    }
  }

  if (currentGroup.isNotEmpty) {
    oldestMessageIds.add(currentGroup.first.id);
  }

  return oldestMessageIds;
}

static String toTimeString(String timestamp) {
  final preciseTimestamp = int.parse(timestamp);
  return DateTime.fromMicrosecondsSinceEpoch(preciseTimestamp).toString();
}

}
class SharedPreferencesUtil {
  static Future<void> setHasProfile(bool hasProfile) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasProfile', hasProfile);
  }

  static Future<void> setSentToken(bool sentToken) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sentToken', sentToken);
  }
  
  static Future<void> setLogOutStatus(bool status) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('logout', status);
  }
  static Future<void> setLogInStatus(bool status) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('login', status);
  }

  static Future<void> saveToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('firebase_token', token);
  }
  
  static Future<void> setUserInfo(Map<String, dynamic> userInfo) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String firstName = userInfo['firstName'];
    String lastName = userInfo['lastName'];
    String about = userInfo['about'];
    List<String> tags = userInfo['tags'];
    String email = userInfo['email'];
    String pictureBytes = userInfo['pictureBytes'];

    await prefs.setString('firstName', firstName);
    await prefs.setString('lastName', lastName);
    await prefs.setString('about', about);
    await prefs.setStringList('tags', tags);
    await prefs.setString('email', email);
    await prefs.setString('pictureBytes', pictureBytes);
  }
  static updateUserInfo(String title, dynamic content) async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      switch (title) {
        case 'First Name':
          await prefs.setString('firstName', content);
          break;
        case 'Last Name':
          await prefs.setString('lastName', content);
          break;
        case 'About':
          await prefs.setString('about', content);
        case 'Skills':
          await prefs.setStringList('tags', content);
        case 'Profile Picture':
        await prefs.setString('pictureBytes', content);
        default:
          break;
      }
  }
  static Future<bool> hasProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('hasProfile') ?? false;
  }
  static Future<bool> sentToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('sentToken') ?? false;
  }
  
  static Future<bool> isLogOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('logout') ?? false;
  }

  static Future<bool> isLogIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('login') ?? false;
  }

  static Future<String> getPictureBytesString() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('pictureBytes') ?? '';
  }

  static Future<String> getEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('email') ?? '';
  }

  static Future<String> getFirstName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('firstName') ?? '';
  }

  static Future<String> getLastName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('lastName') ?? '';
  }

  static Future<String> getAbout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('about') ?? '';
  }

  static Future<List<String>> getTags() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('tags') ?? ["mobile app development", "web development"];
  }

  static Future<String> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('firebase_token') ?? '';
  }
  
  static Future<void> clearPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}