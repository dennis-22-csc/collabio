import 'package:flutter/material.dart';
import 'package:collabio/project_tab.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:collabio/util.dart';
import 'package:provider/provider.dart';
import 'package:collabio/model.dart';
import 'package:go_router/go_router.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:marquee/marquee.dart';

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
  late ProjectsModel projectsModel;

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
    projectsModel.clearProjects();
    projectsModel.updateProjectsForSearch(keywords, 0, 10);
    profileInfoModel.updateSearchKeywords(keywords);
    profileInfoModel.updateDidSearch(true);
    profileInfoModel.resetProjectBounds();
    // Unfocus the text field to dismiss the keyboard after search
    _searchFocusNode.unfocus();
  
  }

  Future<void> logUserOut() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.goNamed("login");
    });
    await FirebaseAuth.instance.signOut();
    SharedPreferencesUtil.setLogOutStatus(true);
    profileInfoModel.updateLogOutUserStatus();
  }
  
  @override
  Widget build(BuildContext context) {
   profileInfoModel = Provider.of<ProfileInfoModel>(context);
   projectsModel = Provider.of<ProjectsModel>(context);
    
  List<Widget> drawerOptions = [
  if (profileInfoModel.hasProfile)
    UserAccountsDrawerHeader(
      accountName: Text(profileInfoModel.name!),
      accountEmail: Text(_email!),
      currentAccountPicture: CircleAvatar(
        backgroundImage: profileInfoModel.profilePicture != null && profileInfoModel.hasProfile ? profileInfoModel.profilePicture: null,
        child: profileInfoModel.profilePicture == null && !profileInfoModel.hasProfile? const Icon(Icons.person) : null,
      ),
    )
  else
    Container(height: 160),
  
  if (profileInfoModel.hasProfile)
    ListTile(
      title: const Text('View Profile'),
      onTap: () {
        context.goNamed("view-profile");
      },
    )
  else
    ListTile(
      title: const Text('Create Profile'),
      onTap: () {
        context.goNamed("create-profile");
      },
    ),
    ListTile(
      title: const Text('Post Project'),
      onTap: () {
        if (profileInfoModel.hasProfile) {
          context.goNamed("post-project");
        } else {
          showProfileDialog("You can't post a project without creating a profile.");        
        }
      },
    ),
  ListTile(
    title: const Text('Log Out'),
    onTap: () {
      if (profileInfoModel.didPush) {
        logUserOut();
      } else {
        context.goNamed("logout");
      }
    },
  ),
  ListTile(
    title: const Text('Delete Account'),
    onTap: () {
      context.goNamed("web-view", pathParameters: {'url': "https://collabio.denniscode.tech/del-account"});
    },
  ),
];
  return Consumer<ProfileInfoModel>(
  builder: (context, profileInfoModel, _) {
    return DefaultTabController(
      length: 2,
      child: WillPopScope(
        onWillPop: () async {
        context.pop();
        return false;
        },
      child:  Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  scaffoldKey.currentState!.openDrawer();
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    if (profileInfoModel.hasProfile)
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: profileInfoModel.profilePicture!,
                      ),
                    if (!profileInfoModel.hasProfile)
                      const CircleAvatar(
                        radius: 20,
                        child: Icon(Icons.person),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Builder(
                  builder: (BuildContext context) {
                    if (profileInfoModel.postStatus.isEmpty || profileInfoModel.silentSend) {
                      return const Text(
                        'Projects',
                        textAlign: TextAlign.center,
                      );
                    } else {
                      return Row(
                        children: [
                          Expanded (
                            flex: 1,
                            child: AutoSizeText (
                              profileInfoModel.postStatus,
                              maxLines: 1,
                              overflowReplacement: SizedBox (
                                width: 180,
                                height: 30,
                                child: Marquee (
                                  scrollAxis: Axis.horizontal,
                                  blankSpace: 10.0,
                                  startPadding: 10.0,
                                  velocity: 25,
                                  text: profileInfoModel.postStatus, 
                                  style: TextStyle(color: buildPostColor(profileInfoModel),),
                                ),
                              ),
                              style: TextStyle(color: buildPostColor(profileInfoModel),),
                            )
                          ),
                          Flexible(
                            flex: 0,
                            child: IconButton(
                            onPressed: () {
                              profileInfoModel.updatePostStatus('');                            },
                            icon: const Icon(Icons.cancel),
                          )),
                        ],
                      );
                    }
                  },
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
                    projectsModel.clearProjects();
                    projectsModel.updateProjects(profileInfoModel.tags!, 0, 10);
                    profileInfoModel.updateDidSearch(false);
                    profileInfoModel.resetProjectBounds();
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
                child: TextFormField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onFieldSubmitted: (_) {
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
      ),
    );
  },
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
  void showErrorDialog(String content){
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hi there'),
          content: Text(content),
          actions: [
            ElevatedButton(
              onPressed: () {
                context.pop();
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

  MaterialColor buildPostColor(ProfileInfoModel profileInfoModel) {
  switch (profileInfoModel.postColor) {
    case 'purple':
     return Colors.purple;  
    case 'red':
     return Colors.red;
    case 'black':
     return MaterialColor(0xFF000000, {
        50: Colors.black.withOpacity(0.1),
        100: Colors.black.withOpacity(0.2),
        200: Colors.black.withOpacity(0.3),
        300: Colors.black.withOpacity(0.4),
        400: Colors.black.withOpacity(0.5),
        500: Colors.black.withOpacity(0.6),
        600: Colors.black.withOpacity(0.7),
        700: Colors.black.withOpacity(0.8),
        800: Colors.black.withOpacity(0.9),
        900: Colors.black.withOpacity(1.0),
      });
    default:
      return Colors.red;
  }
}

}