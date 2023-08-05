import 'package:flutter/material.dart';
import 'dart:io';
import 'package:collabio/project_tab.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:collabio/util.dart';
import 'package:collabio/view_profile.dart';
import 'package:collabio/create_profile.dart';
import 'package:collabio/user_login.dart';
import 'package:collabio/post_project.dart';
import 'package:collabio/inbox_screen.dart';
import 'package:provider/provider.dart';
import 'package:collabio/model.dart';

class MyProjectPage extends StatefulWidget {
  const MyProjectPage({Key? key}) : super(key: key);

  @override
  State<MyProjectPage> createState() => _MyProjectPageState();
}

class _MyProjectPageState extends State<MyProjectPage> {
  int _currentIndex = 0;
  File? profilePicture;
  final TextEditingController _searchController = TextEditingController();
  ProjectsModel? projectsModel;
    
  @override
  void initState() {
    super.initState();
    // Load the profile picture during initialization
    loadProfilePicture();
    projectsModel = Provider.of<ProjectsModel>(context, listen: false);
    projectsModel!.updateProjectsForRefresh(["web development", "frontend"], 10);
  }

  void loadProfilePicture() async {
    String? persistedFilePath = await SharedPreferencesUtil.getPersistedFilePath();

    if (persistedFilePath != null) {
      File existingProfilePicture = File(persistedFilePath);
      if (existingProfilePicture.existsSync()) {
        setState(() {
          profilePicture = existingProfilePicture;
        });
      }
    }
  }

  void handleSearch() {
    String searchText = _searchController.text;
    List<String> keywords = searchText.split(',');
    // Remove leading and trailing whitespaces from each keyword
    keywords = keywords.map((keyword) => keyword.trim()).toList();
    projectsModel!.updateProjectsForSearch(keywords, 10);
  
  }
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileSectionScreen(),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: profilePicture != null ? FileImage(profilePicture!) : null,
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
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                showMenu(
                  context: context,
                  position: const RelativeRect.fromLTRB(1000.0, 80.0, 0.0, 0.0), // Adjust the position as needed
                  items: _buildOptionsMenu(context),
                ).then((value) {
                  if (value != null) {
                    // Handle the selected menu item
                    if (value == 'post_project') {
                      // Handle 'Post project' menu item click
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const ProjectUploadScreen()),
                        );
                      });
                    } else if (value == 'log_out') {
                      // Handle 'Log out' menu item click
                      FirebaseAuth.instance.signOut();
                      SharedPreferencesUtil.setLoggedOut(true);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      });
                    } else if (value == 'create_profile') {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileScreen()),
                        );
                      });
                    }
                  }
                });
              },
            ),

          ],
        ),
        body: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey,
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: FractionallySizedBox(
                widthFactor: 0.75,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search for projects',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.fromLTRB(16.0, 8.0, 8.0, 8.0),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: handleSearch,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            const TabBar(
              tabs: [
                Tab(text: 'Best Matches'),
                Tab(text: 'Most Recent'),
              ],
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  // Projects for Best Matches tab
                  MatchingProjectsTab(),
                  // Projects for Most Recent tab
                  RecentProjectsTab(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            if (index == 1) {
              // If the Messages icon is tapped (index == 1), navigate to the Inbox screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InboxScreen(currentUserEmail: 'denniskoko@gmail.com'),
                ),
              );
            }
          },
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.work),
              label: 'Projects',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.message),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: 'Alerts',
            ),
          ],
        ),
      ),
    );
  }


  List<PopupMenuEntry<String>> _buildOptionsMenu(BuildContext context) {
    return const <PopupMenuEntry<String>>[
      PopupMenuItem<String>(
        value: 'post_project',
        child: Text('Post Project'),
      ),
      PopupMenuItem<String>(
        value: 'create_profile',
        child: Text('Create Profile'),
      ),
      PopupMenuItem<String>(
        value: 'log_out',
        child: Text('Log out'),
      ),
    ];
  }


}