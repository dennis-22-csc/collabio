import 'package:flutter/material.dart';
import 'package:collabio/model.dart';
import 'package:flutter_markdown/flutter_markdown.dart';


class ViewProjectScreen extends StatelessWidget {
  final Project project;

  const ViewProjectScreen({Key? key, required this.project}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Project Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Handle menu option
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project.title,
              style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Text('Posted: ${project.timestamp}'),
            const SizedBox(height: 16.0),
            MarkdownBody(
              data: project.description,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(fontSize: 16.0),
              ),
            ),
            const SizedBox(height: 24.0),
            const Text(
              'About the poster',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              project.posterAbout,
              style: const TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 24.0),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: () {
                  // Handle message button click
                },
                child: const Text('Message Now'),
              ),
            )
          ],
        ),
      ),
      ),
    );
  }

}
