import 'package:collabio/database.dart';
import 'package:flutter/material.dart';

class Project {
  final String id;
  final String title;
  final String timestamp;
  final String description;
  final List<String> tags;
  final String posterName;
  final String posterEmail;
  final String posterAbout;
  double matchPercentage;

  Project({
    required this.id,
    required this.title,
    required this.timestamp,
    required this.description,
    required this.tags,
    required this.posterName,
    required this.posterEmail,
    required this.posterAbout,
    this.matchPercentage = 0.0,
  });

   @override
  String toString() {
    return 'Project{'
        'project_id: $id, '
        'title: $title, '
        'timestamp: $timestamp, '
        'description: $description, '
        'tags: $tags, '
        'poster_name: $posterName, '
        'poster_email: $posterEmail, '
        'poster_about: $posterAbout'
        '}';
  }
  factory Project.fromMap(Map<String, dynamic> map) {
    List<String> tagsList = List<String>.from(map['tags']);

    return Project(
      id: map['project_id'],
      title: map['title'],
      timestamp: map['timestamp'],
      description: map['description'],
      tags: tagsList,
      posterName: map['poster_name'],
      posterEmail: map['poster_email'],
      posterAbout: map['poster_about'],
    );
  }
  Map<String, dynamic> toMap() {
    return {
      DatabaseHelper.columnProjectId: id,
      DatabaseHelper.columnTitle: title,
      DatabaseHelper.columnTimestamp: timestamp,
      DatabaseHelper.columnDescription: description,
      DatabaseHelper.columnTags: tags.join(','), // Convert the list to a comma-separated string
      DatabaseHelper.columnPosterName: posterName,
      DatabaseHelper.columnPosterEmail: posterEmail,
      DatabaseHelper.columnPosterAbout: posterAbout,
    };
  }

}

class Message {
  final String id;
  final String senderName;
  final String senderEmail;
  final String receiverName;
  final String receiverEmail;
  final String message;
  final String timestamp;
  final String status;

  Message({
    required this.id,
    required this.senderName,
    required this.senderEmail,
    required this.receiverName,
    required this.receiverEmail,
    required this.message,
    required this.timestamp,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      DatabaseHelper.columnMessageId: id,
      DatabaseHelper.columnSenderName: senderName,
      DatabaseHelper.columnSenderEmail: senderEmail,
      DatabaseHelper.columnReceiverName: receiverName,
      DatabaseHelper.columnReceiverEmail: receiverEmail,
      DatabaseHelper.columnMessage: message,
      DatabaseHelper.columnMessageTimestamp: timestamp,
      DatabaseHelper.columnMessageStatus: status,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    
    return Message(
      id: map['message_id'],
      senderName: map['sender_name'],
      senderEmail: map['sender_email'],
      receiverName: map['receiver_name'],
      receiverEmail: map['receiver_email'],
      message: map['message'],
      timestamp: map['timestamp'],
      status: map['status'],
    );
  }

   @override
  String toString() {
    return 'Message{'
        'messageId: $id, '
        'senderName: $senderName, '
        'senderEmail: $senderEmail, '
        'receiver: $receiverName, '
        'receiverEmail: $receiverEmail, '
        'message: $message, '
        'timestamp: $timestamp, '
        'status: $status '
        '}';
  }

}

class MessagesModel extends ChangeNotifier {
  Map<String, List<Message>> groupedMessages = {};
  
  Future<void> updateGroupedMessages(String currentUserEmail) async {
    groupedMessages = await DatabaseHelper.getGroupedMessages(currentUserEmail);
    notifyListeners();
  }

}

class ProjectsModel extends ChangeNotifier {
  List<Project> recentProjects = [];
  List<Project> matchingProjects = [];

  Future<void> updateProjects(List<String> keywords, int limit) async {
    recentProjects = await DatabaseHelper.getRecentProjects(limit);
    matchingProjects = await DatabaseHelper.getMatchingProjectsAll(keywords, limit);
    notifyListeners();
  }

  Future<void> updateProjectsForSearch(List<String> keywords, int limit) async {
    recentProjects = await DatabaseHelper.getMatchingProjectsRecent(keywords, limit);
    matchingProjects = await DatabaseHelper.getMatchingProjectsAll(keywords, limit);
    notifyListeners();
  }

  
}
