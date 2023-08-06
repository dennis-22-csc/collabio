import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Util {
  static bool isJSON(String data) {
  try {
    json.decode(data);
    return true;
  } catch (e) {
    return false;
  }
}
}
class SharedPreferencesUtil {
  static Future<void> setLoggedOut(bool isLoggedOut) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedOut', isLoggedOut);
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