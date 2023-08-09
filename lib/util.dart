import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';


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

  static Future<bool?> hasProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('hasProfile');
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