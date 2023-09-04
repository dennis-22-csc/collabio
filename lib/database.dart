import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:collabio/model.dart';
import 'package:collabio/util.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static late final Future<Database> _database;
  static const String _dbName = 'collabio.db';

  // Table names
  static const String _messagesTable = 'messages';
  static const String _projectsTable = 'projects';
  static const String _usersTable = 'users';

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
  static const columnMessageStatus = 'status';

  // Define column names for users table 
  static const columnEmail = 'email';
  static const columnName = 'name';

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
        await _createUsersTable(db);
      },
    );
  }

  static Future<void> clearDatabase() async {
    final db = await _database;
    db.delete(_projectsTable);
    db.delete(_messagesTable);
    db.delete(_usersTable);
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
        $columnMessageTimestamp TEXT NOT NULL,
        $columnMessageStatus TEXT NOT NULL
      )
      ''');
  }

  // Create the users table
  static Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_usersTable (
        $columnEmail TEXT PRIMARY KEY,
        $columnName TEXT NOT NULL
      )
      ''');
  }

  // Method to insert user into the users table 
  static Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await _database;
    return await db.insert(_usersTable, user, conflictAlgorithm: ConflictAlgorithm.replace);
  }
  // Method to insert projects into the projects table
  static Future<void> insertProjects(List<Project> projects) async {
    final database = await _database;
    final batch = database.batch();
    for (Project project in projects) {
      batch.insert(_projectsTable, project.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit();
  }

  // Method to insert messages into the messages table and return the message ids
  static Future<List<String>> insertMessages(List<Message> messages) async {
  final database = await _database;
  final batch = database.batch();

  List<String> insertedIds = [];
  for (Message message in messages) {
    batch.insert(_messagesTable, message.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    insertedIds.add(message.id);
    final sender = <String, dynamic>{
    'email': message.senderEmail,
     'name': message.senderName,
    };
    final receiver = <String, dynamic>{
    'email': message.receiverEmail,
     'name': message.receiverName,
    };
    insertUser(sender);
    insertUser(receiver);
  }
  await batch.commit();
  return insertedIds;
  }

static Future<bool> insertMessage(Map<String, dynamic> jsonData) async {
  Database db = await _database;
  final Message message = Message.fromMap(jsonData);
  await db.insert(_messagesTable, message.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  return true;
}

static Future<void> updateMessageStatus(String messageId, String newStatus) async {
    Database db = await _database;  
    await db.update(
      _messagesTable,
      {columnMessageStatus: newStatus},
      where: '$columnMessageId = ?',
      whereArgs: [messageId],
    );
}

static Future<bool> deleteMessage(String messageId) async {
  Database db = await _database;
  int rowsDeleted = await db.delete(
    _messagesTable,
    where: 'message_id = ?',
    whereArgs: [messageId],
  );

  return rowsDeleted > 0;
}


static Future<void> insertProject(Map<String, dynamic> jsonData) async { 
  Database db = await _database; 
  final Project project = Project.fromMap(jsonData);
  await db.insert(_projectsTable, project.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
}

  static Future<List<Project>> getRecentProjects(int startRange, int endRange) async {
  Database db = await _database;
  final List<Map<String, dynamic>> maps = await db.query(
    _projectsTable,
    orderBy: "$columnTimestamp DESC",
  );

  // Calculate the actual start and end indices based on the supplied range
  int startIndex = startRange;
  int endIndex = endRange;
  
  // Ensure that the indices are within the bounds of the result set
  if (startIndex < 0) startIndex = 0;
  if (endIndex > maps.length) endIndex = maps.length;

  // Slice the list to get the desired range of results
  final List<Map<String, dynamic>> filteredMaps = maps.sublist(startIndex, endIndex);

  return List.generate(filteredMaps.length, (index) => Project(
    id: filteredMaps[index][columnProjectId],
    title: filteredMaps[index][columnTitle],
    timestamp: filteredMaps[index][columnTimestamp],
    description: filteredMaps[index][columnDescription],
    tags: filteredMaps[index][columnTags].split(','), // Convert the comma-separated string back to a list
    posterName: filteredMaps[index][columnPosterName],
    posterEmail: filteredMaps[index][columnPosterEmail],
    posterAbout: filteredMaps[index][columnPosterAbout],
  ));
}


  static Future<List<Project>> getMatchingProjectsAll(List<String> keywords, int startRange, int endRange) async {
    Database db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(_projectsTable);

    List<Project> projects = maps
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
  return Util.getMatchingProjects(keywords, projects, startRange, endRange);
  }

static Future<List<Project>> getMatchingProjectsRecent(List<String> keywords, int startRange, int endRange) async {
    List<Project> projects = await getRecentProjectsAll();
    return Util.getMatchingProjects(keywords, projects, startRange, endRange);
  }

static Future<List<Project>> getMatchingProjectsSearchAll(List<String> keywords, int startRange, int endRange) async {
    Database db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(_projectsTable);

    List<Project> projects = maps
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
  return Util.getMatchingProjectsSearch(keywords, projects, startRange, endRange);
  }

static Future<List<Project>> getMatchingProjectsSearchRecent(List<String> keywords, int startRange, int endRange) async {
    List<Project> projects = await getRecentProjectsAll();
    return Util.getMatchingProjectsSearch(keywords, projects, startRange, endRange);
  }

static Future<List<Project>> getRecentProjectsAll() async {
    
    Database db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      _projectsTable,
      orderBy: "$columnTimestamp DESC",
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
    ORDER BY $columnMessageTimestamp DESC
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

static Future<List<Map<String, dynamic>>> getUnsentMessages() async {
  final db = await _database;
  final statusValues = ['failed', 'pending'];
  final statusCondition = statusValues.map((status) => '$columnMessageStatus = ?').join(' OR ');

  final maps = await db.query(
    _messagesTable,
    where: statusCondition,
    whereArgs: statusValues,
    orderBy: '$columnMessageTimestamp DESC',
  );

  return List<Map<String, dynamic>>.from(maps);
}

  static Future<List<String>> getMessageIdsWithStatus(String targetStatus) async {
  final db = await _database;

  final maps = await db.query(
    _messagesTable,
    where: '$columnMessageStatus = ?',
    whereArgs: [targetStatus],
  );

  return List.generate(maps.length, (i) {
    return maps[i][columnMessageId] as String;
  });
}

static Future<dynamic> getProjectById(String projectId) async {
  final db = await _database;

  final maps = await db.query(
    _projectsTable,
    where: '$columnProjectId = ?',
    whereArgs: [projectId],
  );

  if (maps.isNotEmpty) {
    return Project.dbMapToProject(maps.first);
  } else {
    return 'Project not found';
  }
}
  static Future<String> getUserNamesByEmail(String email) async {
    final db = await _database;
    final result = await db.rawQuery(
      'SELECT $columnName FROM $_usersTable WHERE $columnEmail = ?',
      [email],
    );
    
    if (result.isNotEmpty) {
      return result.first[columnName] as String;
    } else {
      return 'John Doe';
    }
  }
  static Future<Map<String, String>> getAllUsers() async {
    final db = await _database;
    final result = await db.query(_usersTable);
    
    final users = <String, String>{};

    for (final row in result) {
      final email = row[columnEmail] as String;
      final name = row[columnName] as String;
      users[email] = name;
    }

    return users;
  }

}