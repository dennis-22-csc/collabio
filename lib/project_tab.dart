import 'package:flutter/material.dart';
import 'package:collabio/view_project.dart';
import 'package:collabio/model.dart';
import 'package:collabio/database.dart';

class MatchingProjectsTab extends StatefulWidget {
  const MatchingProjectsTab({Key? key}) : super(key: key);

  @override
  State<MatchingProjectsTab> createState() => _MatchingProjectsTabState();
}

class _MatchingProjectsTabState extends State<MatchingProjectsTab> {
  List<Project> matchingProjects = [];
  ThemeData appTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    );
  bool isLoading = true;


  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      List<String> freelancerSkills = ['flutter', 'firebase', 'UI design'];
      final results = await DatabaseHelper.getMatchingProjects(freelancerSkills, 10);

      setState(() {
      matchingProjects = results;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Handle error or display error message
    }
  }

  

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(appTheme.colorScheme.onPrimary), backgroundColor: appTheme.colorScheme.onBackground,
                    )
        : ProjectsListWidget(projects: matchingProjects);
  }
}

class RecentProjectsTab extends StatefulWidget {
  const RecentProjectsTab({Key? key}) : super(key: key);

  @override
  State<RecentProjectsTab> createState() => _RecentProjectsTabState();
}

class _RecentProjectsTabState extends State<RecentProjectsTab> {
  List<Project> recentProjects = [];
  ThemeData appTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    );
  bool isLoading = true;


  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final results = await DatabaseHelper.getRecentProjects(10);
      setState(() {
        recentProjects = results;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Handle error or display error message
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(appTheme.colorScheme.onPrimary), backgroundColor: appTheme.colorScheme.onBackground,
                    )
        : ProjectsListWidget(projects: recentProjects);
  }
}

class ProjectsListWidget extends StatelessWidget {
  final List<Project> projects;

  const ProjectsListWidget({Key? key, required this.projects}) : super(key: key);

  void _navigateToProjectScreen(BuildContext context, Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewProjectScreen(project: project),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: projects.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final project = projects[index];
        return ListTile(
          onTap: () => _navigateToProjectScreen(context, project),
          title: Text(
            project.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Posted: ${project.timestamp}'),
              const SizedBox(height: 8.0),
              Text(
                project.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8.0),
              TagsRow(tags: project.tags),
            ],
          ),
        );
      },
    );
  }
}

class TagsRow extends StatelessWidget {
  final List<String> tags;

  const TagsRow({Key? key, required this.tags}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tags.map((tag) {
          return Container(
            margin: const EdgeInsets.only(right: 8.0),
            child: Chip(
              label: Text(tag),
            ),
          );
        }).toList(),
      ),
    );
  }
}