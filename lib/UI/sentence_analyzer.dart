import 'package:flutter/material.dart';

class SentenceAnalyzerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sentence Analyzer'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade400,
              Colors.red.shade400,
              Colors.blue.shade400,
              Colors.grey.shade400,
            ],
          ),
        ),
        child: Center(
          child: Text(
            'Sentence Analyzer Coming Soon!',
            style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
} 