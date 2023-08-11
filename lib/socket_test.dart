import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class Project {
  final String id;
  final String title;
  final String timestamp;
  final String description;
  final List<String> tags;
  final String posterName;
  final String posterEmail;
  double matchPercentage;

  Project({
    required this.id,
    required this.title,
    required this.timestamp,
    required this.description,
    required this.tags,
    required this.posterName,
    required this.posterEmail,
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
        'poster_email: $posterEmail '
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
    );
  }
  

}


List<Project> getMatchingProjects(
    List<String> keywords, List<Project> projects, int numProjectsToReturn) {
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

class DataSender {
  Future<String> sendMessageData(Map<String, dynamic> messageData) async {
    late String msg;
  String url = 'http://collabio.denniscode.tech/message';

  try {
    final response = await http.post(
      Uri.parse(url),
      body: jsonEncode(messageData),
      headers: {'Content-Type': 'application/json'},
    );

    
    dynamic responseData = jsonDecode(response.body);
      
    msg = responseData;
    
  } catch (e) {
    msg = 'Send Message. $e';
  }
  return msg;
}

  Future<dynamic> createNewProject(Map<String, dynamic> project) async {
    const url = 'http://collabio.denniscode.tech/project';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(project),
    );

    return jsonDecode(response.body);
  }

}



