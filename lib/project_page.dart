import 'package:flutter/material.dart';
import 'package:collabio/project_tab.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:collabio/util.dart';
import 'package:provider/provider.dart';
import 'package:collabio/model.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

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
  
  String? _email;
  User? user;
  late ProfileInfoModel profileInfoModel;
  
  @override
  void initState() {
    super.initState();
    
    user = FirebaseAuth.instance.currentUser!; 
    _email = user?.email;
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
  
  FileImage buildProfilePicture (String persistedFilePath) {
    late FileImage profilePicture;
     
    File existingProfilePicture = File(persistedFilePath);
    if (existingProfilePicture.existsSync()) {
      profilePicture = FileImage(existingProfilePicture);
    }
    return profilePicture;
  }

  void openDeleteAccountUrl() async {
    final Uri url = Uri.parse('https://collabio.denniscode.tech/del-account');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }
  @override
  Widget build(BuildContext context) {
   profileInfoModel = Provider.of<ProfileInfoModel>(context);
  List<Widget> drawerOptions = [
  if (profileInfoModel.hasProfile)
    UserAccountsDrawerHeader(
      accountName: Text(profileInfoModel.name!),
      accountEmail: Text(_email!),
      currentAccountPicture: CircleAvatar(
        backgroundImage: profileInfoModel.persistedFilePath != null && profileInfoModel.hasProfile ? buildProfilePicture(profileInfoModel.persistedFilePath!): null,
        child: profileInfoModel.persistedFilePath == null && !profileInfoModel.hasProfile? const Icon(Icons.person) : null,
      ),
    )
  else
    Container(height: 160),
  
  if (profileInfoModel.hasProfile)
    ListTile(
      title: const Text('View Profile'),
      onTap: () {
        context.pushNamed("view-profile");
      },
    )
  else
    ListTile(
      title: const Text('Create Profile'),
      onTap: () {
        context.pushNamed("create-profile");
      },
    ),
    ListTile(
      title: const Text('Post Project'),
      onTap: () {
        if (profileInfoModel.hasProfile) {
          context.pushNamed("post-project");
        } else {
          showProfileDialog("You can't post a project without creating a profile.");        
        }
      },
    ),
  ListTile(
    title: const Text('Log Out'),
    onTap: () {
      context.pushNamed("login");
      SharedPreferencesUtil.setLogOutStatus(true);
    },
  ),
  ListTile(
    title: const Text('Delete Account'),
    onTap: () {
      openDeleteAccountUrl();
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
                  backgroundImage: profileInfoModel.persistedFilePath != null ? buildProfilePicture(profileInfoModel.persistedFilePath!) : null,
                  child: profileInfoModel.persistedFilePath == null ? const Icon(Icons.person) : null,
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
                    projectsModel.updateProjects(profileInfoModel.tags!, 10);
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
              if (profileInfoModel.hasProfile) {
                context.pushNamed("inbox", pathParameters: {'currentUserName': profileInfoModel.name!, 'currentUserEmail': _email!});
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
          title: const Text('Hi there'),
          content: Text(content),
          actions: [
            ElevatedButton(
              onPressed: () {
                context.goNamed("create-profile");
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