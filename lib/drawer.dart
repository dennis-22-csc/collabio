import 'package:flutter/material.dart';
import 'package:collabio/project_page.dart';

void main() {
  runApp(const MyProjectPage());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: YourWidget(),
    );
  }
}

class YourWidget extends StatefulWidget {
  const YourWidget({Key? key}) : super(key: key);

  @override
  State<YourWidget> createState() => _YourWidgetState();
}

class _YourWidgetState extends State<YourWidget> {
  bool hasProfile = true; // Set this to true if profile exists, false otherwise

  @override
  Widget build(BuildContext context) {
    var scaffoldKey = GlobalKey<ScaffoldState>();
    List<Widget> drawerOptions = [];

    if (hasProfile) {
      drawerOptions.add(
        ListTile(
          title: const Text('Update Profile'),
          onTap: () {
            // Navigate to Update Profile screen
            Navigator.pop(context);
          },
        ),
      );
    } else {
      drawerOptions.add(
        ListTile(
          title: const Text('Create Profile'),
          onTap: () {
            // Navigate to Create Profile screen
            Navigator.pop(context);
          },
        ),
      );
    }

    drawerOptions.addAll([
      ListTile(
        title: const Text('Post Project'),
        onTap: () {
          // Navigate to Post Project screen
          Navigator.pop(context);
        },
      ),
      ListTile(
        title: const Text('Log Out'),
        onTap: () {
          // Implement log out functionality
        },
      ),
    ]);

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                scaffoldKey.currentState!.openDrawer();
              },
              child: const CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(""),
              ),
            ),
            const SizedBox(width: 8.0),
            const Expanded(
              child: Text(
                'Projects',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: drawerOptions,
        ),
      ),
      body: const Center(
        child: Text('Home Screen Content'),
      ),
    );
  }
}