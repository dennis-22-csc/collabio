import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:collabio/network_handler.dart';
import 'package:collabio/model.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:collabio/firebase_options.dart';

class Util {
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
    final bool is24HoursFormat = MediaQuery.of(context).alwaysUse24HourFormat;
    final DateTime time = DateTime.parse(timestamp);
    final DateFormat formatter = DateFormat(is24HoursFormat ? 'HH:mm' : 'h:mm a');


    return formatter.format(time);
  }

static Map<String, dynamic> convertJsonToUserInfo(Map<String, dynamic> jsonData) {
  List<String> tagsList = List<String>.from(jsonData['tags']);

  return {
    'firstName': jsonData['first_name'],
    'lastName': jsonData['last_name'],
    'about': jsonData['about'],
    'tags': tagsList,
  };
}

static Future<String> saveProfileInformation({
    required String firstName,
    required String lastName,
    required String about,
    required String email,
    required List<String> tags,
  }) async {
    Map<String, dynamic> userData = {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'about': about,
        'tags': tags,
        
      };
    
    String result = await sendUserData(userData);
    return result;
  }

   static Future<bool> _requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      return true;
    } else {
      var result = await permission.request();
      if (result == PermissionStatus.granted) {
        return true;
      }
    }
    return false;
  }


   static Future<bool> saveProfilePicture(File profilePicture) async {
     Directory? directory;

     if (Platform.isAndroid) {
       directory = await getExternalStorageDirectory();
       if (directory != null) {
         String newPath = "";

         List<String> paths = directory.path.split("/");
         for (int x = 1; x < paths.length; x++) {
           String folder = paths[x];
           if (folder != "Android") {
             newPath += "/$folder";
           } else {
             break;
           }
         }
         newPath = "$newPath/Collabio/profile_picture";
         directory = Directory(newPath);
       }
     }

     if (directory != null && !await directory.exists()) {
       await directory.create(recursive: true);
     }
     if (directory != null && await directory.exists()) {
       File saveFile = File("${directory.path}/${profilePicture.path.split('/').last}");
       await profilePicture.copy(saveFile.path);
       SharedPreferences prefs = await SharedPreferences.getInstance();
       await prefs.setString('profile_picture', saveFile.path);

       return true;
     }

     return false;
   }


   static Future<bool> checkAndCreateDirectory(BuildContext context) async {
     if (Platform.isAndroid) {
       if (await _requestPermission(Permission.storage)) {
         Directory? directory = await getExternalStorageDirectory();
         if (directory != null) {
           String newPath = "${directory.path}/Collabio/profile_picture";
           directory = Directory(newPath);
           if (!await directory.exists()) {
             await directory.create(recursive: true);
           }
           return true; // Directory creation successful
         }
       }
     }
     return false; // Directory creation failed
   }

  static bool areEquivalentStrings(String str1, String str2) {
  List<String> words1 = str1.split(' ');
  List<String> words2 = str2.split(' ');

  words1.sort();
  words2.sort();

  return words1.join(' ') == words2.join(' ');
}

  static List<Project> getMatchingProjects(List<String> keywords, List<Project> projects, int numProjectsToReturn) {
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

  // Return the top numProjectsToReturn matching projects
  return matchingProjects.take(numProjectsToReturn).toList();
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
      if (DateTime.parse(sortedMessages[i].timestamp).difference(DateTime.parse(currentGroup.last.timestamp)).inHours <= 24) {
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

  static Future<void> setLoggedOut(bool isLoggedOut) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedOut', isLoggedOut);
  }

  static Future<void> saveToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('firebase_token', token);
  }

  static Future<void> setUserInfo(Map<String, dynamic> userInfo) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? firstName = userInfo['firstName'];
    String? lastName = userInfo['lastName'];
    String? about = userInfo['about'];
    List<String>? tags = userInfo['tags'];

    await prefs.setString('firstName', firstName ?? '');
    await prefs.setString('lastName', lastName ?? '');
    await prefs.setString('about', about ?? '');
    await prefs.setStringList('tags', tags ?? []);
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
  static Future<bool> isLoggedOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedOut') ?? false;
  }

  static Future<String?> getPersistedFilePath() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('profile_picture');
  }

  static Future<String?> getFirstName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('firstName');
  }

  static Future<String?> getLastName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('lastName');
  }

  static Future<String?> getAbout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('about');
  }

  static Future<List<String>?> getTags() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('tags');
  }

  static Future<String> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('firebase_token') ?? '';
  }

}