void main() async {
  /*final dataSender = DataSender();
  
  // Simulate sending a new message to the Flask /message route
  final message = {
    "message_id": const Uuid().v4(),
    "sender_name": "Alimat Sadiat",
    "sender_email": "alimatsadiat@gmail.com",
    "receiver_name": "Dennis Akpotaire",
    "receiver_email": "dennisthebusinessguru@gmail.com",
    "message": "Okay",
    "timestamp": DateFormat('yyyy-MM-dd HH:mm:ss')
        .format(DateTime.now()),
  };*/

/*final project1 = {
    'title': 'Build a Social Networking Platform',
    'timestamp': DateFormat('yyyy-MM-dd HH:mm:ss')
        .format(DateTime.now()),
    'description': '''
I am seeking a team of developers to collaborate with me on building a social networking platform similar to Facebook and Twitter.

The platform will have a user-friendly interface with features such as user profiles, posting updates, commenting, liking, and following other users.

It will also include a notification system, search functionality, and privacy settings.

The project will involve front-end and back-end development, database design, API integration, and rigorous testing to ensure scalability and security.

The target audience for the platform is individuals looking to connect with others and share their experiences online.

If you are interested in joining this exciting project, please get in touch with me.
    ''',
    'tags': ['Web Development', 'Social Networking', 'Frontend', 'Backend'],
    'poster_name': 'Rachel',
    'poster_email': 'racheloniga@gmail.com'
};

final project2 = {
    'title': 'Build Online Course Platform',
    'timestamp': DateFormat('yyyy-MM-dd HH:mm:ss')
        .format(DateTime.now()),
    'description': '''
I am looking for developers and educators to collaborate on building an online course platform like Udemy or Coursera.

The platform will offer a wide range of courses on various subjects, including video lectures, quizzes, and assignments.

Users should be able to sign up, enroll in courses, and track their progress.

The project will involve designing an intuitive user interface, developing the platform's functionality, implementing secure payment processing, and integrating video streaming services.

Quality assurance and performance optimization will be essential to deliver an excellent user experience.

The target audience for the platform is students and professionals seeking to enhance their skills and knowledge through online learning.

If you are passionate about education and technology, please reach out to me to discuss further.
    ''',
    'tags': ['Web Development', 'Education', 'Online Learning', 'Video Streaming'],
    'poster_name': 'Alimat',
    'poster_email': 'alimatsadiat@gmail.com'
};

final project3 = {
    'title': 'Build a Personal Finance Mobile App',
    'timestamp': DateFormat('yyyy-MM-dd HH:mm:ss')
        .format(DateTime.now()),
    'description': '''
I am searching for a skilled mobile app developer to collaborate on creating a personal finance app for both iOS and Android platforms.

The app will help users manage their finances by tracking expenses, setting budgets, and providing financial insights.

It will have a user-friendly interface, interactive charts, and data synchronization across devices.

Security is of utmost importance, and the app will use encryption to protect sensitive financial data.

The project will involve UI/UX design, development, API integration with financial institutions, and rigorous testing to ensure data accuracy and privacy.

The target audience for the app is individuals who want to take control of their spending and savings habits.

If you are interested in contributing to this app and helping people achieve their financial goals, please send me a message.
    ''',
    'tags': ['Mobile App Development', 'Personal Finance', 'iOS', 'Android'],
    'poster_name': 'Ola',
    'poster_email': 'olasmith@gmail.com'
};*/

final projectData = [ {
    "project_id": const Uuid().v4(),
    'title': 'Build a Social Networking Platform',
    'timestamp': DateFormat('yyyy-MM-dd HH:mm:ss')
        .format(DateTime.now()),
    'description': '''
I am seeking a team of developers to collaborate with me on building a social networking platform similar to Facebook and Twitter.

The platform will have a user-friendly interface with features such as user profiles, posting updates, commenting, liking, and following other users.

It will also include a notification system, search functionality, and privacy settings.

The project will involve front-end and back-end development, database design, API integration, and rigorous testing to ensure scalability and security.

The target audience for the platform is individuals looking to connect with others and share their experiences online.

If you are interested in joining this exciting project, please get in touch with me.
    ''',
    'tags': ['Web Development', 'Social Networking', 'Frontend', 'Backend'],
    'poster_name': 'Rachel',
    'poster_email': 'racheloniga@gmail.com'
} , {
    "project_id": const Uuid().v4(),
    'title': 'Build Online Course Platform',
    'timestamp': DateFormat('yyyy-MM-dd HH:mm:ss')
        .format(DateTime.now()),
    'description': '''
I am looking for developers and educators to collaborate on building an online course platform like Udemy or Coursera.

The platform will offer a wide range of courses on various subjects, including video lectures, quizzes, and assignments.

Users should be able to sign up, enroll in courses, and track their progress.

The project will involve designing an intuitive user interface, developing the platform's functionality, implementing secure payment processing, and integrating video streaming services.

Quality assurance and performance optimization will be essential to deliver an excellent user experience.

The target audience for the platform is students and professionals seeking to enhance their skills and knowledge through online learning.

If you are passionate about education and technology, please reach out to me to discuss further.
    ''',
    'tags': ['Web Development', 'Education', 'Online Learning', 'Video Streaming'],
    'poster_name': 'Alimat',
    'poster_email': 'alimatsadiat@gmail.com'
}, {
    "project_id": const Uuid().v4(),
    'title': 'Build a Personal Finance Mobile App',
    'timestamp': DateFormat('yyyy-MM-dd HH:mm:ss')
        .format(DateTime.now()),
    'description': '''
I am searching for a skilled mobile app developer to collaborate on creating a personal finance app for both iOS and Android platforms.

The app will help users manage their finances by tracking expenses, setting budgets, and providing financial insights.

It will have a user-friendly interface, interactive charts, and data synchronization across devices.

Security is of utmost importance, and the app will use encryption to protect sensitive financial data.

The project will involve UI/UX design, development, API integration with financial institutions, and rigorous testing to ensure data accuracy and privacy.

The target audience for the app is individuals who want to take control of their spending and savings habits.

If you are interested in contributing to this app and helping people achieve their financial goals, please send me a message.
    ''',
    'tags': ['Mobile App Development', 'Personal Finance', 'iOS', 'Android'],
    'poster_name': 'Ola',
    'poster_email': 'olasmith@gmail.com'
}
];
 //final messageResponse = await dataSender.sendMessageData(message);
 //print(messageResponse);
  
  //final projectResponse = await dataSender.createNewProject(project3);
  //print('Project response: $projectResponse');

  //final userResponse = await dataSender.fetchUserInfoFromApi("denniskoko@gmail.com");
  //print('User Response: $userResponse');

  List<Project> projects = projectData.map((projectMap) => Project.fromMap(projectMap)).toList();

  /*List<Project> matchingProjects1 = getMatchingProjects(["mobile app development", "android", ], projects, 10);
  for (var project in matchingProjects1) {
    print(project);
  }*/

  List<Project> matchingProjects2 = getMatchingProjects(["Finance", ], projects, 10);
  for (var project in matchingProjects2) {
    print(project);
  }

}