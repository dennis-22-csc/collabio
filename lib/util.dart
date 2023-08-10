import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:collabio/network_handler.dart';

class Util {
  static bool isJSON(String data) {
  try {
    json.decode(data);
    return true;
  } catch (e) {
    return false;
  }
}

static bool isSameDay(String timestamp1, String timestamp2) {
    final DateTime time1 = DateTime.parse(timestamp1);
    final DateTime time2 = DateTime.parse(timestamp2);

    return time1.year == time2.year &&
        time1.month == time2.month &&
        time1.day == time2.day;
  }

  static String formatTime(BuildContext context, String timestamp) {
    final bool is24HoursFormat = MediaQuery.of(context).alwaysUse24HourFormat;
    final DateTime time = DateTime.parse(timestamp);
    final DateFormat formatter = DateFormat(is24HoursFormat ? 'HH:mm' : 'h:mm a');


    return formatter.format(time);
  }

  static String formatTimes(BuildContext context, String timestamp) {
  final DateTime time = DateTime.parse(timestamp);
  final TimeOfDay timeOfDay = TimeOfDay.fromDateTime(time);
  final MaterialLocalizations localizations = MaterialLocalizations.of(context);

  return localizations.formatTimeOfDay(timeOfDay);
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


}
class SharedPreferencesUtil {
  static Future<void> setHasProfile(bool hasProfile) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasProfile', hasProfile);
  }

  static Future<void> setLoggedOut(bool isLoggedOut) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedOut', isLoggedOut);
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
  static Future<List<String>> fetchFailedIdsFromSharedPrefs() async {
    List<String> failedUuids = [];
    SharedPreferences prefs = await SharedPreferences.getInstance();
    failedUuids = prefs.getStringList('failed_message_uuids') ?? [];
    if (failedUuids.isNotEmpty) {
    // Clear the stored failed UUIDs after fetching them
    await prefs.remove('failed_message_uuids');
    }
    return failedUuids;
  }

static Future<void> storeFailedMessageUuids(List<String> failedUuids) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String> existingFailedUuids = prefs.getStringList('failed_message_uuids') ?? [];
  existingFailedUuids.addAll(failedUuids);
  await prefs.setStringList('failed_message_uuids', existingFailedUuids);
}



}