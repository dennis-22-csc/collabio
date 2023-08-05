import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:collabio/model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static late final Future<Database> _database;
  static const String _dbName = 'collabio.db';

  // Table names
  static const String _messagesTable = 'messages';
  static const String _projectsTable = 'projects';

  // Define column names for the projects table
  static const columnProjectId = 'project_id';
  static const columnTitle = 'title';
  static const columnTimestamp = 'timestamp';
  static const columnDescription = 'description';
  static const columnTags = 'tags';
  static const columnPosterName = 'poster_name';
  static const columnPosterEmail = 'poster_email';
  static const columnPosterAbout = 'poster_about';

  // Define column names for the messages table
  static const columnMessageId = 'message_id';
  static const columnSenderName = 'sender_name';
  static const columnSenderEmail = 'sender_email';
  static const columnReceiverName = 'receiver_name';
  static const columnReceiverEmail = 'receiver_email';
  static const columnMessage = 'message';
  static const columnMessageTimestamp = 'timestamp';

  
  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  static Future<void> initDatabase() async {
    String path = await getDatabasesPath();
    _database = openDatabase(
      join(path, _dbName),
      version: 1,
      onCreate: (db, version) async {
        // Create tables when the database is created for the first time
        await _createMessagesTable(db);
        await _createProjectsTable(db);
      },
    );
  }

   // Create the projects table
  static Future<void> _createProjectsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_projectsTable (
        $columnProjectId TEXT PRIMARY KEY,
        $columnTitle TEXT NOT NULL,
        $columnTimestamp TEXT NOT NULL,
        $columnDescription TEXT NOT NULL,
        $columnTags TEXT NOT NULL,
        $columnPosterName TEXT NOT NULL,
        $columnPosterEmail TEXT NOT NULL,
        $columnPosterAbout TEXT NOT NULL
      )
      ''');
  }

  // Create the messages table
  static Future<void> _createMessagesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_messagesTable (
        $columnMessageId TEXT PRIMARY KEY,
        $columnSenderName TEXT NOT NULL,
        $columnSenderEmail TEXT NOT NULL,
        $columnReceiverName TEXT NOT NULL,
        $columnReceiverEmail TEXT NOT NULL,
        $columnMessage TEXT NOT NULL,
        $columnMessageTimestamp TEXT NOT NULL
      )
      ''');
  }

  // Method to insert projects into the projects table
  static Future<void> insertProjects(List<Project> projects) async {
    final database = await _database;
    final batch = database.batch();
    for (Project project in projects) {
      batch.insert(_projectsTable, project.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit();
  }

  // Method to insert messages into the messages table and return the message ids
  static Future<List<String>> insertMessages(List<Message> messages) async {
  final database = await _database;
  final batch = database.batch();

  List<String> insertedIds = [];
  for (Message message in messages) {
    batch.insert(_messagesTable, message.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
    insertedIds.add(message.id);
  }
  await batch.commit();
  return insertedIds;
  }

static Future<String> insertMessageFromApi(Map<String, dynamic> jsonData) async {
  Database db = await _database; 
  final Message message = Message.fromMap(jsonData);
  await db.insert(_messagesTable, message.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
  return message.id;
}

static Future<void> insertProjectFromApi(Map<String, dynamic> jsonData) async { 
  Database db = await _database; 
  final Project project = Project.fromMap(jsonData);
  await db.insert(_projectsTable, project.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
}


  // Function to get the most recent projects (based on timestamp)
  static Future<List<Project>> getRecentProjects(int limit) async {
    
    Database db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      _projectsTable,
      orderBy: "$columnTimestamp DESC",
      limit: limit,
    );
    return List.generate(maps.length, (index) => Project(
      id: maps[index][columnProjectId],
      title: maps[index][columnTitle],
      timestamp: maps[index][columnTimestamp],
      description: maps[index][columnDescription],
      tags: maps[index][columnTags].split(','), // Convert the comma-separated string back to a list
      posterName: maps[index][columnPosterName],
      posterEmail: maps[index][columnPosterEmail],
      posterAbout: maps[index][columnPosterAbout],
    ));
  }

  /*static Future<List<Project>> getRecentProjects(int limit) async {
  Database db = await _database;
  final List<Map<String, dynamic>> maps = await db.query(
    _projectsTable,
    orderBy: "$columnTimestamp DESC",
    limit: limit,
  );
  return List.generate(maps.length, (index) => Project.fromMap(maps[index]));
}*/

  // Function to get projects that match the freelancer's profile
  /*static Future<List<Project>> getMatchingProjects(List<String> freelancerSkills) async {
    Database db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(_projectsTable);

    List<Project> matchingProjects = maps
        .map((map) => Project(
              id: map[columnProjectId],
              title: map[columnTitle],
              timestamp: map[columnTimestamp],
              description: map[columnDescription],
              tags: map[columnTags].split(','), // Convert the comma-separated string back to a list
              posterName: map[columnPosterName],
              posterEmail: map[columnPosterEmail],
              posterAbout: map[columnPosterAbout],
            ))
        .toList();

    // Filter the projects based on the percentage of matching skills
    matchingProjects = matchingProjects.where((project) {
      List<String> projectSkills = project.tags;
      int matchingCount = 0;

      for (String skill in freelancerSkills) {
        if (projectSkills.contains(skill)) {
          matchingCount++;
        }
      }

      double matchPercentage = (matchingCount / freelancerSkills.length) * 100;
      return matchPercentage >= 60;
    }).toList();

    return matchingProjects;
  }*/

  static Future<List<Project>> getMatchingProjects(List<String> freelancerSkills, int rankingPoolSize) async {
  Database db = await _database;
  final List<Map<String, dynamic>> maps = await db.query(_projectsTable);

  List<Project> matchingProjects = maps
      .map((map) => Project.fromMap(map))
      .toList();

  // Calculate the matching percentage for each project and store it in a map
  Map<Project, double> projectMatchPercentage = {};
  for (var project in matchingProjects) {
    List<String> projectSkills = project.tags;
    int matchingCount = 0;

    for (String skill in freelancerSkills) {
      if (projectSkills.contains(skill)) {
        matchingCount++;
      }
    }

    double matchPercentage = (matchingCount / freelancerSkills.length) * 100;
    projectMatchPercentage[project] = matchPercentage;
  }

  // Sort the projects based on the matching percentage in descending order
  List<Project> rankedProjects = projectMatchPercentage.keys.toList()
    ..sort((a, b) => projectMatchPercentage[b]!.compareTo(projectMatchPercentage[a]!));

  // Take the top N projects from the ranking pool
  int limit = rankingPoolSize <= rankedProjects.length ? rankingPoolSize : rankedProjects.length;
  List<Project> topProjects = rankedProjects.sublist(0, limit);

  return topProjects;
}

  // Function to retrieve all messages in groups based on the email address of the other party
  static Future<Map<String, List<Message>>> getGroupedMessages(String currentUserEmail) async {
    final db = await _database;
    final maps = await db.rawQuery('''
      SELECT *,
      CASE
        WHEN $columnSenderEmail = ? THEN $columnReceiverEmail
        ELSE $columnSenderEmail
      END AS group_key
      FROM $_messagesTable
      WHERE $columnSenderEmail = ? OR $columnReceiverEmail = ?
      ORDER BY group_key, $columnMessageTimestamp ASC
    ''', [currentUserEmail, currentUserEmail, currentUserEmail]);

    final groupedMessages = <String, List<Message>>{};
    for (final map in maps) {
      final message = Message.fromMap(map);
      final groupKey = map['group_key'] as String;
      if (groupedMessages[groupKey] == null) {
        groupedMessages[groupKey] = [];
      }
      groupedMessages[groupKey]!.add(message);
    }

    return groupedMessages;
  }
  
}