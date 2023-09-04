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
  Future<String> sendProjectData(Map<String, dynamic> projectData) async {
  late String msg;
  String url = 'https://collabio.denniscode.tech/project';

  try {
    final response = await http.post(
      Uri.parse(url),
      body: jsonEncode(projectData),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final contentType = response.headers['content-type'];
      final responseBody = response.body;

      if (contentType?.contains('application/json') == true) {
        return jsonDecode(responseBody);
      } else {
        msg = responseBody;
      }
    } else {
      final responseText = response.body.replaceAll(RegExp(r'<[^>]*>'), '');
      msg = 'HTTP Error Project. $responseText';
    }
  } catch (error) {
    msg = 'Error Project. $error';
  }
  return msg;
}

Future<String> sendMessageData(Map<String, dynamic> messageData) async {
  late String msg;
  String url = 'https://collabio.denniscode.tech/message';

  try {
    final response = await http.post(
      Uri.parse(url),
      body: jsonEncode(messageData),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final contentType = response.headers['content-type'];
      final responseBody = response.body;

      if (contentType?.contains('application/json') == true) {
        final responseData = jsonDecode(responseBody);
        if (responseData == "Message inserted successfully.") {
          return "Message inserted successfully.";
        } else {
          msg = 'Send Message Internal $responseData';
        }
        
      } else {
        msg = responseBody;
      }
    } else {
      final responseText = response.body.replaceAll(RegExp(r'<[^>]*>'), '');
      msg = 'HTTP Error Message. $responseText';
    }
  } catch (error) {
    msg = 'Send Message External. $error';
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


}



void main() async {
  final dataSender = DataSender();
  
  // Simulate sending a new message to the Flask /message route
  final message1 = {
    "message_id": const Uuid().v4(),
    "sender_name": "Alimat Sadiat",
    "sender_email": "alimatsadiat@gmail.com",
    "receiver_name": "Dennis Akpotaire",
    "receiver_email": "dennisthebusinessguru@gmail.com",
    "message": "Can you tell me a bit about your background?",
    "timestamp": DateTime.now().toUtc().microsecondsSinceEpoch.toString(),
    "status": "pending",
  };

  final message2 = {
    "message_id": const Uuid().v4(),
    "sender_name": "Ola Smith",
    "sender_email": "olasmith@gmail.com",
    "receiver_name": "Dennis Akpotaire",
    "receiver_email": "dennisthebusinessguru@gmail.com",
    "message": "I'm fine too.",
    "timestamp": DateTime.now().toUtc().microsecondsSinceEpoch.toString(),
    "status": "pending",
  };

final project1 = {
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
    'poster_email': 'racheloniga@gmail.com',
    'poster_about': 'A programmer',
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
    'poster_name': 'Alimat Sadiat',
    'poster_email': 'alimatsadiat@gmail.com',
    'poster_about': 'A developer',
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
    'tags': ['Mobile App Development', 'Personal Finance', 'Android'],
    'poster_name': 'Ola Smith',
    'poster_email': 'olasmith@gmail.com',
    'poster_about': 'A designer',
};

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
    'poster_name': 'Rachel Oniga',
    'poster_email': 'racheloniga@gmail.com',
    'poster_about': 'A programmer',
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
    'poster_name': 'Alimat Sadiat',
    'poster_email': 'alimatsadiat@gmail.com',
    'poster_about': 'A developer',
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
    'poster_name': 'Ola Smith',
    'poster_email': 'olasmith@gmail.com',
    'poster_about': 'A designer',
}
];

 //final messageResponse = await dataSender.sendMessageData(message1);
 //print(messageResponse);
  
  final projectResponse = await dataSender.sendProjectData(project3);
  print('Project response: $projectResponse');
  /*const imageUrl = 'https://ucarecdn.com/a59c6d79-1baf-412f-bf78-c7d7a7e31712/image14.jpg';
  final response = await http.get(Uri.parse(imageUrl));

  if (response.statusCode == 200) {
    final imageBytes = response.bodyBytes;
    final encodedImageString = base64Encode(imageBytes);
    final imageResponse = await dataSender.updateProfileSection("dennisthebusinessguru@gmail.com", "Profile Picture", encodedImageString);
    print(imageResponse);
  }*/
  //final userResponse = await dataSender.fetchUserInfoFromApi("denniskoko@gmail.com");
  //print('User Response: $userResponse');

  //List<Project> projects = projectData.map((projectMap) => Project.fromMap(projectMap)).toList();

  /*List<Project> matchingProjects1 = getMatchingProjects(["mobile app development", "android", ], projects, 10);
  for (var project in matchingProjects1) {
    print(project);
  }*/

  /*List<Project> matchingProjects2 = getMatchingProjects(["Finance", ], projects, 10);
  for (var project in matchingProjects2) {
    print(project);
  }*/
  /*String formatToOneLine(String message) {
  return message.replaceAll(RegExp(r'\n'), ' ').trim();
}
  
  String input = "Hello, world!\nHow are you?\nThis is a test;\n a test of formatting,\nParentheses ()\n can be tricky.";
  print(formatToOneLine(input));*/
  //final timestampString = DateTime.now().toUtc().microsecondsSinceEpoch.toString();
  

}