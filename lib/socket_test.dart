import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class DataSender {
  Future<Map<String, dynamic>> sendNewMessage(Map<String, dynamic> message) async {
    const url = 'http://collabio.denniscode.tech/message';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(message),
    );

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> createNewProject(Map<String, dynamic> project) async {
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
  final dataSender = DataSender();
  
  // Simulate sending a new message to the Flask /message route
  final message = {
    "sender_name": "Kunle",
    "sender_email": "kunleajayi@gmail.com",
    "receiver_name": "Dennis",
    "receiver_email": "denniskoko@gmail.com",
    "message": "How are you?",
    "timestamp": DateFormat('yyyy-MM-dd HH:mm:ss')
        .format(DateTime.now().subtract(const Duration(minutes: 60 * 4))),
  };

/*final project1 = {
    'title': 'Build a Social Networking Platform',
    'timestamp': DateFormat('yyyy-MM-dd HH:mm:ss')
        .format(DateTime.now().subtract(const Duration(minutes: 60 * 4))),
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
    'title': 'Create an Online Course Platform',
    'timestamp': DateFormat('yyyy-MM-dd HH:mm:ss')
        .format(DateTime.now().subtract(const Duration(minutes: 60 * 4))),
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
        .format(DateTime.now().subtract(const Duration(minutes: 60 * 4))),
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

  final messageResponse = await dataSender.sendNewMessage(message);
  print('Message response: $messageResponse');

  /*final projectResponse = await dataSender.createNewProject(project1);
  print('Project response: $projectResponse');*/
}
