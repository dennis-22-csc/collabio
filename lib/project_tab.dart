import 'package:flutter/material.dart';
import 'package:collabio/model.dart';
import 'package:provider/provider.dart';
import 'package:collabio/util.dart';
import 'package:go_router/go_router.dart';

class MatchingProjectsTab extends StatelessWidget {

  const MatchingProjectsTab({Key? key,}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final projectsModel = Provider.of<ProjectsModel>(context);
    final matchingProjects = projectsModel.matchingProjects;
    return ProjectsListWidget(projects: matchingProjects);
  }
}

class RecentProjectsTab extends StatelessWidget {

  const RecentProjectsTab({Key? key,}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final projectsModel = Provider.of<ProjectsModel>(context);
    final recentProjects = projectsModel.recentProjects;
    return  ProjectsListWidget(projects: recentProjects);
  }
}


class ProjectsListWidget extends StatelessWidget {
  final List<Project> projects;

  const ProjectsListWidget({Key? key, required this.projects}) : super(key: key);

  void _navigateToProjectScreen(BuildContext context, Project project) {
    context.pushNamed("view-project", extra: project);
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
              Text('Posted: ${Util.timeToString(project.timestamp)}'),
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