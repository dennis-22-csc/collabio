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
import 'package:collabio/database.dart';
import 'package:collabio/network_handler.dart';

class MyProjectPage extends StatefulWidget {
  
  const MyProjectPage({Key? key,}) : super(key: key);

  @override
  State<MyProjectPage> createState() => _MyProjectPageState();
}

class _MyProjectPageState extends State<MyProjectPage> {
  int _currentIndex = 0;
  
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final scaffoldKey = GlobalKey<ScaffoldState>();
   
  bool hasProfile = false;
  String? name;
  String? _email;
  File? profilePicture;
  List<String> tags = [];
  
  @override
  void initState() {
    super.initState();
    loadProfilePicture();
    User user = FirebaseAuth.instance.currentUser!; 
    _email = user.email;
    getProfileStatus();
    loadProfileContent();
    loadMessages();
    getSkills();
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
  void loadMessages() async {
    dynamic messageResult = await fetchMessagesFromApi(_email!);
    if (messageResult is List<Message>) {
        await DatabaseHelper.insertMessages(messageResult);
    }

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        //Get initial messages from local database
        final messagesModel = Provider.of<MessagesModel>(context, listen: false);
        messagesModel.updateGroupedMessages(_email!);

        //Set up web socket for new messages
        await connectToSocket(messagesModel, _email!);

        // Resend unsent messages
        final messages = await DatabaseHelper.getUnsentMessages();
        if (messages.isNotEmpty) {
          for (var message in messages) {
            await sendMessageData(messagesModel, message, _email!);
          }
        }
        
      });

  }

  void getSkills() async {
    List<String> myTags = (await SharedPreferencesUtil.getTags()) ?? ["mobile app development", "web development"];
    setState(() {
      tags = myTags;
    });
  } 
  void getProfileStatus() async {
    bool myProfile = await SharedPreferencesUtil.hasProfile();
    setState(() {
      hasProfile = myProfile;
    });
  }
  
  void handleSearch() {
    String searchText = _searchController.text;
    List<String> keywords = searchText.split(',');
    // Remove leading and trailing whitespaces from each keyword
    keywords = keywords.map((keyword) => keyword.trim()).toList();

    final projectsModel = Provider.of<ProjectsModel>(context, listen: false);
    projectsModel.updateProjectsForSearch(keywords, 10);

    // Unfocus the text field to dismiss the keyboard after search
    _searchFocusNode.unfocus();
  
  }

  void loadProfileContent() async {
    String fName = (await SharedPreferencesUtil.getFirstName()) ?? '';
    String lName = (await SharedPreferencesUtil.getLastName()) ?? '';
    setState(() {
      name = '$fName $lName';
    });
  }


  @override
  Widget build(BuildContext context) {
    //var scaffoldKey = GlobalKey<ScaffoldState>();
    List<Widget> drawerOptions = [
  if (hasProfile)
    UserAccountsDrawerHeader(
      accountName: Text(name!),
      accountEmail: Text(_email!),
      currentAccountPicture: CircleAvatar(
        backgroundColor: Colors.white,
        backgroundImage: profilePicture != null ? FileImage(profilePicture!) : null,
        child: profilePicture == null ? const Icon(Icons.person) : null,
      ),
    )
  else
    Container(height: 160),
  
  if (hasProfile)
    ListTile(
      title: const Text('View Profile'),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileSectionScreen()),
        );
      },
    )
  else
    ListTile(
      title: const Text('Create Profile'),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
      },
    ),
    ListTile(
      title: const Text('Post Project'),
      onTap: () {
        if (hasProfile) {
          Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProjectUploadScreen()),
        );
        } else {
          showProfileDialog("You can't post a project without creating a profile.");        
        }
      },
    ),
  ListTile(
    title: const Text('Log Out'),
    onTap: () {
      FirebaseAuth.instance.signOut();
      SharedPreferencesUtil.setLoggedOut(true);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()),);
    },
  ),
];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  scaffoldKey.currentState!.openDrawer();
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: profilePicture != null ? FileImage(profilePicture!) : null,
                  child: profilePicture == null ? const Icon(Icons.person) : null,
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
                  if (value != null && value == 'refresh') {
                    final projectsModel = Provider.of<ProjectsModel>(context, listen: false);
                    projectsModel.updateProjects(tags, 10);
                    _searchController.clear();
                  }
                });
              },
            ),

          ],
          automaticallyImplyLeading: false,
        ),
        drawer: Drawer(
            width: MediaQuery.of(context).size.width * 0.7,
            child: ListView(
            padding: EdgeInsets.zero,
            children: drawerOptions,
          ),
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
                  focusNode: _searchFocusNode,
                  onSubmitted: (_) {
                    if (_searchController.text.trim().isNotEmpty) {
                      handleSearch();
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Search for projects',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.fromLTRB(16.0, 8.0, 8.0, 8.0),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: (){
                        if (_searchController.text.trim().isNotEmpty) {
                          handleSearch();
                      }
                      }
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
              if (hasProfile) {
                // If the Messages icon is tapped (index == 1), navigate to the Inbox screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InboxScreen(currentUserEmail: _email!, currentUserName: name!),
                ),
              );
              } else {
                showProfileDialog("You can't send or view messages without creating a profile.");
              } 
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

  void showProfileDialog(String content){
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hey Chief'),
          content: Text(content),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  List<PopupMenuEntry<String>> _buildOptionsMenu(BuildContext context) {
    return const <PopupMenuEntry<String>>[
      PopupMenuItem<String>(
        value: 'refresh',
        child: Text('Refresh'),
      ),
    ];
  }

}