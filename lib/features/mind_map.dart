import 'package:flutter/material.dart';

class MindMap extends StatelessWidget {
  final List<String> topics = [
    'Idea',
    'Planning',
    'Execution',
    'Launch',
    'Review',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Mind Map")),
      body: Center(
        child: Wrap(
          spacing: 20,
          runSpacing: 20,
          children: topics.map((t) => Chip(label: Text(t))).toList(),
        ),
      ),
    );
  }
}
